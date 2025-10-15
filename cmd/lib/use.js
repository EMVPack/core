const { ethers } = require('ethers');
const { getEVMPack, getEVMPackProxyFactory} = require('./deployment');
const {accountSelection} = require("./ui")
const inquirer = require('inquirer');

async function use(packageNameAndVersion) {
    if (!packageNameAndVersion) {
        console.error('Error: Package name and version are required. e.g., my-package@1.0.0');
        return;
    }

    const [packageName, version] = packageNameAndVersion.split('@');

    if (!packageName || !version) {
        console.error('Error: Invalid package format. Please use packageName@version.');
        return;
    }

    console.log(`Using package: ${packageName} version: ${version}`);

    const deployer = await accountSelection();
    const evmpack = await getEVMPack(deployer);
    const factory = await getEVMPackProxyFactory(deployer);

    try {
        const release = await evmpack.getPackageRelease(packageName, version);

        if (release[1].target == ethers.ZeroAddress ) {
            console.error(`Error: Package '${packageName}' is not an implementation and cannot be used to create a proxy.`);
            return;
        }

        const answers = await inquirer.default.prompt([
            {
                type: 'input',
                name: 'proxyAdmin',
                message: 'Enter EVMPack ProxyAdmin address (optional):',
                default: '',
            },
            {
                type: 'input',
                name: 'initData',
                message: `Enter initialization data with comma separator ${release[1].selector}:`,
                default: '0x',
            },
            {
                type: 'input',
                name: 'salt',
                message: 'Enter a salt for CREATE2 (optional):',
                default: '',
            },
        ]);

        
        let owner = deployer.address;

        if(answers.proxyAdmin){
            owner = answers.proxyAdmin;
        }

        
        const contractInterface = new ethers.Interface([
            `function ${release[1].selector}`
        ]);

        const initData = contractInterface.encodeFunctionData(release[1].selector.split("(")[0], answers.initData.split(","));

        const tx = await factory.usePackageRelease(packageName, version, owner, initData, answers.salt);
        const receipt = await tx.wait();
        const proxyCreated = receipt.events.find(e => e.event === 'ProxyCreated').args;

        console.log(`Proxy for ${packageName}@${version} deployed at: ${proxyCreated.proxy} with admin ${proxyCreated.proxy_admin} `);

    } catch (error) {
            if (error.data) {
                console.log(error)
                //console.error(factory.interface.parseError(error.data));
            } else if (error.error?.data?.data) {
                console.error('❌ Registration failed error:', factory.interface.parseError(error.error.data.data));
            } else {
                console.error("Error", error)
            }
    }
}

module.exports = { use };
