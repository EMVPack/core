const fs = require('fs');
const path = require('path');
const {findFile} = require("./utils")
const semver = require('semver');

function loadConfig(fileName) {
    const configPath = path.join(process.cwd(), fileName);
    if (!fs.existsSync(configPath)) {
        throw new Error(`${fileName} not found`);
    }
    return JSON.parse(fs.readFileSync(configPath, 'utf8'));
}

function saveConfig(fileName, config) {
    const configPath = path.join(process.cwd(), fileName);

    fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
}

function validateConfig(evmpackConfig, releaseConfig) {
    const errors = [];

    // evmpack.json validation
    if (!evmpackConfig.name) {
        errors.push('name is required in evmpack.json');
    }
    if (!evmpackConfig.type) {
        errors.push('type is required in evmpack.json');
    }
    if (!evmpackConfig.title) {
        errors.push('title is required in evmpack.json');
    }
    if (!evmpackConfig.description) {
        errors.push('description is required in evmpack.json');
    }
    if (!evmpackConfig.author) {
        errors.push('author is required in evmpack.json');
    }

    if(evmpackConfig.type == "implementation"){
        if(!releaseConfig.main_contract){
            errors.push('main_contract is required in release.json');
        }else if(!findFile(process.cwd(),releaseConfig.main_contract+".sol")){
            errors.push(`Cannot find ${releaseConfig.main_contract}.sol`);
        }

        if(!releaseConfig.implementationType){
            errors.push('implementationType is required in release.json');
        }

        if(!releaseConfig.selector){
            errors.push('selector is required in release.json');
        }
    }

    // release.json validation
    if (!releaseConfig.version) {
        errors.push('version is required in release.json');
    } else {
        if (!semver.valid(releaseConfig.version)) {
            errors.push('Invalid version format');
        }
    }

    

    return errors;
}

module.exports = {
    loadConfig,
    saveConfig,
    validateConfig
};