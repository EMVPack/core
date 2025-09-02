// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./EVMPackStorage.sol";
import "./IEVMPack.sol";
import "./EVMPackLib.sol";
import {IEVMPackProxyFactory} from "./EVMPackProxyFactory.sol";

/**
 * @title EVMPack
 * @author EVMPack
 * @notice The main contract for the EVMPack system. It handles package registration, releases, and usage.
 */
contract EVMPack is IEVMPack, Initializable {
    /**
     * @notice Initializes the contract with a registration fee and a proxy factory address.
     * @param fee The package registration fee.
     * @param proxy_factory The address of the proxy factory.
     */
    function initialize(uint256 fee, address proxy_factory) public initializer {
        s()._package_register_fee = fee;
        s()._proxy_factory = proxy_factory;
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
        return "1.0.0";
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
            revert PackageAlreadyExist(name);
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
    function getLatestStableVersion(string calldata name) 
        external 
        view 
        checkNotExist(name) 
        returns (string memory) 
    {
        SemVer.Version memory version = s()._latestStableVersion[name];
        require(SemVer.isStable(version), "No stable version found");
        return SemVer.toString(version);
    }

    /**
     * @notice Returns a list of prerelease versions for a package.
     * @param name The name of the package.
     * @return A list of prerelease version strings.
     */
    function getPrereleases(string calldata name) 
        external 
        view 
        checkNotExist(name) 
        returns (string[] memory) 
    {
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
    function getVersions(string calldata name) 
        external 
        view 
        checkNotExist(name) 
        returns (string[] memory) 
    {
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

        return (s()._packages[name], versionStrings, s()._maintainers[name]);
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

        _setPackageData(
            add,
            msg.sender,
            PackageType.Implementation
        );

        s()._implementations[versionKey] = implementation;

        emit RegisterPackage(
            add.name,
            msg.sender,
            PackageType.Implementation,
            add.meta
        );
        emit NewRelease(
            add.name,
            add.release.version,
            add.release.manifest
        );
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

        _setPackageData(
            add,
            msg.sender,
            PackageType.Library
        );

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
        address owner,
        PackageType _type
    ) internal {

        s()._packages[add.name].name = add.name;
        s()._packages[add.name].meta = add.meta;
        s()._packages[add.name]._type = _type;

        s()._isMaintainer[add.name][owner] = true;
        s()._maintainers[add.name].push(owner);
        s()._maintainerIndex[add.name][owner] = s()._maintainers[add.name].length - 1;


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
        _addRelease(name, release,  versionKey);
        emit NewRelease(name, release.version,  release.manifest);
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
     * @notice Deploys a new instance of a package with a deterministic address.
     * @param name The name of the package.
     * @param versionString The version of the package.
     * @param owner The owner of the new instance.
     * @param initData The initialization data for the new instance.
     * @param salt The salt for deterministic address generation.
     * @return The address of the new instance.
     */
    function usePackageDeterm(
        string calldata name,
        string calldata versionString,
        address owner,
        bytes calldata initData,
        string calldata salt
    ) external checkNotExist(name) returns (address) {
        if (s()._packages[name]._type == PackageType.Implementation) {
            string memory versionKey = EVMPackStorage.generateVersionKey(
                name,
                versionString
            );

            return
                address(
                    IEVMPackProxyFactory(s()._proxy_factory)
                        .usePackageReleaseDeterm(
                            name,
                            s()._implementations[versionKey],
                            versionString,
                            owner,
                            initData,
                            salt
                        )
                );
        }

        return address(0);
    }

    /**
     * @notice Deploys a new instance of a package.
     * @param name The name of the package.
     * @param versionString The version of the package.
     * @param owner The owner of the new instance.
     * @param initData The initialization data for the new instance.
     * @return The address of the new instance.
     */
    function usePackage(
        string calldata name,
        string calldata versionString,
        address owner,
        bytes calldata initData
    ) external checkNotExist(name) returns (address) {
        if (s()._packages[name]._type == PackageType.Implementation) {
            string memory versionKey = EVMPackStorage.generateVersionKey(
                name,
                versionString
            );

            return
                address(
                    IEVMPackProxyFactory(s()._proxy_factory).usePackageRelease(
                        name,
                        s()._implementations[versionKey],
                        versionString,
                        owner,
                        initData
                    )
                );
        }

        return address(0);
    }

    /**
     * @notice Deploys a new instance of a package with a deterministic address and a specified admin.
     * @param name The name of the package.
     * @param versionString The version of the package.
     * @param proxy_admin The admin of the new instance.
     * @param initData The initialization data for the new instance.
     * @param salt The salt for deterministic address generation.
     * @return The address of the new instance.
     */
    function usePackageWithAdminDeterm(
        string calldata name,
        string calldata versionString,
        address proxy_admin,
        bytes calldata initData,
        string calldata salt
    ) external checkNotExist(name) returns (address) {
        if (s()._packages[name]._type == PackageType.Implementation) {
            string memory versionKey = EVMPackStorage.generateVersionKey(
                name,
                versionString
            );
            return
                address(
                    IEVMPackProxyFactory(s()._proxy_factory)
                        .usePackageReleaseWithAdminDeterm(
                            name,
                            s()._implementations[versionKey],
                            versionString,
                            proxy_admin,
                            initData,
                            salt
                        )
                );
        }

        return address(0);
    }

    /**
     * @notice Deploys a new instance of a package with a specified admin.
     * @param name The name of the package.
     * @param versionString The version of the package.
     * @param proxy_admin The admin of the new instance.
     * @param initData The initialization data for the new instance.
     * @return The address of the new instance.
     */
    function usePackageWithAdmin(
        string calldata name,
        string calldata versionString,
        address proxy_admin,
        bytes calldata initData
    ) external checkNotExist(name) returns (address) {
        if (s()._packages[name]._type == PackageType.Implementation) {
            string memory versionKey = EVMPackStorage.generateVersionKey(
                name,
                versionString
            );
            return
                address(
                    IEVMPackProxyFactory(s()._proxy_factory)
                        .usePackageReleaseWithAdmin(
                            name,
                            s()._implementations[versionKey],
                            versionString,
                            proxy_admin,
                            initData
                        )
                );
        }

        return address(0);
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
        if (s()._isMaintainer[name][maintainer]) {
            return;
        }
        s()._isMaintainer[name][maintainer] = true;
        s()._maintainers[name].push(maintainer);
        s()._maintainerIndex[name][maintainer] = s()._maintainers[name].length - 1;
        emit AddMaintainer(name, msg.sender, maintainer);
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
        if (s()._maintainers[name].length == 1) {
            revert LastMaintainer();
        }

        if (!s()._isMaintainer[name][maintainer]) {
            revert MaintainerNotFound(maintainer);
        }

        uint256 index = s()._maintainerIndex[name][maintainer];
        address lastMaintainer = s()._maintainers[name][s()._maintainers[name].length - 1];

        s()._maintainers[name][index] = lastMaintainer;
        s()._maintainerIndex[name][lastMaintainer] = index;

        s()._maintainers[name].pop();
        delete s()._isMaintainer[name][maintainer];
        delete s()._maintainerIndex[name][maintainer];

        emit RemoveMaintainer(name, msg.sender, maintainer);
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

        if(s()._versionExists[packageName][newVersionString]){
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

        bool base_version_exist = s()._versionExists[packageName][SemVer.toString(baseVersion)];
        
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
        if (!s()._isMaintainer[name][msg.sender]) {
            revert PackageAccessDenied();
        }
    }

}
