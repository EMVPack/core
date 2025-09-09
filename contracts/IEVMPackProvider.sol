// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title Provider Interface
 * @notice Defines core structures, events and errors for message delivery system
 * @dev Serves as foundation for Provider contract implementation
 */
interface IEVMPackProvider {

    /// @notice Handshake agreement parameters
    /// @param date_expire Expiration timestamp of handshake
    /// @param account User address initiating handshake
    /// @param provider Service provider address
    /// @param provider_approved Provider acceptance status
    /// @param revoked Manual revocation status
    struct Handshake {
        uint256 date_expire;
        address account;
        address provider;
        string aes256_key;
        bool provider_approved;
        bool revoked;
    }

    /// @notice Provider operational data
    /// @param info Provider configuration details
    /// @param deposit Security deposit amount
    /// @param rate Performance rating score
    /// @param online Show provider status
    struct ProviderData {
        Provider info;
        uint256 deposit;
        uint256 rate;
        bool online;
    }

    /// @notice Provider service configuration
    /// @param public_key Encryption public key
    /// @param meta JSON document about of service
    /// @param getway Gateway settings
    struct Provider {
        string public_key;
        string meta;
        ProviderGetway getway;
    }

    /// @notice Gateway-specific configuration
    /// @param enable Gateway activation status
    /// @param endpoints Array of endpoints RPC, REST, WS and other
    /// @param cost_per_message Base price per message
    /// @param time_between_retry Minimum retry interval in seconds
    struct ProviderGetway {
        bool enable;
        string[] endpoints;
        uint256 cost_per_message;
        uint256 time_between_retry;
    }

    /// @notice Service governance parameters
    /// @param min_provider_deposit Minimum security deposit for providers
    /// @param processing_time Maximum allowed processing duration
    /// @param punishment_coast Penalty amount for SLA violations
    struct ServiceSettings {
        uint256 min_provider_deposit;
        uint256 processing_time;
        uint256 punishment_coast;
    }
    
    // Custom errors
    
    /// @notice Insufficient provider deposit during registration
    /// @param min_provider_deposit Required minimum deposit amount
    error MinimumProviderDeposit(uint256 min_provider_deposit);
    
    /// @notice Expired handshake usage attempt
    /// @param date_expire Handshake expiration timestamp
    error HandshakeDateExpire(uint256 date_expire);
    
    /// @notice Attempt to use revoked handshake
    error HandshakeRevoked();
    
    /// @notice Attempt to use unapproved handshake
    error HandshakeNotAprooved();
    
    /// @notice Insufficient payment for message delivery
    /// @param required Expected payment amount
    /// @param given Actual payment amount
    error InsufficientFunds(uint256 required, uint256 given);
    
    /// @notice Early retry attempt detection
    /// @param time_between_retry Required waiting period
    /// @param current_time Time since last attempt
    error Timeout(uint256 time_between_retry, uint256 current_time);
    
    
    /// @notice Provider deposit depletion
    error ProviderDepositExhausted();

    error ProviderDepositSmall(uint256 amount);
    
    /// @notice Unauthorized access attempt
    /// @param provider Restricted module identifier
    error AccessDeniedProvider(string provider);
    
    /// @notice Invalid handshake reference
    /// @param object Context object type
    /// @param object_id Handshake identifier
    error HandshakeNotFound(string object, bytes32 object_id);
    
    error AlreadyExistProvider(string provider);
    
    /// @notice Missing enabled gateways
    error NoGetwayEnabled();
    
    /// @notice Duplicate delivery confirmation
    error AlreadyResponse();

    /// @notice Provider not found
    error ProviderNotFound();

    // Events
    
    /// @notice New provider registration
    /// @param account Provider wallet address
    event AddProvider(address indexed account);
    
    /// @notice Provider deposit balance update
    /// @param provider Provider address
    /// @param amount New deposit amount
    event ProviderDepositUpdated(address indexed provider, uint256 amount);
    
    /// @notice Service parameter change
    /// @param field Modified parameter name
    event ServiceSettingsChanged(string field);
    
    /// @notice Handshake initiation
    /// @param handshake Unique handshake identifier
    /// @param account User address
    event RequestUserHandshakeWithProvider(bytes32 indexed handshake,  string aes_key, address indexed account);
    
    /// @notice Handshake resolution
    /// @param handshake Handshake identifier
    /// @param status Provider acceptance decision
    event ResponseUserHandshakeWithProvider(bytes32 indexed handshake, bool indexed status);
    
    /// @notice Handshake termination
    /// @param handshake Revoked handshake identifier
    event HandshakeRevoke(bytes32 handshake);
    
    /// @notice Call when changes provider online status
    /// @param provider Service provider address
    /// @param status Online status
    event ChangeProviderStatus(address indexed provider, bool status);

    function getServiceInfo() external view returns(ServiceSettings memory);
    function changeProcessingTime(uint256 processing_time) external;
    function changeMinProviderDeposit(uint256 min_provider_deposit) external;
    function registerProvider(Provider calldata provider) payable external;
    function setProviderOnlineStatus(bool status) external;
    function getProvider(address provider) external view returns(ProviderData memory);
    function requestUserHandshakeWithProvider(string calldata aes_key, address provider) external;
    function responseUserHandshakeWithProvider(bytes32 handshake, bool status) external;
    function revokeHandshake(bytes32 handshake)  external;
    function getHandshake(bytes32 handshake) external view returns(Handshake memory);
    function validateHandshake(bytes32 handshake) external view;
}