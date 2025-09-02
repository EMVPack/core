const { getEVMPack } = require("./deployment");
const { getProvider } = require("./ui");
const ipfs = require("./ipfs");


async function info(name) {
    const provider = await getProvider();
    const evmpack = await getEVMPack(provider);
    
    try {
        const [pkg, versions, maintainers] = await evmpack.getPackageInfo(name);

        const metaCid = pkg.meta;
        const metaDataBuffer = await ipfs.downloadFileContent(metaCid);
        const metaData = JSON.parse(metaDataBuffer.toString());

        console.log(`Package: ${metaData.name}`);
        console.log(`Title: ${metaData.title}`);
        console.log(`Description: ${metaData.description}`);
        console.log(`Author: ${metaData.author}`);
        console.log(`License: ${metaData.license}`);
        console.log(`Type: ${metaData.type}`);
        
        console.log("\nMaintainers:");
        for (const maintainer of maintainers) {
            console.log(`  Address: ${maintainer}`);
        }
        console.log("\nReleases:");

        for (const version of versions) {
            console.log(`  Version: ${version}`);
        }

    } catch (error) {
        if (error.data) {
            const decodedError = evmpack.interface.parseError(error.data);
            console.error(`Error: ${decodedError.name}`);
        } else {
            console.error('Error fetching package info:', error);
        }
    }
}

module.exports = { info };
