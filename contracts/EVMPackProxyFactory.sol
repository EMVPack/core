// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;


import "./IEVMPack.sol";
import "./EVMPackLib.sol";
import "./EVMPackProxy.sol";
import "./EVMPackProxyAdmin.sol";

interface IEVMPackProxyFactory{
    function usePackageReleaseDeterm(string calldata name, IEVMPack.Implementation memory implementation, string calldata version, address owner, bytes calldata initData, string calldata salt) external returns(address);
    function usePackageRelease(string calldata name, IEVMPack.Implementation memory implementation, string calldata version, address owner, bytes calldata initData) external returns(address);
    function usePackageReleaseWithAdminDeterm(string calldata name, IEVMPack.Implementation memory implementation, string calldata version, address proxy_admin, bytes calldata initData, string memory salt) external returns(address);
    function usePackageReleaseWithAdmin(string calldata name, IEVMPack.Implementation memory implementation, string calldata version, address proxy_admin, bytes calldata initData) external returns(address);
}

contract EVMPackProxyFactory is IEVMPackProxyFactory {


    function usePackageReleaseDeterm(string calldata name, IEVMPack.Implementation memory implementation, string calldata version, address owner, bytes calldata initData, string calldata salt) external returns(address){


        address proxy_admin = address(new EVMPackProxyAdmin(owner));

        EVMPackProxy proxy = new EVMPackProxy{
            salt: _salt(salt, initData)
        }(
            address(this),
            name,
            version,
            implementation.target,
            proxy_admin,
            initData
        );

        return address(proxy);
    }


    function usePackageRelease(string calldata name, IEVMPack.Implementation memory implementation, string calldata version, address owner, bytes calldata initData) external returns(address){


        address proxy_admin = address(new EVMPackProxyAdmin(owner));

        EVMPackProxy proxy = new EVMPackProxy(
            address(this),
            name,
            version,
            implementation.target,
            proxy_admin,
            initData
        );

        return address(proxy);
    }



    function usePackageReleaseWithAdminDeterm(string calldata name, IEVMPack.Implementation memory implementation, string calldata version, address proxy_admin, bytes calldata initData, string memory salt) external returns(address){

        EVMPackProxy proxy = new EVMPackProxy{
            salt: _salt(salt, initData)
        }(
            address(this),
            name,
            version,
            implementation.target,
            proxy_admin,
            initData
        );

        return address(proxy);
    }

    function usePackageReleaseWithAdmin(string calldata name, IEVMPack.Implementation memory implementation, string calldata version, address proxy_admin, bytes calldata initData) external returns(address){

        EVMPackProxy proxy = new EVMPackProxy(
            address(this),
            name,
            version,
            implementation.target,
            proxy_admin,
            initData
        );

        return address(proxy);
    }




    function _salt(string memory salt, bytes calldata initData) internal pure returns(bytes32){
        return keccak256(
            abi.encode(
                "evmpack",
                salt,
                initData
            )
        );
    }
}