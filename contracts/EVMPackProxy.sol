// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.2.0) (proxy/transparent/TransparentUpgradeableProxy.sol)
// Changed by Mikhail Ivantsov

pragma solidity ^0.8.28;

import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC1967} from "@openzeppelin/contracts/interfaces/IERC1967.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";


import "./IEVMPack.sol";
/**
 * @dev Interface for {TransparentUpgradeableProxy}. In order to implement transparency, {TransparentUpgradeableProxy}
 * does not implement this interface directly, and its upgradeability mechanism is implemented by an internal dispatch
 * mechanism. The compiler is unaware that these functions are implemented by {TransparentUpgradeableProxy} and will not
 * include them in the ABI so this interface must be used to interact with it.
 */
interface IEVMPackProxy is IERC1967 {
    /**
     * @notice Upgrades the proxy to a new implementation and calls a function on the new implementation.
     * @param version The new version to upgrade to.
     * @param data The data to pass to the new implementation.
     */
    function upgradeToAndCall(uint24 version, bytes calldata data) external payable;
}

/**
 * @title EVMPackProxy
 * @author EVMPack
 * @notice This contract implements a transparent upgradeable proxy that is upgradeable through an associated {ProxyAdmin} instance.
 * @dev This is a modified version of the OpenZeppelin TransparentUpgradeableProxy contract.
 * It uses a pre-existing ProxyAdmin and includes EVMPack-specific functionality.
 */
contract EVMPackProxy is ERC1967Proxy {
    // An immutable address for the admin to avoid unnecessary SLOADs before each call
    // at the expense of removing the ability to change the admin once it's set.
    // This is acceptable if the admin is always a ProxyAdmin instance or similar contract
    // with its own ability to transfer the permissions to another account.
    address private immutable _admin;
    string private _package;
    address immutable _evmpack;
    bytes32 private _version;


    /**
     * @dev The proxy caller is the current admin, and can't fallback to the proxy target.
     */
    error ProxyDeniedAdminAccess();

    /**
     * @dev The new version is the same as the current version.
     */
    error SameVersion();

    /**
     * @notice Initializes an upgradeable proxy.
     * @param evmpack The address of the EVMPack contract.
     * @param name The name of the package.
     * @param version The initial version of the package.
     * @param _logic The address of the initial implementation contract.
     * @param proxyAdmin The address of the ProxyAdmin contract.
     * @param _data The data to initialize the implementation with.
     */
    constructor(address evmpack, string memory name,  string memory version, address _logic, address proxyAdmin, bytes memory _data) payable ERC1967Proxy(_logic, _data) {
        _admin = proxyAdmin;
        _evmpack = evmpack;
        assembly {
            sstore(_version.slot, keccak256(add(version, 0x20), mload(version)))
        }
        _package = name;
        
        // Set the storage value and emit an event for ERC-1967 compatibility
        ERC1967Utils.changeAdmin(_proxyAdmin());
    }

    /**
     * @dev Returns the admin of this proxy.
     */
    function _proxyAdmin() internal view virtual returns (address) {
        return _admin;
    }

    /**
     * @dev If caller is the admin process the call internally, otherwise transparently fallback to the proxy behavior.
     */
    function _fallback() internal virtual override {
        if (msg.sender == _proxyAdmin()) {
            if (msg.sig != IEVMPackProxy.upgradeToAndCall.selector) {
                revert ProxyDeniedAdminAccess();
            } else {
                _dispatchUpgradeToAndCall();
            }
        } else {
            super._fallback();
        }
    }

    /**
     * @dev Dispatches the upgradeToAndCall function.
     */
    function _dispatchUpgradeToAndCall() private {
        (string memory version, bytes memory data) = abi.decode(msg.data[4:], (string, bytes));
        bytes32 new_version;
        assembly {
            new_version := keccak256(add(version, 0x20), mload(version))
        }
        if(new_version == _version){
            revert SameVersion();
        }
        _version = new_version;
        
        (,IEVMPack.Implementation memory implementation) = IEVMPack(_evmpack).getPackageRelease(_package,version);

        ERC1967Utils.upgradeToAndCall(implementation.target, data);

    }
}