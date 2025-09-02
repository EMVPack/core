// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../../contracts/EVMPack.sol";
import "../../contracts/EVMPackProxyFactory.sol";
import "../../contracts/EVMPackLib.sol";
import "../../contracts/SemVer.sol";

import "./DummyImplementation.sol";

contract EVMPackTest is Test {
    EVMPack evmpack;
    EVMPackProxyFactory proxyFactory;

    function setUp() public {
        proxyFactory = new EVMPackProxyFactory();
        evmpack = new EVMPack();
        evmpack.initialize(0, address(proxyFactory));
    }

    function testRegisterLibrary() public {
        IEVMPack.Add memory add;
        add.name = "my-library";
        add.meta = "Qm...meta";
        add.release.version = "1.0.0";
        add.release.manifest = "Qm...manifest";

        vm.expectEmit(true, true, false, false);
        emit IEVMPack.NewRelease(add.name, add.release.version, add.release.manifest);
        evmpack.registerLibrary(add);

        (IEVMPack.Package memory package, string[] memory releases, address[] memory maintainers) = evmpack.getPackageInfo(add.name);

        assertEq(package.name, add.name);
        assertEq(package.meta, add.meta);
        assertEq(uint(package._type), uint(IEVMPack.PackageType.Library));
        assertEq(maintainers.length, 1);
        assertEq(maintainers[0], address(this));
        assertEq(releases.length, 1);
        assertEq(releases[0], add.release.version);
    }

    function testRegisterImplementation() public {
        IEVMPack.Add memory add;
        add.name = "my-implementation";
        add.meta = "Qm...meta";
        add.release.version = "1.0.0";
        add.release.manifest = "Qm...manifest";

        IEVMPack.Implementation memory implementation;
        implementation.implementation_type = IEVMPack.ImplementationType.Static;
        implementation.target = address(0x123);
        implementation.selector = "0x12345678";

        vm.expectEmit(true, true, false, false);
        emit IEVMPack.NewRelease(add.name, add.release.version, add.release.manifest);
        evmpack.registerImplementation(add, implementation);

        (IEVMPack.Package memory package, string[] memory releases, address[] memory maintainers) = evmpack.getPackageInfo(add.name);

        assertEq(package.name, add.name);
        assertEq(package.meta, add.meta);
        assertEq(uint(package._type), uint(IEVMPack.PackageType.Implementation));
        assertEq(maintainers.length, 1);
        assertEq(maintainers[0], address(this));

        assertEq(releases.length, 1);
        assertEq(releases[0], add.release.version);

        (IEVMPack.Release memory release, IEVMPack.Implementation memory impl) = evmpack.getPackageRelease(add.name, add.release.version);
        assertEq(release.version, add.release.version);
        assertEq(release.manifest, add.release.manifest);

        assertEq(uint(impl.implementation_type), uint(implementation.implementation_type));
        assertEq(impl.target, implementation.target);
        assertEq(impl.selector, implementation.selector);
    }

    function testAddRelease() public {
        IEVMPack.Add memory add;
        add.name = "my-library";
        add.meta = "Qm...meta";
        add.release.version = "1.0.0";
        add.release.manifest = "Qm...manifest";


        evmpack.registerLibrary(add);

        IEVMPack.Release memory release;
        release.version = "1.0.1";
        release.manifest = "Qm...new_note";


        vm.expectEmit(true, true, false, false);
        emit IEVMPack.NewRelease(add.name, release.version, add.release.manifest);
        evmpack.addRelease(add.name, release,  IEVMPack.Implementation(IEVMPack.ImplementationType.Static, address(1), "ddddd"));

        (, string[] memory releases, ) = evmpack.getPackageInfo(add.name);

        assertEq(releases.length, 2);
        assertEq(releases[1], release.version);
    }

    function testUpdatePackageMeta() public {
        IEVMPack.Add memory add;
        add.name = "my-library";
        add.meta = "Qm...meta";
        add.release.version = "1.0.0";
        add.release.manifest = "Qm...manifest";

        evmpack.registerLibrary(add);

        string memory newMeta = "Qm...new_meta";
        evmpack.updatePackageMeta(add.name, newMeta);

        (IEVMPack.Package memory package, ,) = evmpack.getPackageInfo(add.name);
        assertEq(package.meta, newMeta);
    }


    function testMaintainers() public {
        IEVMPack.Add memory add;
        add.name = "my-library";
        add.meta = "Qm...meta";
        add.release.version = "1.0.0";
        add.release.manifest = "Qm...manifest";

        evmpack.registerLibrary(add);

        address newMaintainer = address(0x123);
        evmpack.addMaintainer(add.name, newMaintainer);

        (, , address[] memory maintainers) = evmpack.getPackageInfo(add.name);
        assertEq(maintainers.length, 2);
        assertEq(maintainers[1], newMaintainer);

        evmpack.removeMaintainer(add.name, newMaintainer);

        (, , maintainers) = evmpack.getPackageInfo(add.name);
        assertEq(maintainers.length, 1);

        vm.expectRevert(IEVMPack.LastMaintainer.selector);
        evmpack.removeMaintainer(add.name, address(this));
    }

    function testUsePackage() public {
        DummyImplementation dummy = new DummyImplementation();

        IEVMPack.Add memory add;
        add.name = "my-implementation";
        add.meta = "Qm...meta";
        add.release.version = "1.0.0";
        add.release.manifest = "Qm...manifest";

        IEVMPack.Implementation memory implementation;
        implementation.implementation_type = IEVMPack.ImplementationType.Transparent;
        implementation.target = address(dummy);
        implementation.selector = "setX(uint256)";

        evmpack.registerImplementation(add, implementation);

        address proxy = evmpack.usePackage(add.name, add.release.version, address(this), "");

        DummyImplementation proxyDummy = DummyImplementation(proxy);
        proxyDummy.setX(42);

        assertEq(proxyDummy.x(), 42);
    }
     
}