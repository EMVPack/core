# EVMPack Release Notes

## Overview

EVMPack is a decentralized package manager for Ethereum Virtual Machine (EVM) compatible blockchains. It allows developers to register, manage, and use reusable smart contracts and libraries.

This document provides an overview of the EVMPack smart contracts, including their functions, events, and data structures.

## Core Contracts

### `EVMPack.sol`

This is the main contract of the EVMPack system. It manages the registration and release of packages.

#### Functions

- `initialize(uint256 fee)`: Initializes the contract with a registration fee.
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

This contract is a factory for deploying new `EVMPackProxy` instances. It simplifies the process of deploying a new proxy contract for a specific package release.

When you want to use a package from the EVMPack registry in your own smart contracts, you should use the `EVMPackProxyFactory` to create a new proxy instance of the package's implementation. This ensures that you are using the correct and verified version of the package.

#### How to use

To use the factory, you need to call the `usePackageRelease` function with the following parameters:

- `name`: The name of the package.
- `version`: The version of the package to use.
- `owner`: The owner of the new proxy contract. If this address is a contract that implements the `IEVMPackProxyAdmin` interface, it will be used as the admin for the new proxy. Otherwise, a new `EVMPackProxyAdmin` contract will be deployed with the provided address as its owner.
- `initData`: The initialization data for the proxy contract.
- `salt`: A unique salt for creating a deterministic address (optional).

The function will return the address of the newly created proxy contract.

Here is an example of how to use the `EVMPackProxyFactory` in your smart contract:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { IEVMPackProxyFactory } from "@evmpack/evmpack-1.0.0-beta.1/contracts/EVMPackProxyFactory.sol";
import { EVMPackAddreses } from "@evmpack/evmpack-1.0.0-beta.1/contracts/EVMPackAddreses.sol";

contract MyContract {
    IEVMPackProxyFactory evmpackFactory;

    constructor() {
        evmpackFactory = IEVMPackProxyFactory(EVMPackAddreses.PROXY_FACTORY);
    }

    function deployMyPackage() public {
        address myPackage = evmpackFactory.usePackageRelease(
            "my-package",
            "1.0.0",
            msg.sender,
            abi.encodeWithSignature("initialize()"),
            ""
        );
        // Now you can interact with myPackage
    }
}
```

### `ProxyFactory.sol`

This contract is a generic proxy factory.
