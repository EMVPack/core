// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./EVMPackStorage.sol";
import "./IEVMPack.sol";
import "./EVMPackLib.sol";


/**
 * @title EVMPack
 * @author EVMPack
 * @notice The main contract for the EVMPack system. It handles package registration, releases, and usage.
 */
contract EVMPack is IEVMPack, Initializable {
    /**
     * @notice Initializes the contract with a registration fee and a proxy factory address.
     * @param fee The package registration fee.
     */
    function initialize(uint256 fee) public initializer {
        s()._package_register_fee = fee;
    }

    /**
     * @dev Returns the storage struct.
     */
    function s() private pure returns (EVMPackStorage.Storage storage $) {
        return EVMPackStorage.state();
    }

    /**
     * @notice Returns the version of the EVMPack contract.
     * @return The version string.
     */
    function getVersion() public pure returns (string memory) {
        return "1.0.0-beta.1";
    }

    /**
     * @notice Returns the package registration fee.
     * @return The registration fee.
     */
    function getRegisterFee() public view returns (uint256) {
        return s()._package_register_fee;
    }

    modifier alreadyExist(string memory name) {
        if (exist(name)) {
            revert AlreadyExist("package", name);
        }
        _;
    }


    modifier checkNotExist(string memory name) {
        if (!exist(name)) {
            revert PackageNotExist(name);
        }
        _;
    }

    modifier onlyMaintainer(string memory name) {
        _onlyMaintainer(name);
        _;
    }

    /**
     * @notice Returns the release and implementation details for a specific package version.
     * @param name The name of the package.
     * @param versionString The version of the package.
     * @return release The release details.
     * @return implementation The implementation details.
     */
    function getPackageRelease(
        string calldata name,
        string calldata versionString
    )
        external
        view
        checkNotExist(name)
        returns (Release memory release, Implementation memory implementation)
    {
        if (!s()._versionExists[name][versionString]) revert ReleaseNotExist();

        string memory versionKey = EVMPackStorage.generateVersionKey(
            name,
            versionString
        );
        release = s()._releases[versionKey];
        implementation = s()._implementations[versionKey];
    }

    /**
     * @notice Returns the latest stable version of a package.
     * @param name The name of the package.
     * @return The latest stable version string.
     */
    function getLatestStableVersion(
        string calldata name
    ) external view checkNotExist(name) returns (string memory) {
        SemVer.Version memory version = s()._latestStableVersion[name];
        require(SemVer.isStable(version), "No stable version found");
        return SemVer.toString(version);
    }

    /**
     * @notice Returns a list of prerelease versions for a package.
     * @param name The name of the package.
     * @return A list of prerelease version strings.
     */
    function getPrereleases(
        string calldata name
    ) external view checkNotExist(name) returns (string[] memory) {
        SemVer.Version[] storage prereleases = s()._prereleaseVersions[name];
        string[] memory result = new string[](prereleases.length);

        for (uint i = 0; i < prereleases.length; i++) {
            result[i] = SemVer.toString(prereleases[i]);
        }

        return result;
    }

    /**
     * @notice Returns a list of all versions for a package.
     * @param name The name of the package.
     * @return A list of all version strings.
     */
    function getVersions(
        string calldata name
    ) external view checkNotExist(name) returns (string[] memory) {
        SemVer.Version[] storage versions = s()._packageVersions[name];
        string[] memory result = new string[](versions.length);

        for (uint i = 0; i < versions.length; i++) {
            result[i] = SemVer.toString(versions[i]);
        }

        return result;
    }

    /**
     * @notice Returns information about a package.
     * @param name The name of the package.
     * @return The package details, a list of version strings, and a list of maintainer addresses.
     */
    function getPackageInfo(
        string calldata name
    )
        external
        view
        checkNotExist(name)
        returns (Package memory, string[] memory, address[] memory)
    {
        SemVer.Version[] storage versions = s()._packageVersions[name];
        string[] memory versionStrings = new string[](versions.length);

        for (uint i = 0; i < versions.length; i++) {
            versionStrings[i] = SemVer.toString(versions[i]);
        }

        return (
            s()._packages[name],
            versionStrings,
            s()._packageMaintainers[name]
        );
    }

    /**
     * @notice Registers a new package with an implementation.
     * @param add The package registration details.
     * @param implementation The implementation details.
     */
    function registerImplementation(
        Add memory add,
        Implementation memory implementation
    ) external payable alreadyExist(add.name) {
        EVMPackLib.verifyImplementationBasics(implementation);
        EVMPackLib.verifyPackageBasics(
            add,
            s()._package_register_fee,
            msg.value
        );

        string memory versionKey = EVMPackStorage.generateVersionKey(
            add.name,
            add.release.version
        );

        _addRelease(add.name, add.release, versionKey);

        _setPackageData(add, msg.sender, PackageType.Implementation);

        s()._implementations[versionKey] = implementation;

        emit RegisterPackage(
            add.name,
            msg.sender,
            PackageType.Implementation,
            add.meta
        );
        emit NewRelease(add.name, add.release.version, add.release.manifest);
    }

    /**
     * @notice Registers a new library package.
     * @param add The package registration details.
     */
    function registerLibrary(
        Add memory add
    ) external payable alreadyExist(add.name) {
        EVMPackLib.verifyPackageBasics(
            add,
            s()._package_register_fee,
            msg.value
        );

        string memory versionKey = EVMPackStorage.generateVersionKey(
            add.name,
            add.release.version
        );

        _addRelease(add.name, add.release, versionKey);

        _setPackageData(add, msg.sender, PackageType.Library);

        emit RegisterPackage(
            add.name,
            msg.sender,
            PackageType.Library,
            add.meta
        );
        emit NewRelease(add.name, add.release.version, add.release.manifest);
    }

    /**
     * @dev Sets the initial data for a new package.
     */
    function _setPackageData(
        Add memory add,
        address account,
        PackageType _type
    ) internal {
        s()._packages[add.name].name = add.name;
        s()._packages[add.name].meta = add.meta;
        s()._packages[add.name]._type = _type;
        s()._packageMaintainers[add.name].push(account);
    }

    /**
     * @notice Adds a new release for an existing package.
     * @param name The name of the package.
     * @param release The release details.
     * @param implementation The implementation details.
     */
    function addRelease(
        string calldata name,
        Release memory release,
        Implementation memory implementation
    ) external checkNotExist(name) onlyMaintainer(name) {
        string memory versionKey = EVMPackStorage.generateVersionKey(
            name,
            release.version
        );
        EVMPackLib.verifyImplementationBasics(implementation);

        _addRelease(name, release, versionKey);

        s()._implementations[versionKey] = implementation;
        emit NewRelease(name, release.version, release.manifest);
    }

    /**
     * @notice Adds a new release for an existing library package.
     * @param name The name of the package.
     * @param release The release details.
     */
    function addRelease(
        string calldata name,
        Release memory release
    ) external checkNotExist(name) onlyMaintainer(name) {
        string memory versionKey = EVMPackStorage.generateVersionKey(
            name,
            release.version
        );
        _addRelease(name, release, versionKey);
        emit NewRelease(name, release.version, release.manifest);
    }

    /**
     * @dev Adds a new release to the storage.
     */
    function _addRelease(
        string memory name,
        Release memory release,
        string memory versionKey
    ) private {
        SemVer.Version memory version = validateNewVersion(
            name,
            release.version
        );

        EVMPackLib.verifyReleaseBasics(release);

        s()._releases[versionKey] = release;
        s()._packageVersions[name].push(version);
        s()._versionExists[name][release.version] = true;

        if (SemVer.isStable(version)) {
            s()._stableVersions[name].push(version);
            if (
                s()._stableVersions[name].length == 0 ||
                SemVer.compare(version, s()._latestStableVersion[name]) > 0
            ) {
                s()._latestStableVersion[name] = version;
            }
        } else {
            s()._prereleaseVersions[name].push(version);
        }
    }

    /**
     * @notice Adds a new maintainer to a package.
     * @param name The name of the package.
     * @param maintainer The address of the new maintainer.
     */
    function addMaintainer(
        string calldata name,
        address maintainer
    ) external checkNotExist(name) onlyMaintainer(name) {
        s()._packageMaintainers[name].push(maintainer);
        emit AddMaintainer(name, maintainer);
    }

    /**
     * @notice Removes a maintainer from a package.
     * @param name The name of the package.
     * @param maintainer The address of the maintainer to remove.
     */
    function removeMaintainer(
        string calldata name,
        address maintainer
    ) external checkNotExist(name) onlyMaintainer(name) {
        address[] storage maintainers = s()._packageMaintainers[name];
        if (maintainers.length == 1) {
            revert LastMaintainer();
        }

        for (uint i = 0; i < maintainers.length; i++) {
            if(maintainers[i] == maintainer){
                maintainers[i] = maintainers[maintainers.length-1];
                maintainers.pop();
                emit RemoveMaintainer(name, maintainer);
                return;
            }
        }

        
    }

    /**
     * @notice Updates the metadata of a package.
     * @param name The name of the package.
     * @param meta The new metadata.
     */
    function updatePackageMeta(
        string calldata name,
        string calldata meta
    ) external checkNotExist(name) onlyMaintainer(name) {
        s()._packages[name].meta = meta;

        emit UpdatePackageMeta(name, meta);
    }

    /**
     * @notice Checks if a package exists.
     * @param name The name of the package.
     * @return True if the package exists, false otherwise.
     */
    function exist(string memory name) public view returns (bool) {
        return bytes(s()._packages[name].name).length != 0;
    }

    /**
     * @notice Validates a new version string.
     * @param packageName The name of the package.
     * @param newVersionString The new version string.
     * @return The parsed Version struct.
     */
    function validateNewVersion(
        string memory packageName,
        string memory newVersionString
    ) internal view returns (SemVer.Version memory) {
        if (s()._versionExists[packageName][newVersionString]) {
            revert IEVMPack.VersionAlreadyExist();
        }

        SemVer.Version memory newVersion = SemVer.parse(newVersionString);

        SemVer.Version[] storage versions = s()._packageVersions[packageName];

        // Create a base version (without prerelease/build)
        SemVer.Version memory baseVersion = SemVer.Version(
            newVersion.major,
            newVersion.minor,
            newVersion.patch,
            "",
            ""
        );

        bool base_version_exist = s()._versionExists[packageName][
            SemVer.toString(baseVersion)
        ];

        if (versions.length > 0 && !SemVer.isBuild(newVersion)) {
            SemVer.Version memory lastVersion = versions[versions.length - 1];

            // Rule 1: The version must be increasing.
            if (SemVer.compare(newVersion, lastVersion) <= 0) {
                revert IEVMPack.VersionNotIncreasing(
                    SemVer.toString(newVersion),
                    SemVer.toString(lastVersion)
                );
            }

            // Rule 2: A prerelease version cannot have a stable base version.
            if (!SemVer.isStable(newVersion)) {
                if (base_version_exist) {
                    revert IEVMPack.PrereleaseHaveStable(newVersionString);
                }
            }
        }

        return newVersion;
    }

    /**
     * @dev Checks if the caller is a maintainer of a package.
     */
    function _onlyMaintainer(string memory name) private view {
        address[] memory maintainers = s()._packageMaintainers[name];
        for (uint i = 0; i < maintainers.length; i++) {
            if (maintainers[i] == msg.sender) {
                return;
            }
        }

        revert PackageAccessDenied();
    }


}
