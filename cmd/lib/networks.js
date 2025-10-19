const fs = require('fs');
const path = require('path');
const inquirer = require('inquirer');
const { ethers } = require('ethers');

const networks = {
    opsepolia: {
        endpoints: [{rpc:"https://sepolia.optimism.io"}],
        name: "Optimism Sepolia",
        type: "testnet"
    },
    sepolia: {
        endpoints: [{rpc:"https://1rpc.io/sepolia"}],
        name: "Ethereum Sepolia",
        type: "testnet"
    },
    oasis: {
        endpoints: [{rpc:"https://sapphire.oasis.io"}],
        name: "Oasis",
        type: "mainnet"
    },
    oasistestnet: {
        endpoints: [{rpc:"https://testnet.sapphire.oasis.io"}],
        name: "Oasis testnet",
        type: "testnet"        
    }    
}

const defaultNetwork = "opsepolia";

function getSelectedNetwork() {
    const selectedNetworkPath = path.join(process.env.EVM_PACK_DIR, 'selected_network');
    if (fs.existsSync(selectedNetworkPath)) {
        const selectedNetworkKey = fs.readFileSync(selectedNetworkPath, 'utf8');
        return networks[selectedNetworkKey];
    } else {
        return networks[defaultNetwork];
    }
}

async function selectNetwork() {
    const evmpackDir = process.env.EVM_PACK_DIR;
    if (!fs.existsSync(evmpackDir)) {
        fs.mkdirSync(evmpackDir, { recursive: true });
    }

    const { networkType } = await inquirer.default.prompt([
        {
            type: 'list',
            name: 'networkType',
            message: 'Select network type:',
            choices: ['testnet', 'mainnet'],
        },
    ]);

    const filteredNetworks = Object.entries(networks).filter(
        ([, network]) => network.type === networkType
    );

    const { selectedNetworkKey } = await inquirer.default.prompt([
        {
            type: 'list',
            name: 'selectedNetworkKey',
            message: 'Select network:',
            choices: filteredNetworks.map(([key, network]) => ({
                name: network.name,
                value: key,
            })),
        },
    ]);

    const selectedNetworkPath = path.join(evmpackDir, 'selected_network');
    fs.writeFileSync(selectedNetworkPath, selectedNetworkKey);

    console.log(`Selected network: ${networks[selectedNetworkKey].name}`);
}

module.exports = {defaultNetwork, networks, getSelectedNetwork, selectNetwork, getProvider}

async function getProvider() {
    const selectedNetwork = getSelectedNetwork();
    const endpoint = selectedNetwork.endpoints[0].rpc;
    return new ethers.JsonRpcProvider(endpoint);
}