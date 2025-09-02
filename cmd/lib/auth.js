
const fs = require('fs');
const path = require('path');
const os = require('os');
const inquirer = require('inquirer');
const crypto = require('crypto');

async function auth() {
    const answers = await inquirer.default.prompt([
        {
            type: 'input',
            name: 'privateKey',
            message: 'Enter your Ethereum private key:'
        },
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

    if (answers.password !== answers.confirmPassword) {
        console.error('Passwords do not match.');
        return;
    }

    const algorithm = 'aes-256-cbc';
    const salt = crypto.randomBytes(16).toString('hex');
    const key = crypto.scryptSync(answers.password, salt, 32);
    const iv = crypto.randomBytes(16);

    const cipher = crypto.createCipheriv(algorithm, key, iv);
    let encrypted = cipher.update(answers.privateKey, 'utf8', 'hex');
    encrypted += cipher.final('hex');

    const authDir = path.join(os.homedir(), '.evmpack');
    if (!fs.existsSync(authDir)) {
        fs.mkdirSync(authDir);
    }

    const authData = {
        iv: iv.toString('hex'),
        salt: salt,
        encryptedData: encrypted
    };

    fs.writeFileSync(path.join(authDir, 'auth_key'), JSON.stringify(authData));

    console.log('Private key encrypted and saved successfully.');
}

module.exports = {
    auth
};