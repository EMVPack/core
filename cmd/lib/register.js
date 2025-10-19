const { getEVMPack } = require("./deployment");
const {
    loadConfig,
    validateConfig
} = require("./config");
const { uploadFile } = require("./ipfs");
const { accountSelection } = require("./auth");
const { prepareRelease } = require("./release")
const { packageTypes } = require("../lib/init")
const { execSync } = require('child_process');
const { createSymlink } = require("./utils");


async function prepareAdd(deployer, external_implementation_address = false) {

    const evmpackConfig = loadConfig('evmpack.json');
    const releaseConfig = loadConfig('release.json');

    const errors = validateConfig(evmpackConfig, releaseConfig);

    if (errors.length > 0) {
        throw new Error(`Configuration errors: \n - ${errors.join('\n - ')}`);
    }
    const release = await prepareRelease(deployer, external_implementation_address, evmpackConfig, releaseConfig);

    const metaCid = await uploadFile(process.cwd() + "/evmpack.json");

    const add = {
        name: evmpackConfig.name,
        meta: metaCid,
        packageType: packageTypes.indexOf(evmpackConfig.type),
        release: release
    };

  
    return { add, implementation:release.implementation };
}

async function register(external_implementation_address = false) {
    const deployer = await accountSelection();
    const evmpack = await getEVMPack(deployer);

    
    try {
        console.log('Starting package registration...');
        execSync('rm -f @evmpack')
        const { add, implementation } = await prepareAdd(deployer, external_implementation_address);
        await createSymlink(process.env.EVM_PACK_DIR+'/packages', './@evmpack');

        try {
            const fee = await evmpack.getRegisterFee();
            let tx;

            if (implementation) {
                tx = await evmpack.registerImplementation(add, implementation, { value: fee });
            } else {
                tx = await evmpack.registerLibrary(add, { value: fee });
            }

            console.log(`📝 Registration transaction sent: ${tx.hash}`);
            await tx.wait();
            console.log('✅ Package registered successfully!');

        } catch (error) {
            if (error.data) {
                console.error(evmpack.interface.parseError(error.data));
            } else if (error.error?.data?.data) {
                console.error('❌ Registration failed error:', evmpack.interface.parseError(error.error.data.data));
            } else {
                console.error("Error", error)
            }
        }

    } catch (error) {
        console.error('❌ Registration failed:');
        if (error.data) {
            const decodedError = evmpack.interface.parseError(error.data);
            console.error(decodedError);
        }
        console.error(error);
        throw error;
    }
}

module.exports = {
    register
};