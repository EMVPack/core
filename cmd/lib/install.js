const fs = require('fs');
const path = require('path');
const os = require('os');
const { readLockfile, writeLockfile } = require('./lockfile');
const { resolveVersion } = require('./versions');
const { getPackageRelease } = require('./packages');
const { downloadFile } = require('./ipfs');
const { extractTarball } = require('./tar');
const { loadConfig, saveConfig } = require('./config');

// Main entry point for the install command
async function install(packageName, versionRange) {

    const lockfile = readLockfile();

    if (packageName) {
        // Add or update a specific package
        console.log(`Resolving package ${packageName}@${versionRange || 'latest'}...`);
        await addPackageToLock(packageName, versionRange || '*', lockfile || { packages: {} });
    } else if (lockfile) {
        // Install from lockfile
        console.log('Installing from evmpack-lock.json...');
        await installFromLockfile(lockfile);
    } else {
        // Install from release.json
        console.log('No lockfile found. Installing from release.json...');
        const config = loadConfig('release.json');
        const newLockfile = { packages: {} };
        if (config.dependencies) {
            for (const name of Object.keys(config.dependencies)) {
                await addPackageToLock(name, config.dependencies[name], newLockfile);
            }
        }
    }
}

async function addPackageToLock(packageName, versionRange, lockfile, saveRelease = true) {


    const exactVersion = await resolveVersion(packageName, versionRange);
    if (!exactVersion) {
        throw new Error(`Could not resolve a version for ${packageName}@${versionRange}`);
    }

    const packageKey = `${packageName}@${exactVersion}`;
    if (lockfile.packages[packageKey]) {
        console.log(`Package ${packageKey} is already processed.`);
        return; // Already in lockfile, skip
    }

    console.log(`Fetching release info for ${packageName}@${exactVersion}...`);
    const { release } = await getPackageRelease(packageName, exactVersion);

    if (!release) {
        throw new Error(`Could not get release info for ${packageName}-${exactVersion}`);
    }

    // Add to lockfile
    lockfile.packages[packageKey] = {
        version: exactVersion,
        resolved: release.tarball,
        dependencies: release.dependencies
    };

    // Recursively add dependencies
    if (release.dependencies) {
        for (const key of Object.keys(release.dependencies)) {
            await addPackageToLock(release.dependencies[key].name, release.dependencies[key].version, lockfile, false);
        }
    }

    // Write the final lockfile and download
    writeLockfile(lockfile.packages);
    console.log(`Locked ${packageName}@${exactVersion}.`);

    // Download and extract the package
    await downloadAndInstall(packageName, exactVersion, release.tarball);

    // Update release.json for the top-level package
    const config = loadConfig('release.json');
    if (!config.dependencies) config.dependencies = {};
    config.dependencies[packageName] = "^"+release.version;

    if(saveRelease)
        saveConfig('release.json', config);
}

async function installFromLockfile(lockfile) {
    for (const [key, packageInfo] of Object.entries(lockfile.packages)) {
        const [packageName, version] = key.split('@');
        await downloadAndInstall(packageName, version, packageInfo.resolved);
    }
}

async function downloadAndInstall(packageName, version, url) {
    const installDir = path.join(os.homedir(), '.evmpack', 'packages', `${packageName}-${version}`);
    if (fs.existsSync(installDir)) {
        console.log(`Already installed: ${packageName}@${version}`);
        return;
    }

    console.log(`Downloading ${packageName}@${version} from CID ${url}...`);

    const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'evmpack-download-'));
    const tarballPath = path.join(tempDir, 'package.tgz');

    try {
        await downloadFile(url, 'package.tgz', tempDir);
        console.log(`Extracting ${packageName}@${version}...`);
        await extractTarball(tarballPath, installDir);
        console.log(`Successfully installed ${packageName}@${version} to ${installDir}`);
    } catch (error) {
        console.error(`Failed to install ${packageName}@${version}.`, error);
        throw error; // Re-throw to ensure the process exits with an error
    } finally {
        fs.rmSync(tempDir, { recursive: true, force: true });
    }
}

module.exports = { install };