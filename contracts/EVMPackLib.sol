// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./IEVMPack.sol";
import "./SemVer.sol";
import "./EVMPackStorage.sol";

/**
 * @title EVMPackLib
 * @author EVMPack
 * @notice A library containing validation and verification functions for the EVMPack system.
 */
library EVMPackLib {
    using SemVer for SemVer.Version;

    /**
     * @notice Validates a package name.
     * @dev Package names can only contain lowercase letters, numbers, and the characters '@' and '-'.
     * @param name The package name to validate.
     * @return True if the name is valid, false otherwise.
     */
    function validatePackageName(string memory name) internal pure returns (bool) {
        bytes memory b = bytes(name);
        if (b.length == 0) return false;

        for (uint i = 0; i < b.length; i++) {
            bytes1 char = b[i];
            if (
                !(char >= 0x61 && char <= 0x7A) && // a-z
                !(char >= 0x30 && char <= 0x39) && // 0-9
                char != 0x40 && // @
                char != 0x2D // -
            ) {
                return false;
            }
        }
        return true;
    }

    /**
     * @notice Verifies the basic requirements for a new package.
     * @param package The struct containing the new package information.
     * @param fee The required registration fee.
     * @param value The amount of Ether sent with the transaction.
     */
    function verifyPackageBasics(
        IEVMPack.Add memory package,
        uint256 fee,
        uint256 value
    ) internal pure {
        if (!validatePackageName(package.name)) {
            revert IEVMPack.PackageNameInvalid(
                "Accepted only: [a-z0-9] @ and -",
                package.name
            );
        }

        if (bytes(package.meta).length == 0) {
            revert IEVMPack.Empty("package.meta");
        }


        if (value < fee) {
            revert IEVMPack.PackageRegisterFeeRequire(fee);
        }
    }

    /**
     * @notice Verifies the basic requirements for a new release.
     * @param release The struct containing the new release information.
     */
    function verifyReleaseBasics(IEVMPack.Release memory release) internal pure {
        if (bytes(release.manifest).length == 0) {
            revert IEVMPack.Empty("release.note");
        }

        SemVer.parse(release.version);
        
    }

    /**
     * @notice Verifies the basic requirements for a new implementation.
     * @param implementation The struct containing the new implementation information.
     */
    function verifyImplementationBasics(IEVMPack.Implementation memory implementation) internal pure {
        if (implementation.target == address(0)) {
            revert IEVMPack.ZeroAddress("implementation.target");
        }

        if (bytes(implementation.selector).length == 0) {
            revert IEVMPack.Empty("implementation.selector");
        }

    }
        
    
}
