// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.2.0) (proxy/transparent/TransparentUpgradeableProxy.sol)
// Changed by Mikhail Ivantsov

pragma solidity ^0.8.28;

import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC1967} from "@openzeppelin/contracts/interfaces/IERC1967.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";


import "./IEVMPack.sol";


library Bytes32ToString {
    function toString(bytes32 _bytes32) internal pure returns (string memory) {
        uint8 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
}


interface IEVMPackProxy is IERC1967 {
    /**
     * @notice Upgrades the proxy to a new implementation and calls a function on the new implementation.
     * @param version The new version to upgrade to.
     * @param data The data to pass to the new implementation.
     */
    function upgradeToAndCall(string memory version, bytes calldata data) external payable;
    function getPackage() external view returns(string memory _package);
    function getVersion() external view returns(string memory _version);
}

/**
 * @title EVMPackProxy
 * @author EVMPack
 * @notice This contract implements a transparent upgradeable proxy that is upgradeable through an associated {ProxyAdmin} instance.
 * @dev This is a modified version of the OpenZeppelin TransparentUpgradeableProxy contract.
 * It uses a pre-existing ProxyAdmin and includes EVMPack-specific functionality.
 */
contract EVMPackProxy is ERC1967Proxy {
    using Bytes32ToString for bytes32;

    // An immutable address for the admin to avoid unnecessary SLOADs before each call
    // at the expense of removing the ability to change the admin once it's set.
    // This is acceptable if the admin is always a ProxyAdmin instance or similar contract
    // with its own ability to transfer the permissions to another account.
    address private immutable _admin;
    address immutable _evmpack;

    // keccak256("evmpack.proxy.package")
    bytes32 private constant _PACKAGE_SLOT = 0x70498b65356a69a2f8f7c8395b585893b5e05429324c29a9de93624e060412d3;
    // keccak256("evmpack.proxy.version")
    bytes32 private constant _VERSION_SLOT = 0x997a8ac7b54ff35c06e833365e453375ff0d9c46337b8388c9b1417409310334;


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

        require(bytes(name).length <= 32, "EVMPackProxy: package name too long");
        require(bytes(version).length <= 32, "EVMPackProxy: version string too long");

        bytes32 nameBytes32;
        assembly {
            nameBytes32 := mload(add(name, 32))
        }

        bytes32 versionBytes32;
        assembly {
            versionBytes32 := mload(add(version, 32))
        }

        assembly {
            sstore(_PACKAGE_SLOT, nameBytes32)
            sstore(_VERSION_SLOT, versionBytes32)
        }
        
        // Set the storage value and emit an event for ERC-1967 compatibility
        ERC1967Utils.changeAdmin(_proxyAdmin());
    }


    function getPackage() public view returns(string memory _package){
        bytes32 packageNameBytes32;

        assembly {
            packageNameBytes32 := sload(_PACKAGE_SLOT)
        }

        _package = packageNameBytes32.toString();
    }

    function getVersion() public view returns(string memory _version){
        bytes32 versionBytes32;

        assembly {
            versionBytes32 := sload(_VERSION_SLOT)
        }

        _version = versionBytes32.toString();
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
        (string memory newVersionString, bytes memory data) = abi.decode(msg.data[4:], (string, bytes));
        
        require(bytes(newVersionString).length <= 32, "EVMPackProxy: version string too long");
        bytes32 newVersionBytes32;
        assembly {
            newVersionBytes32 := mload(add(newVersionString, 32))
        }

        bytes32 currentVersionBytes32;
        assembly {
            currentVersionBytes32 := sload(_VERSION_SLOT)
        }

        if (newVersionBytes32 == currentVersionBytes32) {
            revert SameVersion();
        }

        assembly {
            sstore(_VERSION_SLOT, newVersionBytes32)
        }
        
        bytes32 packageNameBytes32;

        assembly {
            packageNameBytes32 := sload(_PACKAGE_SLOT)
        }

        string memory packageNameString = packageNameBytes32.toString();

        (, IEVMPack.Implementation memory implementation) = IEVMPack(_evmpack).getPackageRelease(
            packageNameString,
            newVersionString
        );

        ERC1967Utils.upgradeToAndCall(implementation.target, data);
    }



}