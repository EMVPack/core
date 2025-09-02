const { loadConfig, saveConfig } = require('./config');
const { resolveVersion } = require('./versions');
const { install } = require('./install');
const fs = require('fs');
const path = require('path');

async function upgrade(packageName) {
    if (!packageName) {
        console.error('You must specify a package to upgrade.');
        return;
    }

    console.log(`Upgrading ${packageName}...`);

    // 1. Find the latest version of the package
    const latestVersion = await resolveVersion(packageName, '*');
    if (!latestVersion) {
        throw new Error(`Could not find any version for package ${packageName}.`);
    }
    console.log(`Found latest version: ${latestVersion}.`);

    // 2. Update release.json
    const config = loadConfig('release.json');
    if (!config.dependencies || !config.dependencies[packageName]) {
        throw new Error(`${packageName} is not a dependency in release.json.`);
    }
    const newVersionRange = `^${latestVersion}`;
    config.dependencies[packageName] = newVersionRange;
    saveConfig('release.json', config);
    console.log(`Updated ${packageName} to ${newVersionRange} in release.json.`);

    // 3. Delete the lockfile to force re-resolution
    const lockfilePath = path.join(process.cwd(), 'evmpack-lock.json');
    if (fs.existsSync(lockfilePath)) {
        fs.unlinkSync(lockfilePath);
        console.log('Deleted lockfile to allow for fresh dependency resolution.');
    }

    // 4. Re-run install to generate new lockfile and download packages
    console.log('Re-installing all packages to update lockfile...');
    await install();

    console.log(`Successfully upgraded ${packageName} to ${latestVersion}.`);
}

module.exports = { upgrade };