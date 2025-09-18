// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title Provider Interface
 * @notice Defines core structures, events and errors for message delivery system
 * @dev Serves as foundation for Provider contract implementation
 */
interface IEVMPackProvider {

    /// @notice Handshake agreement parameters
    /// @param dateExpire Expiration timestamp of handshake
    /// @param account User address initiating handshake
    /// @param provider Service provider address
    /// @param providerApproved Provider acceptance status
    /// @param revoked Manual revocation status
    struct Handshake {
        uint256 deposit;
        uint256 coastPerDay;
        string hello; // encrypted ipfs json document
        uint256 createDate;
        uint32 commitIndex;
        uint256 dateExpire;
        address account;
        address provider;
        string aes256Key;
        bool providerApproved;
        bool revoked;
        bool suspended;
    }

    struct Commit {
        uint256 amount;
        uint256 timestamp;
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
        bool exist;
    }

    /// @notice Provider service configuration
    /// @param publicKey Encryption public key
    /// @param meta JSON document about of service
    /// @param handshakeCoastPerDay Base price per message
    /// @param getway Gateway settings
    struct Provider {
        string publicKey;
        string meta;
        uint256 handshakeCoastPerDay;
        ProviderGetway getway;
    }

    /// @notice Gateway-specific configuration
    /// @param enable Gateway activation status
    /// @param endpoints Array of endpoints RPC, REST, WS and other
    /// @param timeBetweenRetry Minimum retry interval in seconds
    struct ProviderGetway {
        bool enable;
        string[] endpoints;
        uint256 timeBetweenRetry;
    }

    /// @notice Service governance parameters
    /// @param minProviderDeposit Minimum security deposit for providers
    /// @param defaultHandshakeExpire Maximum allowed processing duration
    /// @param meta Penalty amount for SLA violations
    struct ServiceSettings {
        uint256 minProviderDeposit;
        uint16 defaultHandshakeExpire; // in days
        string helloForm;
        string meta;
    }

    
    // Custom errors
    
    /// @notice Insufficient provider deposit during registration
    /// @param minProviderDeposit Required minimum deposit amount
    error MinimumProviderDeposit(uint256 minProviderDeposit);
    
    /// @notice Expired handshake usage attempt
    /// @param dateExpire Handshake expiration timestamp
    error HandshakeDateExpire(uint256 dateExpire);
    
    /// @notice Attempt to use revoked handshake
    error HandshakeRevoked();
    
    /// @notice Attempt to use unapproved handshake
    error HandshakeNotAprooved();
    
    error HandshakeAmountFailed(uint256 required, uint256 given);
    /// @notice Insufficient payment for message delivery
    /// @param required Expected payment amount
    /// @param given Actual payment amount
    error InsufficientFunds(uint256 required, uint256 given);
    
    /// @notice Early retry attempt detection
    /// @param timeBetweenRetry Required waiting period
    /// @param currentTime Time since last attempt
    error Timeout(uint256 timeBetweenRetry, uint256 currentTime);
    
    
    /// @notice Provider deposit depletion
    error ProviderDepositExhausted();

    error ProviderDepositSmall(uint256 amount);
    
    /// @notice Unauthorized access attempt
    /// @param provider Restricted module identifier
    error AccessDeniedProvider(string provider);
    
    /// @notice Invalid handshake reference
    /// @param object Context object type
    /// @param objectId Handshake identifier
    error HandshakeNotFound(string object, bytes32 objectId);
    
    error AlreadyExist(string reason);
    
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

    event CommitHandshake(bytes32 indexed handshake, uint32 commitIndex, uint256 amount);

    event ExtendHandshake(bytes32 indexed handshake, uint16 _days, uint256 amount);

    function getServiceInfo() external view returns(ServiceSettings memory);
    function changeMinProviderDeposit(uint256 minProviderDeposit) external;
    function registerProvider(Provider calldata provider) payable external;
    function getProvider(address provider) external view returns(ProviderData memory);
    function requestUserHandshakeWithProvider(string calldata aes256Key, address provider, string calldata hello, uint16 period) payable external;
    function responseUserHandshakeWithProvider(bytes32 handshake, bool status) external;
    function revokeHandshake(bytes32 handshake)  external;
    function getHandshake(bytes32 handshake) external view returns(Handshake memory);
    function validateHandshake(bytes32 handshake) external view;
}