const { loadConfig, validateConfig } = require('./config');
const { compile } = require('./compiler');
const { createTarball } = require('./tar');
const { uploadFile } = require('./ipfs');
const { getEVMPack } = require('./deployment');
const { findFile, convertDeps } = require('./utils');
const inquirer = require('inquirer');
const fs = require('fs');
const path = require('path');
const { ethers } = require('ethers');
const { execSync } = require('child_process');
const { implTypes } = require("./init");
const { accountSelection } = require("./ui");
const { verify } = require('crypto');

async function prepareRelease(deployer, external_implementation_address, evmpackConfig, releaseConfig){
    
    console.log('Compiling contracts...');
    await compile();

    let release_note;
    let release_note_path = process.cwd() + "/release_note.md";

    if(!fs.existsSync(release_note_path)){

        try {
            console.log("Gemini auto generate release_note.md")
            const output = execSync(`gemini -y -p "Create release_note.md based on all of files in current directory, if you see natspec comment, create from them documentation"`)
            console.log("Gemini answer", output.toString())
            release_note = fs.readFileSync(release_note_path, 'utf8');
        } catch {
            
            const answers = await inquirer.default.prompt([
                {
                    type: 'editor',
                    name: 'release_note',
                    message: 'Enter your release note:',
                    validate: function(input){ 

                        if(input.length < 150){
                            return "Input should me more than 150 chars";
                        }else{
                            return true;
                        }
                    }
                }
            ]);

            release_note = answers.release_note
        }

    }else{
        const answers = await inquirer.default.prompt([
            {
                type: 'editor',
                name: 'release_note',
                message: 'Edit your release note:',
                default: fs.readFileSync(release_note_path, 'utf8'),
                validate: function(input){ 

                    if(input.length < 150){
                        return "Input should me more than 150 chars";
                    }else{
                        return true;
                    }
                }
            }
        ]);

        release_note = answers.release_note
    }

    fs.writeFileSync(release_note_path, release_note);

    const releaseNoteCid = await uploadFile(process.cwd() + "/release_note.md");
    const tarballPath = await createTarball(evmpackConfig.name, releaseConfig.version);
    const tarballCid = await uploadFile(tarballPath);


    let implementation = false;
    let abiCid = "";
    let sourceCid = "";

    if (evmpackConfig.type === 'implementation') {
        
        let implementationAddress;
        const artifactPath = path.join(process.cwd(), 'artifacts', releaseConfig.main_contract + '.sol', releaseConfig.main_contract + '.json');
        const artifact = JSON.parse(fs.readFileSync(artifactPath, 'utf8'));
        abiCid = await uploadFile(Buffer.from(JSON.stringify(artifact.abi)));
        sourceCid = await uploadFile(findFile(process.cwd(),releaseConfig.main_contract+".sol"));

        if (external_implementation_address) {
            const answers = await inquirer.default.prompt([
                {
                    type: 'input',
                    name: 'implementationAddress',
                    message: 'Enter the address of the deployed implementation contract:',
                }
            ]);
            implementationAddress = answers.implementationAddress;
        }else{
            const factory = new ethers.ContractFactory(artifact.abi, artifact.bytecode, deployer);
            const deployedImplementation = await factory.deploy()
            const implementation  = await deployedImplementation.waitForDeployment()
            implementationAddress = implementation.target;
        }

        implementation = {
            implementation_type: implTypes.indexOf(releaseConfig.implementation_type),
            target: implementationAddress,
            selector: releaseConfig.selector
        };

    }


    const manifest = {
        dependencies: convertDeps(releaseConfig.dependencies), 
        note: releaseNoteCid,
        tarball: tarballCid,
        source: sourceCid,
        abi: abiCid,
    }

    

    const manifestCid = await uploadFile(Buffer.from(JSON.stringify(manifest)))

    return {
        version: releaseConfig.version,
        manifest:manifestCid,
        implementation
    }
}


async function addRelease(external_implementation_address = false) {
    const deployer = await accountSelection();
    // 5. Get EVMPack contract instance
    const evmPack = await getEVMPack(deployer);

    try {
        // 1. Get package and release config
        const packageConfig = loadConfig('evmpack.json');
        const releaseConfig = loadConfig('release.json');

        const errors = validateConfig(packageConfig, releaseConfig);

        if (errors.length > 0) {
            throw new Error(`Configuration errors: \n - ${errors.join('\n - ')}`);
        }

  
        const release = await prepareRelease(deployer,external_implementation_address, packageConfig, releaseConfig)
        

        let tx;

        if(release.implementation){
            tx = await evmPack.addRelease(
                packageConfig.name, 
                {
                    version: release.version,
                    manifest: release.manifest
                },
                release.implementation
            );
        }else{
            tx = await evmPack.addRelease(
                packageConfig.name, 
                {
                    version: release.version,
                    manifest: release.manifest
                }
            );
        }

        await tx.wait();

        console.log(`Successfully added release ${release.version} for package ${packageConfig.name}`);
        console.log(`Transaction hash: ${tx.hash}`);
    } catch (error) {
        console.error('❌ Registration failed:');
        if (error.data) {
            const decodedError = evmPack.interface.parseError(error.data);
            console.error(decodedError);
        }else{
            console.error(error);
            throw error;
        }

    }
}

module.exports = { addRelease, prepareRelease };
