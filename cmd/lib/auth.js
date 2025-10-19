const fs = require('fs');
const path = require('path');
const inquirer = require('inquirer');
const { Wallet, ethers } = require('ethers');
const crypto = require('crypto');
const { getProvider } = require('./networks');

const keysFilePath = path.join(process.env.EVM_PACK_DIR, 'keys.json');

function getKeys() {
    if (fs.existsSync(keysFilePath)) {
        const keysData = fs.readFileSync(keysFilePath, 'utf8');
        return JSON.parse(keysData);
    } else {
        return {};
    }
}

function saveKeys(keys) {
    fs.writeFileSync(keysFilePath, JSON.stringify(keys, null, 2));
}

async function addKey() {
    const { action } = await inquirer.default.prompt([
        {
            type: 'list',
            name: 'action',
            message: 'What do you want to do?',
            choices: [
                { name: 'Add a new key', value: 'add' },
                { name: 'Import an existing key', value: 'import' },
            ],
        },
    ]);

    let privateKey;
    const { keyName } = await inquirer.default.prompt([
        {
            type: 'input',
            name: 'keyName',
            message: 'Enter a name for the key:',
        },
    ]);

    if (action === 'add') {
        const wallet = Wallet.createRandom();
        privateKey = wallet.privateKey;
        console.log(`Generated new private key for '${keyName}'.`);
    } else if (action === 'import') {
        const answers = await inquirer.default.prompt([
            {
                type: 'password',
                name: 'privateKey',
                message: 'Enter the private key:',
            },
        ]);
        privateKey = answers.privateKey;
    }

    const { password, confirmPassword } = await inquirer.default.prompt([
        {
            type: 'password',
            name: 'password',
            message: 'Enter a password to encrypt your private key:'
        },
        {
            type: 'password',
            name: 'confirmPassword',
            message: 'Confirm your password:'
        }
    ]);

    if (password !== confirmPassword) {
        console.error('Passwords do not match.');
        return;
    }

    const wallet = new Wallet(privateKey);
    const address = wallet.address;

    const algorithm = 'aes-256-cbc';
    const salt = crypto.randomBytes(16).toString('hex');
    const key = crypto.scryptSync(password, salt, 32);
    const iv = crypto.randomBytes(16);

    const cipher = crypto.createCipheriv(algorithm, key, iv);
    let encrypted = cipher.update(privateKey, 'utf8', 'hex');
    encrypted += cipher.final('hex');

    const keys = getKeys();
    keys[keyName] = {
        address: address,
        iv: iv.toString('hex'),
        salt: salt,
        encryptedData: encrypted
    };

    saveKeys(keys);

    console.log(`Key '${keyName}' encrypted and saved successfully.`);
}

function getDecryptedKey(keyName, password) {
    const keys = getKeys();
    const encryptedKey = keys[keyName];

    if (!encryptedKey) {
        throw new Error(`Key '${keyName}' not found.`);
    }

    const algorithm = 'aes-256-cbc';
    const key = crypto.scryptSync(password, encryptedKey.salt, 32);
    const decipher = crypto.createDecipheriv(algorithm, key, Buffer.from(encryptedKey.iv, 'hex'));

    let decrypted = decipher.update(encryptedKey.encryptedData, 'hex', 'utf8');
    decrypted += decipher.final('utf8');

    return decrypted;
}

function listKeys() {
    const keys = getKeys();
    console.log('Saved keys:');
    for (const keyName in keys) {
        console.log(`  - ${keyName}: ${keys[keyName].address}`);
    }
}

async function selectKey() {
    const keys = getKeys();
    const keyNames = Object.keys(keys);

    if (keyNames.length === 0) {
        console.log('No keys found. Please add a key first using \'evmpack auth add\'.');
        return;
    }

    const { selectedKeyName } = await inquirer.default.prompt([
        {
            type: 'list',
            name: 'selectedKeyName',
            message: 'Select a key to make it active:',
            choices: keyNames,
        },
    ]);

    const selectedKeyPath = path.join(process.env.EVM_PACK_DIR, 'selected_key');
    fs.writeFileSync(selectedKeyPath, selectedKeyName);

    console.log(`Key '${selectedKeyName}' is now the active key.`);
}

function getSelectedKey() {
    const selectedKeyPath = path.join(process.env.EVM_PACK_DIR, 'selected_key');
    let selectedKeyName;

    if (fs.existsSync(selectedKeyPath)) {
        selectedKeyName = fs.readFileSync(selectedKeyPath, 'utf8');
    } else {
        const keys = getKeys();
        const keyNames = Object.keys(keys);
        if (keyNames.length > 0) {
            selectedKeyName = keyNames[0];
            fs.writeFileSync(selectedKeyPath, selectedKeyName);
        } else {
            return null;
        }
    }

    const keys = getKeys();
    return { name: selectedKeyName, ...keys[selectedKeyName] };
}

module.exports = { addKey, getKeys, getDecryptedKey, listKeys, selectKey, getSelectedKey, accountSelection };

async function accountSelection() {
    const selectedKey = getSelectedKey();

    if (!selectedKey) {
        throw new Error('No key selected. Please run `evmpack auth select-key` first.');
    }

    const { password } = await inquirer.default.prompt([
        {
            type: 'password',
            name: 'password',
            message: `Enter password for key '${selectedKey.name}':`
        }
    ]);

    const decrypted = getDecryptedKey(selectedKey.name, password);

    const provider = await getProvider();
    const wallet = new ethers.Wallet(decrypted, provider);

    return wallet;
}