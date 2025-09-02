// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { SemVer } from "./SemVer.sol";

/**
 * @title IEVMPack
 * @author EVMPack
 * @notice This interface defines the data structures, events, and functions for the EVMPack system.
 * It serves as the central point of interaction for all EVMPack-related operations.
 */
interface IEVMPack {
    // ==================== EVENTS ====================

    /**
     * @notice Emitted when a new package is registered.
     * @param name The name of the package.
     * @param maintainer Owner of package
     * @param packageType The type of the package (Implementation or Library).
     * @param meta The address of the package meta json.
     */
    event RegisterPackage(string indexed name, address indexed maintainer, PackageType packageType, string meta);

    /**
     * @notice Emitted when a new release is added to a package.
     * @param name The name of the package.
     * @param version The version of the new release.
     * @param manifest ipfs hash to json manifest
     */
    event NewRelease(string indexed name, string indexed version, string manifest);

    /**
     * @notice Emitted when a maintainer is added to a package.
     * @param name The name of the package.
     * @param adder The address of the maintainer who add new maintainer.
     * @param added The address of the new maintainer.
     */
    event AddMaintainer(string indexed name, address adder, address added);

    /**
     * @notice Emitted when a maintainer is removed from a package.
     * @param name The name of the package.
     * @param remover The address of who removed maintainer.
     * @param removed The address of removed maintainer.
     */
    event RemoveMaintainer(string indexed name, address remover, address removed);

    /**
     * @notice Emitted when a package's metadata is updated.
     * @param name The name of the package.
     * @param meta The new metadata (e.g., an IPFS hash).
     */
    event UpdatePackageMeta(string name, string meta);

    /**
     * @notice Emitted when a release note is updated for a specific version.
     * @param name The name of the package.
     * @param version The version of the release.
     * @param releaseNote The new release note (e.g., an IPFS hash).
     */
    event UpdateReleaseNote(string name, SemVer.Version version, string releaseNote);

    // ==================== ERRORS ====================

    error PackageAlreadyExist(string name);
    error PackageNotExist(string name);
    error ReleaseNotExist();
    error PackageNameInvalid(string rules, string value);
    error ZeroAddress(string field);
    error VersionIncorrect();
    error VersionAlreadyExist();
    error PackageRegisterFeeRequire(uint256 fee);
    error PackageAccessDenied();
    error IncorrectImplementationType(           
        ImplementationType given,
        ImplementationType _require
    );
    error UnresolvedDependencies(string _error);
    error LastMaintainer();
    error MaintainerNotFound(address maintainer);
    error Empty(string field);
    error InvalidSemVer(string version);
    error PrereleaseHaveStable(string version);
    error VersionNotIncreasing(string newVersion, string lastVersion);

    // ==================== ENUMS ====================

    /**
     * @notice Defines the type of a package.
     */
    enum PackageType {
        Implementation,
        Library
    }

    /**
     * @notice Defines the type of an implementation.
     */
    enum ImplementationType {
        Static,
        Transparent,
        Diamond
    }

    // ==================== STRUCTS ====================

    /**
     * @notice Contains the information needed to register a new package.
     */
    struct Add {
        string name;
        PackageType packageType;
        string meta;
        Release release;
    }

    /**
     * @notice Represents a package in the EVMPack system.
     */
    struct Package {
        address owner;
        PackageType _type;
        string name;
        string meta;
    }

    /**
     * @notice Represents a release of a package.
     */
    struct Release {
        string version;
        string manifest;
    }

    /**
     * @notice Represents the implementation of a package.
     */
    struct Implementation {
        ImplementationType implementation_type;
        address target;
        string selector;
    }

    /**
     * @notice Represents a dependency of a package.
     */
    struct Dependency {
        string name;
        string version;
    }

    // ==================== FUNCTIONS ====================

    function getVersion() external pure returns (string memory);

    function getRegisterFee() external view returns (uint256);

    function getPackageRelease(
        string calldata name,
        string calldata versionString
    ) external view returns (Release memory release, Implementation memory implementation);

    function getLatestStableVersion(string calldata name) external view returns (string memory);

    function getPrereleases(string calldata name) external view returns (string[] memory);

    function getVersions(string calldata name) external view returns (string[] memory);

    function getPackageInfo(
        string calldata name
    ) external view returns (Package memory, string[] memory, address[] memory);

    function registerImplementation(
        Add memory add,
        Implementation memory implementation
    ) external payable;

    function registerLibrary(Add memory add) external payable;

    function addRelease(
        string calldata name,
        Release memory release,
        Implementation memory implementation
    ) external;

    function addRelease(string calldata name, Release memory release) external;

    function usePackageDeterm(
        string calldata name,
        string calldata versionString,
        address owner,
        bytes calldata initData,
        string calldata salt
    ) external returns (address);

    function usePackage(
        string calldata name,
        string calldata versionString,
        address owner,
        bytes calldata initData
    ) external returns (address);

    function usePackageWithAdminDeterm(
        string calldata name,
        string calldata versionString,
        address proxy_admin,
        bytes calldata initData,
        string calldata salt
    ) external returns (address);

    function usePackageWithAdmin(
        string calldata name,
        string calldata versionString,
        address proxy_admin,
        bytes calldata initData
    ) external returns (address);

    function addMaintainer(string calldata name, address maintainer) external;

    function removeMaintainer(string calldata name, address maintainer) external;

    function updatePackageMeta(string calldata name, string calldata meta) external;

    function exist(string memory name) external view returns (bool);

}
