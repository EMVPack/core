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
            const releaseInfo = await evmpack.getPackageRelease(name, version)
            console.log(`  Version: ${version}`);
            console.log(`  Implementation target: ${releaseInfo[1].target}`, )
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

async function listPackages() {

    if(process.env.EVM_PACK_DEV){
        console.info("EVMPack run on testnet dev mode, he work without archive node, this means that you may not see all the packages\n")
    }
    const provider = await getProvider();
    const evmpack = await getEVMPack(provider);

    const filter = evmpack.filters.RegisterPackage();
    const events = await evmpack.queryFilter(filter, -9999);

    // TODO: move to graphql
    
    for (const event of events) {
        console.log(`- ${event.args.name}`)
    }


}

module.exports = { info, listPackages };
