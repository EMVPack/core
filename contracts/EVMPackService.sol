// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import "./IEVMPackService.sol";

/**
 * @title Abstract service contract
 * @dev Uses handshake mechanism for secure communication between users and providers
 */
contract EVMPackService is IEVMPackService, Initializable, OwnableUpgradeable, ERC20Upgradeable {
    
    // keccak256(abi.encode(uint256(keccak256("evmpack.service.storage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant EVMPACKSERVICE_STORAGE = 0xa0c3d6c71a5db55999a7b3cfff685d3899eb61aa28d7866bfc8aa806bc0eb600;
    
    struct Storage {
        /// @dev Service configuration parameters
        ServiceSettings _settings;

        /// @dev Mapping of provider addresses to their data
        mapping (address => ProviderData) providers;
        mapping (address => mapping(uint256 id => Tariff) ) provider_tariffs;
        
        /// @dev Mapping of handshake hashes to handshake details
        mapping (bytes32 => Handshake) handshakes;
        
        /// @dev Nonces for message hashing prevention
        mapping (address => uint256) nonces;

        mapping (address => uint256) locked_balance;
        mapping (bytes32 handshake => mapping(uint32 commitIndex => Commit)) handshake_commits;

    }


    /**
     * @notice Returns the main storage struct.
     * @return $ The storage struct.
     */
    function state() internal pure returns (Storage storage $) {
        bytes32 slot = EVMPACKSERVICE_STORAGE;
        assembly ("memory-safe") {
            $.slot := slot
        }
    }

    /**
     * @notice Initializes contract with service settings
     * @param settings Initial service configuration parameters
     * @dev Checks validity of fee/deposit ratios during initialization
     */
    function __EVMPackService__initialize(ServiceSettings calldata settings, address owner) internal onlyInitializing {

        state()._settings = settings;
        __Ownable_init(owner);
        __ERC20_init("Balance", "ETH");
    }

    /**
     * @notice Returns current service settings
     * @return ServiceSettings struct with current configuration
     */
    function getServiceInfo() external view returns(ServiceSettings memory) {
        return state()._settings;
    }


    function changeMinProviderDeposit(uint256 minProviderDeposit) onlyOwner() external {
        state()._settings.minProviderDeposit = minProviderDeposit;
        emit ServiceSettingsChanged("minProviderDeposit");
    }

    /// @notice Modifier for handshake access control
    /// @dev Reverts if caller isn't part of the handshake
    modifier handshakeAccess(bytes32 handshake) {
        Handshake memory _handshake = state().handshakes[handshake];

        bool access = false;

        if(_handshake.provider == msg.sender)
            access = true;

        if(_handshake.account == msg.sender)
            access = true;

        if(!access)
            revert AccessDeniedProvider("Provider");
        _;
    }


    /**
     * @notice Register a new message provider
     * @param provider Provider configuration details
     * @dev Requires minimum deposit and at least one enabled gateway
     */
    function registerProvider(Provider calldata provider) payable external {
        if(msg.value < state()._settings.minProviderDeposit)
            revert MinimumProviderDeposit(state()._settings.minProviderDeposit);

        if(state().providers[msg.sender].deposit != 0)
            revert AlreadyExist("Provider");

        _mint(msg.sender, msg.value);
        state().providers[msg.sender] = ProviderData(provider, msg.value, 0, 0, 0, 0, true);
        emit AddProvider(msg.sender);
    }

    function addTariff(Tariff memory tariff) public {

        if(tariff.minHandshakeDays == 0){
            revert TariffMinHandshakeDays();
        }

        if(!_existProvider(msg.sender)){
            revert ProviderNotFound();
        }

        state().providers[msg.sender].tariff_count++;

        state().provider_tariffs[msg.sender][state().providers[msg.sender].tariff_count] = tariff;

    }


    /**
     * @notice Get provider details
     * @param provider Address of the provider to query
     * @return ProviderData struct with provider information
     */
    function getProvider(address provider) external view returns(ProviderData memory) {
        return state().providers[provider];
    }

    /**
     * @notice Initiate a handshake request with provider
     * @param aes256Key AES key encrypted with provider's public key
     * @param provider Target provider address
     * @dev Generates unique handshake hash using nonce
     */
    function requestUserHandshakeWithProvider(string calldata aes256Key, address provider, string calldata hello, uint16 period, uint256 tariffId) payable external {

        if(period == 0){
            period = state()._settings.defaultHandshakeExpire;
        }

        Tariff memory tariff = state().provider_tariffs[provider][tariffId];

        if(tariff.minHandshakeDays == 0){
            revert TariffNotFound(tariffId);
        }

        if(tariff.disabled){
            revert TariffDisabled();
        }

        if(period < tariff.minHandshakeDays){
            revert IncorrectPeriod(tariff.minHandshakeDays, period);
        }

        uint256 amount =  tariff.handshakeCoastPerDay * period; 

        if(msg.value != amount){
            revert HandshakeAmountFailed(amount, msg.value);
        }

        if(state().providers[provider].deposit == 0)
            revert ProviderDepositExhausted();
        
        bytes32 handshake = keccak256(abi.encodePacked(provider, aes256Key, msg.sender, state().nonces[msg.sender]++));

        if(state().handshakes[handshake].account != address(0))
            revert AlreadyExist("Handshake");

        state().handshakes[handshake] = Handshake({
            tariffId:tariffId,
            deposit: msg.value,
            hello: hello,
            createDate: block.timestamp,
            dateExpire: block.timestamp + (period * 1 days),
            commitIndex: 0,
            account: msg.sender,
            provider: provider,
            aes256Key: aes256Key,
            providerApproved: false,
            revoked: false,
            suspended: false
        });

        state().locked_balance[msg.sender] += msg.value;

        _mint(msg.sender, msg.value);

        emit RequestUserHandshakeWithProvider(handshake, aes256Key, msg.sender);
    }


    function extendHandshake(bytes32 handshake, uint16 period) payable external {
        _checkHandshakeExist(handshake);

        Tariff memory tariff = state().provider_tariffs[state().handshakes[handshake].provider][state().handshakes[handshake].tariffId];
        uint256 amount = tariff.handshakeCoastPerDay * period;

        if(msg.value != amount){
            revert HandshakeAmountFailed(amount, msg.value);
        }

        state().handshakes[handshake].dateExpire += (period * 1 days);

        if(state().handshakes[handshake].suspended ){
            state().handshakes[handshake].suspended = false;
        }

        emit ExtendHandshake(handshake, period, amount);
        
    }

    function commit(bytes32 handshake) public {
        _checkHandshakeExist(handshake);

        if(state().handshakes[handshake].suspended){
            return;
        }

        uint256 fromDate = state().handshakes[handshake].createDate;

        if(state().handshakes[handshake].commitIndex > 0){
           fromDate = state().handshake_commits[handshake][state().handshakes[handshake].commitIndex].timestamp;
        }

        uint256 _days = Math.mulDiv((fromDate - block.timestamp), 1, 86400, Math.Rounding.Floor);

        if(_days == 0){
            return;
        }
        Tariff memory tariff = state().provider_tariffs[state().handshakes[handshake].provider][state().handshakes[handshake].tariffId];
        state().handshakes[handshake].commitIndex++;

        uint256 amount = 0;

        if(state().handshakes[handshake].commitIndex > tariff.freeDays){
            amount = tariff.handshakeCoastPerDay * _days;
        }

        
        state().handshake_commits[handshake][state().handshakes[handshake].commitIndex] = Commit({
            amount: amount,
            timestamp:block.timestamp
        });

        state().handshakes[handshake].deposit -= amount;
        state().locked_balance[state().handshakes[handshake].account] -= amount;
        _transferFrom(state().handshakes[handshake].account, state().handshakes[handshake].provider, amount);
        

        if(state().handshakes[handshake].deposit == 0){
            state().handshakes[handshake].suspended = true;
        }

        emit CommitHandshake(handshake, state().handshakes[handshake].commitIndex, amount);
    }



    /**
     * @notice Provider response to handshake request
     * @param handshake Handshake identifier
     * @param status Approval status from provider
     */
    function responseUserHandshakeWithProvider(bytes32 handshake, bool status) external {
        _responseUserHandshakeWithProvider(handshake,status);
    }

    function _responseUserHandshakeWithProvider(bytes32 handshake, bool status) internal {
        _checkHandshakeExist(handshake);
        if(state().handshakes[handshake].provider != msg.sender)
            revert AlreadyExist("Provider");

        if(status) {
            state().handshakes[handshake].providerApproved = true;
        } else {
            state().handshakes[handshake].revoked = true;
        }
        emit ResponseUserHandshakeWithProvider(handshake, status);
    }

    /**
     * @notice Revoke an existing handshake
     * @param handshake Handshake identifier to revoke
     */
    function revokeHandshake(bytes32 handshake) external handshakeAccess(handshake) {
        commit(handshake);
        state().handshakes[handshake].revoked = true;
        state().handshakes[handshake].suspended = true;

        uint256 amount = state().handshakes[handshake].deposit;
        state().locked_balance[state().handshakes[handshake].account] -= amount;

        emit HandshakeRevoke(handshake);
    }

    /**
     * @notice Get handshake details
     * @param handshake Handshake identifier
     * @return Handshake struct with current status
     */
    function getHandshake(bytes32 handshake)  external view returns(Handshake memory) {
        return state().handshakes[handshake];
    }

    /**
     * @notice Validate handshake status
     * @param handshake Handshake identifier to validate
     * @dev Checks existence, approval, revocation and expiration
     */    
    function validateHandshake(bytes32 handshake) public view {
        _checkHandshakeExist(handshake);
        _checkHandshakeAprove(handshake);
        _checkHandshakeRevoke(handshake);
        _checkHandshakeExpire(handshake);
    }

    // Internal validation functions
    function _checkHandshakeAprove(bytes32 handshake) internal view {
        if(!state().handshakes[handshake].providerApproved)
            revert HandshakeNotAprooved();
    }

    function _checkHandshakeRevoke(bytes32 handshake) internal view {
        if(state().handshakes[handshake].revoked)
            revert HandshakeRevoked();
    }

    function _checkHandshakeExpire(bytes32 handshake) internal view {
        if(block.timestamp > state().handshakes[handshake].dateExpire)
            revert HandshakeDateExpire(state().handshakes[handshake].dateExpire);
    }

    function _checkHandshakeExist(bytes32 handshake) internal view {
        if(state().handshakes[handshake].dateExpire == 0)
            revert HandshakeNotFound("Provider:Handshake",handshake);
    }

    function _existProvider(address account) internal view returns(bool){
        return state().providers[account].exist;
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        
        return _transferFrom(spender, to, value);
    }

    
    function transfer(address to, uint256 value) public override returns (bool) {
        address owner = _msgSender();
        return _transferFrom(owner, to, value);
    }

    function balanceOf(address account) public view override returns (uint256) {
        uint256 balance = super.balanceOf(account);
        balance -= state().locked_balance[account];
        return balance;
    }

    function _transferFrom(address from, address to, uint256 value ) internal returns (bool){

        uint256 balance = balanceOf(from);

        if(_existProvider(from)){
            (bool success, uint256 result) = Math.trySub(balance, value);

            if(!success)
                revert ProviderDepositSmall(balance);

            if(result < state()._settings.minProviderDeposit)
                revert ProviderDepositSmall(balance);
        }


        _burn(from, value);

        (bool success_call, ) = to.call{value: value}("");

        require(
            success_call,
            "Address: unable to send value, recipient may have reverted"
        );
        return true;
    }


}