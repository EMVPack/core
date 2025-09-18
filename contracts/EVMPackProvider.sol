// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import "./IEVMPackProvider.sol";

/**
 * @title Message Provider Contract
 * @notice Handles message delivery system with SMS gateways using provider network
 * @dev Uses handshake mechanism for secure communication between users and providers
 */
abstract contract EVMPackProvider is IEVMPackProvider, Initializable, OwnableUpgradeable, ERC20Upgradeable {
    
    /// @dev Service configuration parameters
    ServiceSettings _settings;

    /// @dev Mapping of provider addresses to their data
    mapping (address => ProviderData) providers;
    
    /// @dev Mapping of handshake hashes to handshake details
    mapping (bytes32 => Handshake) handshakes;
    
    /// @dev Nonces for message hashing prevention
    mapping (address => uint256) nonces;

    mapping (address => uint256) locked_balance;
    mapping (bytes32 handshake => mapping(uint32 commitIndex => Commit)) handshake_commits;

    /**
     * @notice Initializes contract with service settings
     * @param settings Initial service configuration parameters
     * @dev Checks validity of fee/deposit ratios during initialization
     */
    function __EVMPackProvider__initialize(ServiceSettings calldata settings, address owner) internal onlyInitializing {

        _settings = settings;
        __Ownable_init(owner);
        __ERC20_init("Balance", "ETH");
    }

    /**
     * @notice Returns current service settings
     * @return ServiceSettings struct with current configuration
     */
    function getServiceInfo() external view returns(ServiceSettings memory) {
        return _settings;
    }


    function changeMinProviderDeposit(uint256 minProviderDeposit) onlyOwner() external {
        _settings.minProviderDeposit = minProviderDeposit;
        emit ServiceSettingsChanged("minProviderDeposit");
    }

    /// @notice Modifier for handshake access control
    /// @dev Reverts if caller isn't part of the handshake
    modifier handshakeAccess(bytes32 handshake) {
        Handshake memory _handshake = handshakes[handshake];

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
        _registerProvider(provider);
    }


    function _registerProvider(Provider calldata provider) internal {
        if(msg.value < _settings.minProviderDeposit)
            revert MinimumProviderDeposit(_settings.minProviderDeposit);

        if(providers[msg.sender].deposit != 0)
            revert AlreadyExist("Provider");

        _mint(msg.sender, msg.value);
        providers[msg.sender] = ProviderData(provider, msg.value, 0, true);
        emit AddProvider(msg.sender);
    }


    /**
     * @notice Get provider details
     * @param provider Address of the provider to query
     * @return ProviderData struct with provider information
     */
    function getProvider(address provider) external view returns(ProviderData memory) {
        return providers[provider];
    }

    /**
     * @notice Initiate a handshake request with provider
     * @param aes256Key AES key encrypted with provider's public key
     * @param provider Target provider address
     * @dev Generates unique handshake hash using nonce
     */
    function requestUserHandshakeWithProvider(string calldata aes256Key, address provider, string calldata hello, uint16 period) payable external {
        _requestUserHandshakeWithProvider(aes256Key, provider, hello, period);
    }

    function _requestUserHandshakeWithProvider(string calldata aes256Key, address provider,  string memory hello, uint16 period) internal  {

        if(period == 0){
            period = _settings.defaultHandshakeExpire;
        }

        uint256 amount = providers[provider].info.handshakeCoastPerDay * period;

        if(msg.value != amount){
            revert HandshakeAmountFailed(amount, msg.value);
        }

        if(providers[provider].deposit == 0)
            revert ProviderDepositExhausted();
        
        bytes32 handshake = keccak256(abi.encodePacked(provider, aes256Key, msg.sender, nonces[msg.sender]++));

        if(handshakes[handshake].account != address(0))
            revert AlreadyExist("Handshake");

        handshakes[handshake] = Handshake({
            deposit: msg.value,
            coastPerDay: providers[provider].info.handshakeCoastPerDay,
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

        locked_balance[msg.sender] += msg.value;

        _mint(msg.sender, msg.value);

        emit RequestUserHandshakeWithProvider(handshake, aes256Key, msg.sender);
    }

    function extendHandshake(bytes32 handshake, uint16 period) payable external {
        _checkHandshakeExist(handshake);
        
        uint256 amount = handshakes[handshake].coastPerDay * period;

        if(msg.value != amount){
            revert HandshakeAmountFailed(amount, msg.value);
        }

        handshakes[handshake].dateExpire += (period * 1 days);

        if(handshakes[handshake].suspended ){
            handshakes[handshake].suspended = false;
        }

        emit ExtendHandshake(handshake, period, amount);
        
    }

    function commit(bytes32 handshake) public {
        _checkHandshakeExist(handshake);

        if(handshakes[handshake].suspended){
            return;
        }

        uint256 fromDate = handshakes[handshake].createDate;

        if(handshakes[handshake].commitIndex > 0){
           fromDate = handshake_commits[handshake][handshakes[handshake].commitIndex].timestamp;
        }

        uint256 _days = Math.mulDiv((fromDate - block.timestamp), 1, 86400, Math.Rounding.Floor);

        if(_days == 0){
            return;
        }
        uint256 amount = handshakes[handshake].coastPerDay * _days;

        handshakes[handshake].commitIndex++;
        handshake_commits[handshake][handshakes[handshake].commitIndex] = Commit({
            amount: amount,
            timestamp:block.timestamp
        });

        handshakes[handshake].deposit -= amount;
        locked_balance[handshakes[handshake].account] -= amount;
        _transferFrom(handshakes[handshake].account, handshakes[handshake].provider, amount);
        

        if(handshakes[handshake].deposit == 0){
            handshakes[handshake].suspended = true;
        }

        emit CommitHandshake(handshake, handshakes[handshake].commitIndex, amount);
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
        if(handshakes[handshake].provider != msg.sender)
            revert AlreadyExist("Provider");

        if(status) {
            handshakes[handshake].providerApproved = true;
        } else {
            handshakes[handshake].revoked = true;
        }
        emit ResponseUserHandshakeWithProvider(handshake, status);
    }

    /**
     * @notice Revoke an existing handshake
     * @param handshake Handshake identifier to revoke
     */
    function revokeHandshake(bytes32 handshake) external handshakeAccess(handshake) {
        commit(handshake);
        handshakes[handshake].revoked = true;
        handshakes[handshake].suspended = true;

        uint256 amount = handshakes[handshake].deposit;
        locked_balance[handshakes[handshake].account] -= amount;

        emit HandshakeRevoke(handshake);
    }

    /**
     * @notice Get handshake details
     * @param handshake Handshake identifier
     * @return Handshake struct with current status
     */
    function getHandshake(bytes32 handshake)  external view returns(Handshake memory) {
        return handshakes[handshake];
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
        if(!handshakes[handshake].providerApproved)
            revert HandshakeNotAprooved();
    }

    function _checkHandshakeRevoke(bytes32 handshake) internal view {
        if(handshakes[handshake].revoked)
            revert HandshakeRevoked();
    }

    function _checkHandshakeExpire(bytes32 handshake) internal view {
        if(block.timestamp > handshakes[handshake].dateExpire)
            revert HandshakeDateExpire(handshakes[handshake].dateExpire);
    }

    function _checkHandshakeExist(bytes32 handshake) internal view {
        if(handshakes[handshake].dateExpire == 0)
            revert HandshakeNotFound("Provider:Handshake",handshake);
    }

    function _existProvider(address account) internal view returns(bool){
        return providers[account].exist;
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
        balance -= locked_balance[account];
        return balance;
    }

    function _transferFrom(address from, address to, uint256 value ) internal returns (bool){

        uint256 balance = balanceOf(from);

        if(_existProvider(from)){
            (bool success, uint256 result) = Math.trySub(balance, value);

            if(!success)
                revert ProviderDepositSmall(balance);

            if(result < _settings.minProviderDeposit)
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