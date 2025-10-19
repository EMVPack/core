// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { IEVMPack } from "./IEVMPack.sol";
import { SemVer } from "./SemVer.sol";

/**
 * @title EVMPackStorage
 * @author EVMPack
 * @notice This library holds the storage for the EVMPack system.
 * @dev It uses the unstructured storage pattern to allow for future upgrades without storage collisions.
 */
library EVMPackStorage {
    // keccak256(abi.encode(uint256(keccak256("evmpack.storage")) - 1)) & ~bytes32(uint256(0xff));
    bytes32 private constant EVMPACK_STORAGE = 0x008396c86f3ac5f3df851d8f0492af696762722a1221c7ae4c55b94bd223b400;
        
    /**
     * @notice The main storage struct for the EVMPack system.
     */
    struct Storage {
        // Fee for package registration
        uint256 _package_register_fee;

        // Core package storage
        mapping(string name => IEVMPack.Package) _packages;
        mapping(string name => address[]) _packageMaintainers;

        // Release storage - key: "name@version"
        mapping(string versionKey => IEVMPack.Release) _releases;
        
        // Implementation storage - key: "name@version"
        mapping(string versionKey => IEVMPack.Implementation) _implementations;
        
        // Indexes for fast lookups
        mapping(string name => SemVer.Version[]) _packageVersions;
        mapping(string name => SemVer.Version[]) _stableVersions;
        mapping(string name => SemVer.Version[]) _prereleaseVersions;
        mapping(string name => SemVer.Version) _latestStableVersion;
        
        // Reverse lookup support
        mapping(string name => mapping(string versionString => bool)) _versionExists;
    }

    /**
     * @dev Returns the storage slot for the EVMPack storage.
     * @return The storage slot.
     */
    function _slot() internal pure returns (bytes32) {
        return EVMPACK_STORAGE;
    }

    /**
     * @notice Returns the main storage struct.
     * @return $ The storage struct.
     */
    function state() internal pure returns (Storage storage $) {
        bytes32 slot = _slot();
        assembly ("memory-safe") {
            $.slot := slot
        }
    }
    
    /**
     * @notice Generates a unique key for a specific version of a package.
     * @param name The name of the package.
     * @param versionString The version of the package.
     * @return The version key.
     */
    function generateVersionKey(string memory name, string memory versionString) 
        internal 
        pure 
        returns (string memory) 
    {
        return string.concat(name, "@", versionString);
    }
}
