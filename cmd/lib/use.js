const { ethers } = require('ethers');
const { getEVMPack, getEVMPackProxyFactory} = require('./deployment');
const {accountSelection} = require("./auth")
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

        const genericAnswers = await inquirer.default.prompt([
            {
                type: 'input',
                name: 'proxyAdmin',
                message: 'Enter EVMPack ProxyAdmin address (optional):',
                default: '',
            },
            {
                type: 'input',
                name: 'salt',
                message: 'Enter a salt for CREATE2 (optional):',
                default: '',
            },
        ]);

        let owner = deployer.address;
        if (genericAnswers.proxyAdmin) {
            owner = genericAnswers.proxyAdmin;
        }

        let initData = '0x';
        // Check if an initializer function exists
        if (release[1].selector && release[1].selector.includes('(')) {
            const contractInterface = new ethers.Interface([`function ${release[1].selector}`]);
            const functionFragment = contractInterface.getFunction(release[1].selector.split('(')[0]);

            if (functionFragment.inputs.length > 0) {
                const argQuestions = functionFragment.inputs.map(param => ({
                    type: 'input',
                    name: param.name,
                    message: `Enter value for '${param.name}' (type: ${param.type}):`
                }));

                console.log(`Please provide arguments for the initializer function: ${release[1].selector}`);
                const argAnswers = await inquirer.default.prompt(argQuestions);
                
                const orderedArgs = functionFragment.inputs.map(param => argAnswers[param.name]);
                initData = contractInterface.encodeFunctionData(functionFragment, orderedArgs);
            }
        }
        
        const tx = await factory.usePackageRelease(packageName, version, owner, initData, genericAnswers.salt);
        const receipt = await tx.wait();

        // Find and parse the correct log manually for ethers v6
        let proxyCreated = null;
        for (const log of receipt.logs) {
            try {
                const parsedLog = factory.interface.parseLog(log);
                if (parsedLog && parsedLog.name === 'ProxyCreated') {
                    proxyCreated = parsedLog.args;
                    break; // Found it, exit loop
                }
            } catch (error) {
                // Ignore logs that don't match our interface
            }
        }

        if (!proxyCreated) {
            console.error("Error: Could not find 'ProxyCreated' event in the transaction receipt.");
            return;
        }

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
