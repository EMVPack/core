// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;


import "./IEVMPack.sol";
import "./EVMPackLib.sol";
import "./EVMPackProxy.sol";
import "./EVMPackProxyAdmin.sol";

interface IEVMPackProxyFactory{
    event ProxyCreated(address indexed proxy, address indexed proxy_admin);
    event ProxyAdminCreated(address indexed proxy);
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
            emit ProxyAdminCreated(proxy_admin);
        }else{
            proxy_admin = owner;
        }
        

        if(bytes(salt).length == 0 ){
            EVMPackProxy proxy = new EVMPackProxy(
                address(_evmpack),
                name,
                version,
                impl.target,
                proxy_admin,
                initData
            );
            emit ProxyCreated(address(proxy), proxy_admin);
            return address(proxy);
        }else{
            EVMPackProxy proxy = new EVMPackProxy{
                salt: _salt(salt, initData)
            }(
                address(_evmpack),
                name,
                version,
                impl.target,
                proxy_admin,
                initData
            );
            emit ProxyCreated(address(proxy), proxy_admin);
            return address(proxy);
        }

    }


    function isAdminContract(address _addr) internal view returns (bool) {
        if (_addr.code.length == 0) {
            return false;
        }

        try IERC165(_addr).supportsInterface(type(IEVMPackProxyAdmin).interfaceId) returns (bool success) {
            return success;
        } catch {
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