
const inquirer = require("inquirer");
const fs = require('fs');
const path = require('path');
const os = require('os');
const crypto = require('crypto');
const { ethers } = require('ethers');

async function getProvider() {
    return new ethers.JsonRpcProvider(process.env.EVM_PACK_NETWORK);
}

async function accountSelection() {
    const authFile = path.join(os.homedir(), '.evmpack', 'auth_key');
    if (!fs.existsSync(authFile)) {
        throw new Error('No auth key found. Please run `evmpack auth` first.');
    }

    const authData = JSON.parse(fs.readFileSync(authFile, 'utf8'));

    if(!authData.salt){
        authData.salt = "salt"
    }

    const answers = await inquirer.default.prompt([
        {
            type: 'password',
            name: 'password',
            message: 'Enter your password to decrypt your private key:'
        }
    ]);

    const algorithm = 'aes-256-cbc';
    const key = crypto.scryptSync(answers.password, authData.salt, 32);
    const iv = Buffer.from(authData.iv, 'hex');

    const decipher = crypto.createDecipheriv(algorithm, key, iv);
    let decrypted = decipher.update(authData.encryptedData, 'hex', 'utf8');
    decrypted += decipher.final('utf8');

    const provider = await getProvider();
    const wallet = new ethers.Wallet(decrypted, provider);

    return wallet;
}

module.exports = {
    accountSelection,
    getProvider
}