// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./EVMPackTransparentUpgradeableProxy.sol"; 

/**
 * @title ProxyFactory
 * @author EVMPack
 * @notice A factory for deploying new proxy contracts.
 * @dev This contract is used to create new instances of proxy contracts, which can then be used to delegate calls to an implementation contract.
 */
contract ProxyFactory {
    /**
     * @notice Emitted when a new proxy is created.
     * @param addr The address of the new proxy contract.
     */
    event Deployed(address addr);


    function deploy(bytes32 salt, address logic, address admin, bytes memory data) public returns (address proxy_admin, address proxy) {
        EVMPackTransparentUpgradeableProxy _proxy = new EVMPackTransparentUpgradeableProxy{salt: salt}(logic, admin, data);
        proxy_admin = _proxy.getProxyAdmin();
        proxy = address(_proxy);
        emit Deployed(proxy);
    }
}