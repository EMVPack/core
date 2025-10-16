// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../contracts/EVMPack.sol";
import "../contracts/ProxyFactory.sol";
import "../contracts/EVMPackProxyFactory.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract DeployScript is Script {
    function run() external returns (EVMPack, ProxyAdmin, EVMPackProxyFactory, ProxyFactory) {
        uint256 deployerPrivateKey = vm.envUint("EVMPACK_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address[] memory accounts = vm.getWallets();
        console.log(accounts[0]);

        ProxyFactory proxyFactory = new ProxyFactory();
        EVMPack evmpackImplementation = new EVMPack();
        
        address dummyImplementation = 0x4e59b44847b379578588920cA78FbF26c0B4956C; // Nick's create2 factory

        bytes32 salt = keccak256(abi.encodePacked("EVMPack.dev.v7"));

        (address proxy_admin, address proxyAddress) = proxyFactory.deploy(salt, address(dummyImplementation), vm.envAddress("EVMPACK_DEPLOYER_ADDRESS"), "");

        ProxyAdmin admin = ProxyAdmin(proxy_admin);

        admin.upgradeAndCall(
            ITransparentUpgradeableProxy(payable(proxyAddress)),
            address(evmpackImplementation),
            abi.encodeWithSelector(
                EVMPack.initialize.selector,
                0
            )
        );

        EVMPackProxyFactory evmpackProxyFactory = new EVMPackProxyFactory(proxyAddress);
        vm.stopBroadcast();

        return (EVMPack(proxyAddress), admin, evmpackProxyFactory, proxyFactory);
    }
}
