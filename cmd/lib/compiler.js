
const fs = require('fs');
const { loadConfig } = require('./config');
const { execSync } = require('child_process');
const os = require('os');

const { createSymlink } = require("./utils");

async function compile() {
    try {
        execSync('command -v forge');
    } catch {
        throw new Error('Forge is not installed. Please install Foundry: https://book.getfoundry.sh/getting-started/installation');
    }

    let releaseConfig;
    try {
        releaseConfig = loadConfig('release.json');
    } catch {
        releaseConfig = {
            compiler: {
                via_ir: true,
                evm_version: "prague",
                optimizer: {
                    enabled: true,
                    runs: 200
                },
                no_metadata: true,
                solc_version: "0.8.30",
                output_dir: "./artifacts",
                context_dir: "./"
            }
        };
        fs.writeFileSync('release.json', JSON.stringify(releaseConfig, null, 2));
    }

    if (!releaseConfig.compiler) {
        releaseConfig.compiler = {
            via_ir: true,
            evm_version: "prague",
            optimizer: {
                enabled: true,
                runs: 200
            },
            no_metadata: true,
            solc_version: "0.8.28",
            output_dir: "./artifacts",
            context_dir: "./"
        };
        fs.writeFileSync('release.json', JSON.stringify(releaseConfig, null, 2));
    }

    const compilerSettings = releaseConfig.compiler;

    const command = [
        'forge build',
        compilerSettings.via_ir ? '--via-ir' : '',
        `--evm-version ${compilerSettings.evm_version}`,
        compilerSettings.optimizer.enabled ? '--optimize' : '',
        `--optimizer-runs ${compilerSettings.optimizer.runs}`,
        compilerSettings.no_metadata ? '--no-metadata' : '',
        `--use ${compilerSettings.solc_version}`,
        `-C ${compilerSettings.context_dir}`,
        `-o ${compilerSettings.output_dir}`,
        `--root ./`,
        `--skip node_modules/*`,
        `-q`,
        `--remappings  @evmpack=${os.homedir()}/.evmpack/packages`
    ].join(' ');

    

    try {
        console.log(`Executing: ${command}`);
        execSync('rm -f @evmpack')
        execSync(command, { stdio: 'inherit' });
                  
        await createSymlink(process.env.EVM_PACK_DIR+'/packages', './@evmpack');

        console.log('Compilation finished successfully.');
    } catch {
        console.error('Compilation failed');
        throw new Error('Compilation failed');
    }
}

module.exports = {
    compile
};