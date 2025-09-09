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

    /**
     * @notice Initializes contract with service settings
     * @param settings Initial service configuration parameters
     * @dev Checks validity of fee/deposit ratios during initialization
     */
    function __provider_initialize(ServiceSettings calldata settings) internal onlyInitializing {

        if(settings.punishment_coast > settings.min_provider_deposit)
            revert("punishment_coast more than min_provider_deposit");

        _settings = settings;
        __Ownable_init(msg.sender);
        __ERC20_init("Balance", "ETH");
    }

    /**
     * @notice Returns current service settings
     * @return ServiceSettings struct with current configuration
     */
    function getServiceInfo() external view returns(ServiceSettings memory) {
        return _settings;
    }

    /// @notice Group of functions for service parameter management
    /// @dev All functions restricted to contract owner
    
    function changeProcessingTime(uint256 processing_time) onlyOwner() external {
        _settings.processing_time = processing_time;
        emit ServiceSettingsChanged("processing_time");
    }

    function changeMinProviderDeposit(uint256 min_provider_deposit) onlyOwner() external {
        _settings.min_provider_deposit = min_provider_deposit;
        emit ServiceSettingsChanged("min_provider_deposit");
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
    function registerProvider(Provider calldata provider) payable external virtual {
        _registerProvider(provider);
    }


    function _registerProvider(Provider calldata provider) internal {
        if(msg.value < _settings.min_provider_deposit)
            revert MinimumProviderDeposit(_settings.min_provider_deposit);

        if(providers[msg.sender].deposit != 0)
            revert AlreadyExistProvider("Provider");

        _mint(msg.sender, msg.value);
        providers[msg.sender] = ProviderData(provider, msg.value, 0, false);
        emit AddProvider(msg.sender);
    }

    /**
     * @notice Set a current provider status
     * @param status Online status
     */    
    function setProviderOnlineStatus(bool status) external {

        if(providers[msg.sender].deposit == 0)
            revert ProviderNotFound();

        providers[msg.sender].online = status;
        
        emit ChangeProviderStatus(msg.sender, status);
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
     * @param aes_key AES key encrypted with provider's public key
     * @param provider Target provider address
     * @dev Generates unique handshake hash using nonce
     */
    function requestUserHandshakeWithProvider(string calldata aes_key, address provider) external virtual {
        _requestUserHandshakeWithProvider(aes_key, provider);
    }

    function _requestUserHandshakeWithProvider(string calldata aes_key, address provider) internal  {

        if(providers[provider].deposit == 0)
            revert ProviderDepositExhausted();
        
        bytes32 handshake = keccak256(abi.encodePacked(provider, aes_key, msg.sender, nonces[msg.sender]++));

        if(handshakes[handshake].account != address(0))
            revert AlreadyExistProvider("Provider:Handshake");

        handshakes[handshake] = Handshake(
            block.timestamp + 365 days,
            msg.sender,
            provider,
            aes_key,
            false,
            false
        );

        emit RequestUserHandshakeWithProvider(handshake, aes_key, msg.sender);
    }

    /**
     * @notice Provider response to handshake request
     * @param handshake Handshake identifier
     * @param status Approval status from provider
     */
    function responseUserHandshakeWithProvider(bytes32 handshake, bool status) external virtual {
        _responseUserHandshakeWithProvider(handshake,status);
    }

    function _responseUserHandshakeWithProvider(bytes32 handshake, bool status) internal {
        _checkHandshakeExist(handshake);
        if(handshakes[handshake].provider != msg.sender)
            revert AlreadyExistProvider("Provider");

        if(status) {
            handshakes[handshake].provider_approved = true;
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
        handshakes[handshake].revoked = true;
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
        if(!handshakes[handshake].provider_approved)
            revert HandshakeNotAprooved();
    }

    function _checkHandshakeRevoke(bytes32 handshake) internal view {
        if(handshakes[handshake].revoked)
            revert HandshakeRevoked();
    }

    function _checkHandshakeExpire(bytes32 handshake) internal view {
        if(block.timestamp > handshakes[handshake].date_expire)
            revert HandshakeDateExpire(handshakes[handshake].date_expire);
    }

    function _checkHandshakeExist(bytes32 handshake) internal view {
        if(handshakes[handshake].date_expire == 0)
            revert HandshakeNotFound("Provider:Handshake",handshake);
    }



    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Skips emitting an {Approval} event indicating an allowance update. This is not
     * required by the ERC. See {xref-ERC20-_approve-address-address-uint256-bool-}[_approve].
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */    
    function transferFrom(address from, address to, uint256 value) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        
        return _transferFrom(spender, to, value);
    }

    

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(address to, uint256 value) public virtual override returns (bool) {
        address owner = _msgSender();
        return _transferFrom(owner, to, value);
    }

    function _transferFrom(address from, address to, uint256 value ) internal returns (bool){

        uint256 balance = balanceOf(from);
        (bool success, uint256 result) = Math.trySub(balance, value);

        if(!success)
            revert ProviderDepositSmall(balance);

        if(result < _settings.min_provider_deposit)
            revert ProviderDepositSmall(balance);

        _burn(from, value);

        (bool success_call, ) = to.call{value: value}("");

        require(
            success_call,
            "Address: unable to send value, recipient may have reverted"
        );
        return true;
    }


}