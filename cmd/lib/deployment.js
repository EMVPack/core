const ethers = require('ethers');
const fs = require('fs');
const path = require('path');

async function getEVMPack(signer) {
    const projectRoot = path.resolve(__dirname, '../..');
    const evmpackArtifactPath = path.join(projectRoot, 'artifacts', 'EVMPack.sol', 'EVMPack.json');
    const artifacts = JSON.parse(fs.readFileSync(evmpackArtifactPath, 'utf8'));
    return new ethers.Contract(process.env.EVM_PACK_ADDRESS, artifacts.abi, signer);
}

async function getEVMPackProxyFactory(signer) {
    const projectRoot = path.resolve(__dirname, '../..');
    const evmpackProxyFactoryArtifactPath = path.join(projectRoot, 'artifacts', 'EVMPackProxyFactory.sol', 'EVMPackProxyFactory.json');
    const artifacts = JSON.parse(fs.readFileSync(evmpackProxyFactoryArtifactPath, 'utf8'));
    return new ethers.Contract(process.env.EVM_PACK_PROXY_FACTORY_ADDRESS, artifacts.abi, signer);
}


async function createEVMPackProxyAdmin(deployer) {
    const projectRoot = path.resolve(__dirname, '../..');
    const evmpackProxyFactoryArtifactPath = path.join(projectRoot, 'artifacts', 'contracts', 'EVMPackProxyAdmin.sol', 'EVMPackProxyAdmin.json');
    const artifacts = JSON.parse(fs.readFileSync(evmpackProxyFactoryArtifactPath, 'utf8'));
    

    const factory = new ethers.ContractFactory(artifacts.abi, artifacts.bytecode, deployer);
    const deployedImplementation = await factory.deploy()
    const implementation  = await deployedImplementation.waitForDeployment()
    return implementation.target;
}


module.exports = { getEVMPack, getEVMPackProxyFactory, createEVMPackProxyAdmin };