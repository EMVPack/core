#!/usr/bin/env node

process.env.EVM_PACK_ADDRESS = process.env.EVM_PACK_ADDRESS || "0x4fCD571Dbc9C7f8b235182B704665Ffd9dAC6289"; // op-sepolia
process.env.EVM_PACK_PROXY_FACTORY_ADDRESS = process.env.EVM_PACK_PROXY_FACTORY_ADDRESS || "0x4f6a8b02E9bB71669AFBb415532c450F980C8f7F"
process.env.EVM_PACK_NETWORK = process.env.EVM_PACK_NETWORK || process.env.EVM_PACK_NETWORK || "https://sepolia.optimism.io"
process.env.STORAGE_API_KEY = process.env.STORAGE_API_KEY || "20C291cBB2eF8D6D6c344fd59c1D0B458a083a6A";
process.env.STORAGE_ENDPOINT = process.env.STORAGE_ENDPOINT || "https://storage.evmpack.tech"
process.env.EVM_PACK_DIR = process.env.EVM_PACK_DIR || require('os').homedir()+"/.evmpack";
process.env.EVM_PACK_DEV = process.env.EVM_PACK_DEV || true;

const yargs = require('yargs/yargs');
const { hideBin } = require('yargs/helpers');
const { init } = require("./lib/init");
const { register } = require("./lib/register");
const { install } = require("./lib/install");
const { compile } = require("./lib/compiler");
const { auth } = require("./lib/auth");
const { upgrade } = require("./lib/upgrade");
const { addRelease } = require("./lib/release");
const { info, listPackages } = require("./lib/info");
const { initFromNPM } = require("./lib/init-from-npm");
const { link } = require("./lib/link");
const { createHiddenDirInHome, createSymlink } = require("./lib/utils");
const { execSync } = require('child_process');
const fs = require('fs');

createHiddenDirInHome(process.env.EVM_PACK_DIR+"/packages")

yargs(hideBin(process.argv))
    .scriptName('evmpack')
    .command("enable-node-support", "If you use node js , for support import use this command, they create symlink in node_modules/@evmpack to homedir/.evmpack/packages", () => {}, async function(){
        
        if(!fs.existsSync(process.cwd()+"/node_modules")){
            fs.mkdirSync(process.cwd()+"/node_modules");
        }
          
        await createSymlink(process.env.EVM_PACK_DIR+'/packages', './node_modules/@evmpack');
    })
    .command("enable-foundry-support", "If you use node js , for support import use this command, they create symlink in node_modules/@evmpack to homedir/.evmpack/packages", () => {}, async function(){
        
        if(!fs.existsSync(process.cwd()+"/node_modules")){
            fs.mkdirSync(process.cwd()+"/node_modules");
        }
          
        await createSymlink(process.env.EVM_PACK_DIR+'/packages', './@evmpack');
    })    
    .command('generate-release-note', "Use gemini for generate release_note.md", () => {}, async function(){
        console.log("Gemini auto generate release_note.md")
        const output = execSync(`gemini -y -p \"Create or add if exist to ./release_note.md based on all of files in current directory, if you see natspec comment, create from them documentation\"`)
        console.log("Gemini answer", output.toString())

    })
    .command('status', 'Info about connection', () =>{}, async function() {
        console.log(`EVMPack: ${process.env.EVM_PACK_ADDRESS}`)
        console.log(`EVMPack network: ${process.env.EVM_PACK_NETWORK}`)
        console.log(`IPFS storage api key: ${process.env.STORAGE_API_KEY}`)
        console.log(`IPFS storage endpoint : ${process.env.STORAGE_ENDPOINT}`)
    })
    .command('register', 'Register a new package', () => { }, register)
    .command('release', 'Create a new release for a package', () => { }, addRelease)
    .command('init', 'Initialize a new evmpack.json file', () => { }, init)
    .command('install [package]', 'Install a package', (yargs) => {
        yargs.positional('package', {
            describe: 'Package to install (e.g., packageName:version)',
            type: 'string',
        });
    }, (argv) => {
        if (argv.package) {
            const [packageName, version] = argv.package.split(':');
            install(packageName, version);
        } else {
            install();
        }
    })
    .command('auth', 'Authenticate with the registry', () => { }, auth)
    .command('compile', 'Compile contracts', () => { }, compile)
    .command('upgrade [package]', 'Upgrade a package', (yargs) => {
        yargs.positional('package', {
            describe: 'Package to upgrade',
            type: 'string',
        });
    }, (argv) => upgrade(argv.package))
    .command('info [package]', 'Get information about a package', (yargs) => {
        yargs.positional('package', {
            describe: 'Package to get info about',
            type: 'string',
        });
    }, (argv) => info(argv.package))
    .command('list', 'List all available packages', () => { }, listPackages)
    .command('link', 'Link local packages', () => { }, link)
    .command('init-from-npm [package]', 'Initialize from an NPM package', (yargs) => {
        yargs.positional('package', {
            describe: 'NPM package to initialize from',
            type: 'string'
        })
    }, (argv) => initFromNPM(argv.package))
    .demandCommand(1, 'You need at least one command before moving on')
    .help()
    .argv;
