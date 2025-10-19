// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract EVMPackTransparentUpgradeableProxy is TransparentUpgradeableProxy {
    constructor(address _logic, address initialOwner, bytes memory _data) payable TransparentUpgradeableProxy(_logic, initialOwner, _data){}

    function getProxyAdmin() public view returns(address){
        return ERC1967Utils.getAdmin();
    }

    receive() external payable {}

}