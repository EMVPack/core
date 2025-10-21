#!/usr/bin/env node

process.env.EVM_PACK_ADDRESS = process.env.EVM_PACK_ADDRESS || "0x4fCD571Dbc9C7f8b235182B704665Ffd9dAC6289"; // op-sepolia
process.env.EVM_PACK_PROXY_FACTORY_ADDRESS = process.env.EVM_PACK_PROXY_FACTORY_ADDRESS || "0x0D24c50dbA70179d55C553c1420D9E619Ff2F726"
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
const { addKey, listKeys, selectKey, getSelectedKey } = require("./lib/auth");
const { upgrade } = require("./lib/upgrade");
const { addRelease } = require("./lib/release");
const { info, listPackages } = require("./lib/info");
const { initFromNPM } = require("./lib/init-from-npm");
const { link } = require("./lib/link");
const { use } = require("./lib/use");
const { selectNetwork, getSelectedNetwork } = require("./lib/networks");
const { createHiddenDirInHome } = require("./lib/utils");
const { execSync } = require('child_process');
const chalk = require('chalk');
const boxen = require('boxen');
const { version } = require('../package.json');


createHiddenDirInHome(process.env.EVM_PACK_DIR+"/packages")

showStatus()

yargs(hideBin(process.argv))
    .scriptName('evmpack')
    .command('generate-release-note', "Use gemini for generate release_note.md", () => {}, async function(){
        console.log("Gemini auto generate release_note.md")
        const output = execSync(`gemini -y -p \"Create or add if exist to ./release_note.md based on all of files in current directory, if you see natspec comment, create from them documentation\"`)
        console.log("Gemini answer", output.toString())

    })
    .command('register', 'Register a new package', () => { }, register)
    .command('release', 'Create a new release for a package', () => { }, addRelease)
    .command('init', 'Initialize a new evmpack.json file', async () => {}, init)
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
    .command('auth', 'Manage authentication', (yargs) => {
        yargs
            .command('add', 'Add or import a new key', () => {}, addKey)
            .command('accounts', 'List all added accounts', () => {}, listKeys)
            .command('select-account', 'Select an active account', () => {}, selectKey)
            .demandCommand(1, 'You must specify a subcommand for auth.')
    })
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
    .command('use [package]', 'Use a package to create a proxy', (yargs) => {
        yargs.positional('package', {
            describe: 'Package to use (e.g., my-package@1.0.0)',
            type: 'string'
        })
    }, (argv) => use(argv.package))
    .command('select-network', 'Select a network to work with', () => { }, selectNetwork)
    .demandCommand(1, 'You need at least one command before moving on')
    .help()
    .argv;


function showStatus(){

    const selectedNetwork = getSelectedNetwork();
    const selectedKey = getSelectedKey();

    let boxContent = `${chalk.blue.bold(`EVMPack CLI v${version}`)}\n\n`;
    boxContent += `${chalk.green('Selected network:')} ${selectedNetwork.name}`;
    if (selectedKey) {
        boxContent += `\n${chalk.green('Selected key:')} ${selectedKey.name} (${selectedKey.address})`;
    } else {
        boxContent += `\n${chalk.yellow('No key selected. Use \'evmpack auth select-key\' to select one.')}`;
    }

    console.log(boxen(boxContent, { padding: 1, margin: 1, borderStyle: 'round', borderColor: 'green' }));
}

