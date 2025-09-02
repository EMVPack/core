# EVMPack Release Notes

## Overview

EVMPack is a decentralized package manager for Ethereum Virtual Machine (EVM) compatible blockchains. It allows developers to register, manage, and use reusable smart contracts and libraries.

This document provides an overview of the EVMPack smart contracts, including their functions, events, and data structures.

## Core Contracts

### `EVMPack.sol`

This is the main contract of the EVMPack system. It manages the registration and release of packages.

#### Functions

- `initialize(uint256 fee, address proxy_factory)`: Initializes the contract with a registration fee and a proxy factory address.
- `getVersion()`: Returns the version of the EVMPack contract.
- `getRegisterFee()`: Returns the package registration fee.
- `getPackageRelease(string calldata name, string calldata versionString)`: Returns the release and implementation details for a specific package version.
- `getLatestStableVersion(string calldata name)`: Returns the latest stable version of a package.
- `getPrereleases(string calldata name)`: Returns a list of prerelease versions for a package.
- `getVersions(string calldata name)`: Returns a list of all versions for a package.
- `getPackageInfo(string calldata name)`: Returns information about a package, including its versions and maintainers.
- `registerImplementation(Add memory add, Implementation memory implementation)`: Registers a new package with an implementation.
- `registerLibrary(Add memory add)`: Registers a new library package.
- `addRelease(string calldata name, Release memory release, Implementation memory implementation)`: Adds a new release for an existing package.
- `addRelease(string calldata name, Release memory release)`: Adds a new release for an existing library package.
- `usePackageDeterm(string calldata name, string calldata versionString, address owner, bytes calldata initData, string calldata salt)`: Deploys a new instance of a package with a deterministic address.
- `usePackage(string calldata name, string calldata versionString, address owner, bytes calldata initData)`: Deploys a new instance of a package.
- `usePackageWithAdminDeterm(string calldata name, string calldata versionString, address proxy_admin, bytes calldata initData, string calldata salt)`: Deploys a new instance of a package with a deterministic address and a specified admin.
- `usePackageWithAdmin(string calldata name, string calldata versionString, address proxy_admin, bytes calldata initData)`: Deploys a new instance of a package with a specified admin.
- `addMaintainer(string calldata name, address maintainer)`: Adds a new maintainer to a package.
- `removeMaintainer(string calldata name, address maintainer)`: Removes a maintainer from a package.
- `updatePackageMeta(string calldata name, string calldata meta)`: Updates the metadata of a package.
- `exist(string memory name)`: Checks if a package exists.

### `IEVMPack.sol`

This interface defines the data structures, events, and functions for the EVMPack system.

#### Enums

- `PackageType`: `Implementation`, `Library`
- `ImplementationType`: `Static`, `Transparent`, `Diamond`

#### Structs

- `Add`: Contains information for registering a new package.
- `Package`: Contains information about a package.
- `Release`: Contains information about a release.
- `Implementation`: Contains information about an implementation.
- `Dependency`: Contains information about a dependency.

#### Events

- `RegisterPackage`: Emitted when a new package is registered.
- `NewRelease`: Emitted when a new release is added.
- `AddMaintainer`: Emitted when a maintainer is added.
- `RemoveMaintainer`: Emitted when a maintainer is removed.
- `UpdatePackageMeta`: Emitted when a package's metadata is updated.
- `UpdateReleaseNote`: Emitted when a release note is updated.

### `SemVer.sol`

This library provides functions for parsing and comparing SemVer 2.0.0 version strings.

#### Functions

- `compare(Version memory v1, Version memory v2)`: Compares two versions.
- `isStable(Version memory v)`: Checks if a version is stable.
- `isBuild(Version memory v)`: Checks if a version is a build.
- `isCompatible(Version memory v1, Version memory v2)`: Checks if two versions are compatible.
- `parse(string memory versionStr)`: Parses a version string into a `Version` struct.
- `toString(Version memory v)`: Converts a `Version` struct to a string.

## Proxy Contracts

### `EVMPackProxy.sol`

This contract implements a transparent upgradeable proxy.

### `EVMPackProxyAdmin.sol`

This contract is the admin for the `EVMPackProxy`.

### `EVMPackProxyFactory.sol`

This contract is a factory for deploying new `EVMPackProxy` instances.

### `ProxyFactory.sol`

This contract is a generic proxy factory.
