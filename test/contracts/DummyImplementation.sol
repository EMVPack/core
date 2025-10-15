// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract DummyImplementation is Initializable, OwnableUpgradeable {
    uint256 public _x;

    function initialize(uint256 x, address owner) public initializer {
        _x = x;

        __Ownable_init(owner);
    }

    function setX(uint256 x) public {
        _x = x;
    }
}
