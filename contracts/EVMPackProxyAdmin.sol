// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.2.0) (proxy/transparent/ProxyAdmin.sol)

pragma solidity ^0.8.28;

import {IEVMPackProxy} from "./EVMPackProxy.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";


interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
interface IEVMPackProxyAdmin is IERC165 {
    function upgradeAndCall(IEVMPackProxy proxy, string memory version, bytes memory data) external payable;
}

/**
 * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
 * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
 */
contract EVMPackProxyAdmin is IEVMPackProxyAdmin, Ownable {
    /**
     * @dev The version of the upgrade interface of the contract. If this getter is missing, both `upgrade(address,address)`
     * and `upgradeAndCall(address,address,bytes)` are present, and `upgrade` must be used if no function should be called,
     * while `upgradeAndCall` will invoke the `receive` function if the third argument is the empty byte string.
     * If the getter returns `"5.0.0"`, only `upgradeAndCall(address,address,bytes)` is present, and the third argument must
     * be the empty byte string if no function should be called, making it impossible to invoke the `receive` function
     * during an upgrade.
     */
    string public constant UPGRADE_INTERFACE_VERSION = "5.0.0";

    /**
     * @dev Sets the initial owner who can perform upgrades.
     */
    constructor(address initialOwner) Ownable(initialOwner) {}

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return (type(IEVMPackProxyAdmin).interfaceId == interfaceId);
    }
    /**
     * @dev Upgrades `proxy` to `implementation` and calls a function on the new implementation.
     * See {TransparentUpgradeableProxy-_dispatchUpgradeToAndCall}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     * - If `data` is empty, `msg.value` must be zero.
     */
    function upgradeAndCall(
        IEVMPackProxy proxy,
        string memory version,
        bytes memory data
    ) public payable virtual onlyOwner {
        proxy.upgradeToAndCall{value: msg.value}(version, data);
    }
}
