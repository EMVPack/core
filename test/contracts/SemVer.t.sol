// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "src/SemVer.sol";

contract SemVerTest is Test {
    using SemVer for SemVer.Version;

    // ==================== ТЕСТЫ ПАРСИНГА ====================

    function testParseBasic() public pure {
        SemVer.Version memory v = SemVer.parse("1.2.3");
        assertEq(SemVer.MajorVersion.unwrap(v.major), 1);
        assertEq(SemVer.MinorVersion.unwrap(v.minor), 2);
        assertEq(SemVer.PatchVersion.unwrap(v.patch), 3);
        assertEq(v.prerelease, "");
        assertEq(v.build, "");
    }

    function testParseWithPrerelease() public pure {
        SemVer.Version memory v = SemVer.parse("1.2.3-alpha.1");
        assertEq(SemVer.MajorVersion.unwrap(v.major), 1);
        assertEq(SemVer.MinorVersion.unwrap(v.minor), 2);
        assertEq(SemVer.PatchVersion.unwrap(v.patch), 3);
        assertEq(v.prerelease, "alpha.1");
        assertEq(v.build, "");
    }

    function testParseWithBuild() public pure {
        SemVer.Version memory v = SemVer.parse("1.2.3+build.001");
        assertEq(SemVer.MajorVersion.unwrap(v.major), 1);
        assertEq(SemVer.MinorVersion.unwrap(v.minor), 2);
        assertEq(SemVer.PatchVersion.unwrap(v.patch), 3);
        assertEq(v.prerelease, "");
        assertEq(v.build, "build.001");

        assertEq(SemVer.isBuild(v), true);
    }

    function testParseFull() public pure {
        SemVer.Version memory v = SemVer.parse("1.2.3-alpha.1+build.001");
        assertEq(SemVer.MajorVersion.unwrap(v.major), 1);
        assertEq(SemVer.MinorVersion.unwrap(v.minor), 2);
        assertEq(SemVer.PatchVersion.unwrap(v.patch), 3);
        assertEq(v.prerelease, "alpha.1");
        assertEq(v.build, "build.001");
    }

    // ==================== ТЕСТЫ СРАВНЕНИЯ ====================

    function testCompareBasic() public pure {
        SemVer.Version memory v1 = SemVer.parse("1.2.3");
        SemVer.Version memory v2 = SemVer.parse("1.2.4");
        
        int8 result = SemVer.compare(v1, v2);
        assertEq(result, -1); // v1 < v2
    }

    function testComparePrerelease() public pure {
        SemVer.Version memory v1 = SemVer.parse("1.2.3-alpha.1");
        SemVer.Version memory v2 = SemVer.parse("1.2.3-alpha.10");
        
        int8 result = SemVer.compare(v1, v2);
        assertEq(result, -1); // alpha.1 < alpha.10
    }

    function testCompareStableVsPrerelease() public pure {
        SemVer.Version memory v1 = SemVer.parse("1.2.3-alpha.1");
        SemVer.Version memory v2 = SemVer.parse("1.2.3");
        
        int8 result = SemVer.compare(v1, v2);
        assertEq(result, -1); // alpha < stable
    }

    function testCompareDifferentTypes() public pure {
        SemVer.Version memory v1 = SemVer.parse("1.2.3-alpha.1");
        SemVer.Version memory v2 = SemVer.parse("1.2.3-alpha.beta");
        
        int8 result = SemVer.compare(v1, v2);
        assertEq(result, -1); // 1 < beta (number < string)
    }

    function testCompareEqual() public pure {
        SemVer.Version memory v1 = SemVer.parse("1.2.3");
        SemVer.Version memory v2 = SemVer.parse("1.2.3");
        
        int8 result = SemVer.compare(v1, v2);
        assertEq(result, 0); // equal
    }

    // ==================== ТЕСТЫ ВАЛИДАЦИИ ====================

    function testValidation() public pure {
        SemVer.Version memory v = SemVer.parse("100.255.255");
        assertEq(SemVer.MajorVersion.unwrap(v.major), 100);
        assertEq(SemVer.MinorVersion.unwrap(v.minor), 255);
        assertEq(SemVer.PatchVersion.unwrap(v.patch), 255);
    }


    /// forge-config: default.allow_internal_expect_revert = true
    function testValidationMajorTooHigh() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                SemVer.MajorVersionTooHigh.selector,
                101
            )
        );
        SemVer.parse("101.0.0");
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function testValidationMinorTooHigh() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                SemVer.MinorVersionTooHigh.selector,
                256
            )
        );
        SemVer.parse("1.256.0");
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function testValidationPatchTooHigh() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                SemVer.PatchVersionTooHigh.selector,
                256
            )
        );
        SemVer.parse("1.0.256");
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function testValidationInvalidDigit() public {
        vm.expectRevert(SemVer.InvalidDigit.selector);
        SemVer.parse("1.0.a");
    }

    // ==================== ТЕСТЫ ВСПОМОГАТЕЛЬНЫХ ФУНКЦИЙ ====================

    function testIsStable() public pure {
        SemVer.Version memory v1 = SemVer.parse("1.2.3");
        SemVer.Version memory v2 = SemVer.parse("1.2.3-alpha.1");
        
        assertTrue(SemVer.isStable(v1));
        assertFalse(SemVer.isStable(v2));
    }

    function testIsCompatible() public pure {
        SemVer.Version memory v1 = SemVer.parse("2.0.0");
        SemVer.Version memory v2 = SemVer.parse("2.1.0");
        SemVer.Version memory v3 = SemVer.parse("3.0.0");
        
        assertTrue(SemVer.isCompatible(v1, v2));
        assertFalse(SemVer.isCompatible(v1, v3));
    }

    function testToString() public pure {
        SemVer.Version memory v = SemVer.parse("1.2.3-alpha.1+build.001");
        string memory result = SemVer.toString(v);
        
        assertEq(result, "1.2.3-alpha.1+build.001");
    }

    function testToStringStable() public pure {
        SemVer.Version memory v = SemVer.parse("1.2.3");
        string memory result = SemVer.toString(v);
        
        assertEq(result, "1.2.3");
    }

    function testCleanVersionString() public pure {
        assertEq(SemVer.cleanVersionString(">=1.2.3"), "1.2.3");
        assertEq(SemVer.cleanVersionString("<=1.2.3"), "1.2.3");
        assertEq(SemVer.cleanVersionString(">1.2.3"), "1.2.3");
        assertEq(SemVer.cleanVersionString("<1.2.3"), "1.2.3");
        assertEq(SemVer.cleanVersionString("=1.2.3"), "1.2.3");
        assertEq(SemVer.cleanVersionString("~1.2.3"), "1.2.3");
        assertEq(SemVer.cleanVersionString("^1.2.3"), "1.2.3");
        assertEq(SemVer.cleanVersionString("=>1.2.3"), "1.2.3");
        assertEq(SemVer.cleanVersionString("1.2.3"), "1.2.3");
        assertEq(SemVer.cleanVersionString(">=>"), "");
        assertEq(SemVer.cleanVersionString(""), "");
    }

    // ==================== ТЕСТЫ КРАЙНИХ СЛУЧАЕВ ====================

    function testEdgeCaseEmptyString() public pure {
        SemVer.Version memory v = SemVer.parse("0.0.0");
        assertEq(SemVer.MajorVersion.unwrap(v.major), 0);
        assertEq(SemVer.MinorVersion.unwrap(v.minor), 0);
        assertEq(SemVer.PatchVersion.unwrap(v.patch), 0);
    }

    function testEdgeCaseLongPrerelease() public pure {
        SemVer.Version memory v = SemVer.parse("1.0.0-very.long.prerelease.identifier");
        assertEq(v.prerelease, "very.long.prerelease.identifier");
    }

    function testEdgeCaseBuildMetadata() public pure {
        SemVer.Version memory v = SemVer.parse("1.0.0+exp.sha.5114f85");
        assertEq(v.build, "exp.sha.5114f85");
    }

    // ==================== FUZZ ТЕСТЫ ====================

    function testFuzzParseToString(uint8 major, uint8 minor, uint8 patch) public pure {
        vm.assume(major <= 100);
        vm.assume(minor <= 255);
        vm.assume(patch <= 255);
        
        string memory versionStr = string(abi.encodePacked(
            _uintToString(major), ".",
            _uintToString(minor), ".",
            _uintToString(patch)
        ));
        
        SemVer.Version memory v = SemVer.parse(versionStr);
        string memory result = SemVer.toString(v);
        
        assertEq(result, versionStr);
    }

    function _uintToString(uint256 value) private pure returns (string memory) {
        if (value == 0) return "0";
        
        uint256 temp = value;
        uint256 digits;
        
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        
        bytes memory buffer = new bytes(digits);
        
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + value % 10));
            value /= 10;
        }
        
        return string(buffer);
    }
}