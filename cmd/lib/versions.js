const semver = require('semver');
const { getPackage } = require('./packages');

/**
 * Finds the latest version of a package that satisfies a given semver range.
 * @param {string} packageName - The name of the package.
 * @param {string} versionRange - The semver range (e.g., "^1.2.3").
 * @returns {Promise<string|null>} - The resolved specific version, or null if no match is found.
 */
async function resolveVersion(packageName, versionRange) {
    const { versionStrings } = await getPackage(packageName);
    if (!versionStrings || versionStrings.length === 0) {
        return null;
    }

    // Find the latest version that satisfies the range.
    // The `maxSatisfying` function from `semver` is perfect for this.
    const latestMatching = semver.maxSatisfying(versionStrings, versionRange);

    return latestMatching;
}

module.exports = { resolveVersion };
