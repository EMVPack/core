// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../contracts/EVMPack.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

interface IProxyWithAdmin {
    function getProxyAdmin() external view returns(address);
}

contract UpgradeScript is Script {
    function run(address proxyAddress) external {
        uint256 deployerPrivateKey = vm.envUint("EVMPACK_PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        EVMPack newImplementation = new EVMPack();
        
        ProxyAdmin admin = ProxyAdmin(payable(IProxyWithAdmin(proxyAddress).getProxyAdmin()));

        admin.upgradeAndCall(
            ITransparentUpgradeableProxy(payable(proxyAddress)),
            address(newImplementation),
            bytes("")
        );

        vm.stopBroadcast();
    }
}
