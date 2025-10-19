// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title SemVer
 * @author EVMPack
 * @notice A gas-optimized library for comparing SemVer 2.0.0 versions.
 * @dev Uses custom types for type safety and semantic clarity.
 */
library SemVer {
    // ==================== CUSTOM ERRORS ====================
    error MajorVersionTooHigh(uint256 value);
    error MinorVersionTooHigh(uint256 value);
    error PatchVersionTooHigh(uint256 value);
    error InvalidDigit();
    error SubstringOutOfBounds();
    error InvalidSubstringRange();
    error InvalidVersion();

    // ==================== CUSTOM TYPES ====================
    type MajorVersion is uint8;
    type MinorVersion is uint8;
    type PatchVersion is uint8;
    
    /**
     * @notice Represents a semantic version.
     * @param major The major version number.
     * @param minor The minor version number.
     * @param patch The patch version number.
     * @param prerelease The prerelease identifier (e.g., "alpha", "beta").
     * @param build The build metadata.
     */
    struct Version {
        MajorVersion major;
        MinorVersion minor;
        PatchVersion patch;
        string prerelease;
        string build;
    }
    
    // ==================== TYPE VALIDATION ====================
    
    function validateMajor(MajorVersion major) internal pure {
        uint8 value = MajorVersion.unwrap(major);
        if (value > 100) revert MajorVersionTooHigh(value);
    }
    
    function eqMajor(MajorVersion a, MajorVersion b) internal pure returns (bool) {
        return MajorVersion.unwrap(a) == MajorVersion.unwrap(b);
    }
    
    function gtMajor(MajorVersion a, MajorVersion b) internal pure returns (bool) {
        return MajorVersion.unwrap(a) > MajorVersion.unwrap(b);
    }
    
    function eqMinor(MinorVersion a, MinorVersion b) internal pure returns (bool) {
        return MinorVersion.unwrap(a) == MinorVersion.unwrap(b);
    }
    
    function gtMinor(MinorVersion a, MinorVersion b) internal pure returns (bool) {
        return MinorVersion.unwrap(a) > MinorVersion.unwrap(b);
    }
    
    function eqPatch(PatchVersion a, PatchVersion b) internal pure returns (bool) {
        return PatchVersion.unwrap(a) == PatchVersion.unwrap(b);
    }
    
    function gtPatch(PatchVersion a, PatchVersion b) internal pure returns (bool) {
        return PatchVersion.unwrap(a) > PatchVersion.unwrap(b);
    }
    
    // ==================== CORE FUNCTIONS ====================
    
    /**
     * @notice Compares two versions according to SemVer 2.0.0.
     * @param v1 The first version.
     * @param v2 The second version.
     * @return -1 if v1 < v2, 0 if they are equal, 1 if v1 > v2.
     */
    function compare(Version memory v1, Version memory v2) 
        internal 
        pure 
        returns (int8) 
    {
        // Compare major versions
        if (!eqMajor(v1.major, v2.major)) {
            return gtMajor(v1.major, v2.major) ? int8(1) : int8(-1);
        }
        
        // Compare minor versions
        if (!eqMinor(v1.minor, v2.minor)) {
            return gtMinor(v1.minor, v2.minor) ? int8(1) : int8(-1);
        }
        
        // Compare patch versions
        if (!eqPatch(v1.patch, v2.patch)) {
            return gtPatch(v1.patch, v2.patch) ? int8(1) : int8(-1);
        }
        
        // Compare prerelease identifiers
        return _comparePrerelease(v1.prerelease, v2.prerelease);
    }
    
    /**
     * @notice Checks if a version is stable (has no prerelease identifier).
     * @param v The version to check.
     * @return True if the version is stable, false otherwise.
     */
    function isStable(Version memory v) internal pure returns (bool) {
        return bytes(v.prerelease).length == 0;
    }
    
    /**
     * @notice Checks if a version is a build version.
     * @param v The version to check.
     * @return True if the version has build metadata, false otherwise.
     */
    function isBuild(Version memory v) internal pure returns (bool) {
        return bytes(v.build).length != 0;
    }

    /**
     * @notice Checks for compatibility based on the major version.
     * @param v1 The first version.
     * @param v2 The second version.
     * @return True if the major versions are the same, false otherwise.
     */
    function isCompatible(Version memory v1, Version memory v2) 
        internal 
        pure 
        returns (bool) 
    {
        return eqMajor(v1.major, v2.major);
    }
    
    /**
     * @notice Parses a version string into a Version struct.
     * @param versionStr The version string to parse.
     * @return The parsed Version struct.
     */
    function parse(string memory versionStr) public pure returns (Version memory) {
        bytes memory b = bytes(versionStr);
        uint256 len = b.length;

        if(len == 0){
            revert InvalidVersion();
        }

        Version memory v;
        
        uint256[3] memory components;
        uint256 currentComponent = 0;
        uint256 startIndex = 0;
        uint256 prereleaseStart = 0;
        uint256 buildStart = 0;
        
        for (uint256 i = 0; i <= len; i++) {
            if (i == len || b[i] == '.' || b[i] == '-' || b[i] == '+') {
                if (startIndex == i) revert InvalidVersion(); // Handle empty parts like "1..2"

                if (currentComponent < 3) {
                    components[currentComponent] = _parseUintFromBytes(b, startIndex, i);
                    currentComponent++;
                }
                
                if (i < len) {
                    if (b[i] == '-') {
                        if (prereleaseStart != 0) revert InvalidVersion(); // disallow multiple prerelease separators
                        prereleaseStart = i + 1;
                    } else if (b[i] == '+') {
                        buildStart = i + 1;
                        break; // build metadata is always last
                    }
                }
                
                startIndex = i + 1;
            }
        }
        
        // Validate before creating custom types
        if (components[0] > 100) revert MajorVersionTooHigh(components[0]);
        if (components[1] > 255) revert MinorVersionTooHigh(components[1]);
        if (components[2] > 255) revert PatchVersionTooHigh(components[2]);
        
        // Apply custom types
        v.major = MajorVersion.wrap(uint8(components[0]));
        v.minor = MinorVersion.wrap(uint8(components[1]));
        v.patch = PatchVersion.wrap(uint8(components[2]));
        
        if (prereleaseStart > 0) {
            uint256 end = buildStart > 0 ? buildStart - 1 : len;
            v.prerelease = _substring(versionStr, prereleaseStart, end);
        }
        
        if (buildStart > 0) {
            v.build = _substring(versionStr, buildStart, len);
        }
        
        return v;
    }
    
    // ==================== INTERNAL FUNCTIONS ====================
    
    /**
     * @dev Compares prerelease strings according to SemVer 2.0.0.
     */
    function _comparePrerelease(string memory a, string memory b) 
        private 
        pure 
        returns (int8) 
    {
        if (bytes(a).length == 0 && bytes(b).length > 0) return 1;
        if (bytes(b).length == 0 && bytes(a).length > 0) return -1;
        if (bytes(a).length == 0 && bytes(b).length == 0) return 0;
        
        string[] memory partsA = _splitPrerelease(a);
        string[] memory partsB = _splitPrerelease(b);
        
        uint256 minLength = partsA.length < partsB.length ? partsA.length : partsB.length;
        
        for (uint256 i = 0; i < minLength; i++) {
            int8 result = _comparePrereleasePart(partsA[i], partsB[i]);
            if (result != 0) return result;
        }
        
        if (partsA.length < partsB.length) return -1;
        if (partsA.length > partsB.length) return 1;
        
        return 0;
    }
    
    /**
     * @dev Compares individual prerelease components.
     */
    function _comparePrereleasePart(string memory a, string memory b) 
        private 
        pure 
        returns (int8) 
    {
        bool isNumA = _isNumeric(a);
        bool isNumB = _isNumeric(b);
        
        if (isNumA && isNumB) {
            uint256 numA = _parseUintFromBytes(bytes(a), 0, bytes(a).length);
            uint256 numB = _parseUintFromBytes(bytes(b), 0, bytes(b).length);
            if (numA > numB) return 1;
            if (numA < numB) return -1;
            return 0;
        } else if (isNumA) {
            return -1;
        } else if (isNumB) {
            return 1;
        } else {
            return _compareStrings(a, b);
        }
    }
    
    /**
     * @dev Checks if a string is numeric.
     */
    function _isNumeric(string memory str) private pure returns (bool) {
        bytes memory b = bytes(str);
        if (b.length == 0) return false;
        
        for (uint256 i = 0; i < b.length; i++) {
            uint8 char = uint8(b[i]);
            if (char < 48 || char > 57) {
                return false;
            }
        }
        return true;
    }
    
    /**
     * @dev Parses a uint from a slice of a byte array.
     */
    function _parseUintFromBytes(bytes memory b, uint256 start, uint256 end) private pure returns (uint256) {
        uint256 result = 0;
        for (uint256 i = start; i < end; i++) {
            uint8 digit = uint8(b[i]) - 48;
            if (digit > 9) revert InvalidDigit();
            result = result * 10 + digit;
        }
        return result;
    }
    
    /**
     * @dev Compares two strings lexicographically.
     */
    function _compareStrings(string memory a, string memory b) 
        private 
        pure 
        returns (int8) 
    {
        bytes memory ba = bytes(a);
        bytes memory bb = bytes(b);
        uint256 minLength = ba.length < bb.length ? ba.length : bb.length;
        
        for (uint256 i = 0; i < minLength; i++) {
            if (ba[i] < bb[i]) return -1;
            if (ba[i] > bb[i]) return 1;
        }
        
        if (ba.length < bb.length) return -1;
        if (ba.length > bb.length) return 1;
        
        return 0;
    }
    
    /**
     * @dev Splits a prerelease string into its components.
     */
    function _splitPrerelease(string memory str) 
        private 
        pure 
        returns (string[] memory) 
    {
        bytes memory b = bytes(str);
        uint256 count = 1;
        
        for (uint256 i = 0; i < b.length; i++) {
            if (b[i] == '.') {
                count++;
            }
        }
        
        string[] memory parts = new string[](count);
        uint256 currentPart = 0;
        uint256 startIndex = 0;
        
        for (uint256 i = 0; i <= b.length; i++) {
            if (i == b.length || b[i] == '.') {
                bytes memory part = new bytes(i - startIndex);
                for (uint256 j = startIndex; j < i; j++) {
                    part[j - startIndex] = b[j];
                }
                parts[currentPart] = string(part);
                currentPart++;
                startIndex = i + 1;
            }
        }
        
        return parts;
    }
    
    /**
     * @dev Extracts a substring.
     */
    function _substring(string memory str, uint256 start, uint256 end) 
        private 
        pure 
        returns (string memory) 
    {
        bytes memory bStr = bytes(str);
        if (end > bStr.length) revert SubstringOutOfBounds();
        if (start > end) revert InvalidSubstringRange();
        
        bytes memory bResult = new bytes(end - start);
        
        for (uint256 i = start; i < end; i++) {
            bResult[i - start] = bStr[i];
        }
        
        return string(bResult);
    }
    
    // ==================== HELPER FUNCTIONS ====================

    /**
     * @notice Removes ~ or ^ prefixes from a version string.
     * @param versionStr The version string.
     * @return The version string without prefixes.
     */
    function cleanVersionString(string memory versionStr) internal pure returns (string memory) {
        bytes memory b = bytes(versionStr);
        uint256 len = b.length;

        for (uint256 i = 0; i < len; i++) {
            bytes1 char = b[i];
            // Check if the character is a digit (ASCII 48-57)
            if (char >= '0' && char <= '9') {
                return _substring(versionStr, i, len);
            }
        }

        // If no digit is found, return an empty string.
        return "";
    }
    
    /**
     * @notice Converts a Version struct to a string.
     * @param v The Version struct to convert.
     * @return The string representation of the version.
     */
    function toString(Version memory v) internal pure returns (string memory) {
        string memory base = string(abi.encodePacked(
            _uintToString(MajorVersion.unwrap(v.major)), ".",
            _uintToString(MinorVersion.unwrap(v.minor)), ".",
            _uintToString(PatchVersion.unwrap(v.patch))
        ));
        
        if (bytes(v.prerelease).length > 0) {
            base = string(abi.encodePacked(base, "-", v.prerelease));
        }
        
        if (bytes(v.build).length > 0) {
            base = string(abi.encodePacked(base, "+", v.build));
        }
        
        return base;
    }
    
    /**
     * @dev Converts a uint to a string.
     */
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
