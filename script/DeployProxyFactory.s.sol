// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../contracts/EVMPack.sol";
import "../contracts/ProxyFactory.sol";
import "../contracts/EVMPackProxyFactory.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract DeployScript is Script {
    function run() external returns (EVMPackProxyFactory) {
        uint256 deployerPrivateKey = vm.envUint("EVMPACK_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address[] memory accounts = vm.getWallets();
        console.log(accounts[0]);

        EVMPackProxyFactory evmpackProxyFactory = new EVMPackProxyFactory(0x4fCD571Dbc9C7f8b235182B704665Ffd9dAC6289);
        vm.stopBroadcast();

        return evmpackProxyFactory;
    }
}
