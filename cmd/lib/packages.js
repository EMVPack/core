const { getEVMPack } = require("./deployment");
const { getProvider } = require("./ui");

async function getPackage(name) {
    const provider = await getProvider();
    const evmpack = await getEVMPack(provider);

    try {
        const [packageInfo, versionStrings, maintainers] = await evmpack.getPackageInfo(name);
        return { evmpack, packageInfo, versionStrings, maintainers };
    } catch (error) {
        if (error.data) {
            const decodedError = evmpack.interface.parseError(error.data);
            console.error(`Error getting package "${name}": ${decodedError.name}`);
        } else {
            console.error(`Error fetching package info for "${name}":`, error.message);
        }
        return { evmpack: null, packageInfo: null, releases: null };
    }
}

async function getPackageRelease(name, version) {
    const provider = await getProvider();
    const evmpack = await getEVMPack(provider);

    try {
        const [releaseFromState, implementation] = await evmpack.getPackageRelease(name, version);

        const manifestBuffer = await ipfs.downloadFileContent(releaseFromState.manifest);
        const manifest = JSON.parse(manifestBuffer.toString());
        manifest.version = releaseFromState.version;

        return { release: manifest, implementation };
    } catch (error) {
        if (error.data) {
            const decodedError = evmpack.interface.parseError(error.data);
            console.error(`Error getting package release "${name}-${version}": ${decodedError.name}`);
        } else {
            console.error(`Error fetching package release for "${name}-${version}":`, error.message);
        }
        return { release: null, implementation: null };
    }
}

module.exports = { getPackage, getPackageRelease };
