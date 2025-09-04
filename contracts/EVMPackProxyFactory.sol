// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;


import "./IEVMPack.sol";
import "./EVMPackLib.sol";
import "./EVMPackProxy.sol";
import "./EVMPackProxyAdmin.sol";

interface IEVMPackProxyFactory{
    function usePackageRelease(string calldata name, string calldata version, address owner, bytes calldata initData, string calldata salt) external returns(address);
}

contract EVMPackProxyFactory is IEVMPackProxyFactory {

    IEVMPack _evmpack;

    error IncorrectImplementation();
    error IncorrectOwner();

    constructor(address evmpack){
        _evmpack = IEVMPack(evmpack);
    }


    function usePackageRelease(string calldata name, string calldata version, address owner, bytes calldata initData, string calldata salt) external returns(address){

        if(owner == address(0)){
            revert IncorrectOwner();
        }

        (, IEVMPack.Implementation memory impl) = _evmpack.getPackageRelease(name, version);


        if(impl.target == address(0)){
            revert IncorrectImplementation();
        }
        
        address proxy_admin;

        if(!isAdminContract(owner)){
            proxy_admin = address(new EVMPackProxyAdmin(owner));
        }else{
            proxy_admin = owner;
        }
        

        if(bytes(salt).length == 0 ){
            EVMPackProxy proxy = new EVMPackProxy(
                address(this),
                name,
                version,
                impl.target,
                proxy_admin,
                initData
            );

            return address(proxy);
        }else{
            EVMPackProxy proxy = new EVMPackProxy{
                salt: _salt(salt, initData)
            }(
                address(this),
                name,
                version,
                impl.target,
                proxy_admin,
                initData
            );

            return address(proxy);
        }

    }


    function isAdminContract(address _addr) internal view returns (bool) {
        try IERC165(_addr).supportsInterface(type(IEVMPackProxyAdmin).interfaceId) returns (bool success) {
            if(success){
                return true;
            }else{
                return false;
            }

        } catch  {
            return false;
        }
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