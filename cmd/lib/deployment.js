const ethers = require('ethers');
const fs = require('fs');
const path = require('path');

async function getEVMPack(signer) {
    const projectRoot = path.resolve(__dirname, '..');
    const evmpackArtifactPath = path.join(projectRoot, 'artifacts', 'EVMPack.sol', 'EVMPack.json');
    const artifacts = JSON.parse(fs.readFileSync(evmpackArtifactPath, 'utf8'));
    return new ethers.Contract(process.env.EVM_PACK_ADDRESS, artifacts.abi, signer);
}

module.exports = { getEVMPack };