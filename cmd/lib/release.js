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
const { accountSelection } = require("./auth");

const { createSymlink } = require("./utils");

async function prepareRelease(deployer, external_implementation_address, evmpackConfig, releaseConfig){
    
    await compile();
    execSync('rm -f @evmpack')

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
        
        let root = './';
    
        if(fs.existsSync('foundry.lock')){
            root = "./src"
        }
    
        if(fs.existsSync('hardhat.config.js') || fs.existsSync('hardhat.config.ts') ){
            root = "./contracts"
        }


        let implementationAddress;
        const artifactPath = path.join(process.cwd(), root , 'artifacts', releaseConfig.main_contract + '.sol', releaseConfig.main_contract + '.json');
        const artifact = JSON.parse(fs.readFileSync(artifactPath, 'utf8'));
        abiCid = await uploadFile(Buffer.from(JSON.stringify(artifact.abi)));
        sourceCid = await uploadFile(findFile(process.cwd(),releaseConfig.main_contract+".sol"));

        if (external_implementation_address) {
            const answers = await inquirer.default.prompt([
                {
                    type: 'input',
                    name: 'implementationAddress',
                    message: 'Enter the address of the deployed implementation contract (empty for deploy now):',
                }
            ]);

            implementationAddress = answers.implementationAddress;

            if(!implementationAddress){
                const factory = new ethers.ContractFactory(artifact.abi, artifact.bytecode, deployer);
                const deployedImplementation = await factory.deploy()
                const implementation  = await deployedImplementation.waitForDeployment()
                implementationAddress = implementation.target;
            }

        }else{
            const factory = new ethers.ContractFactory(artifact.abi, artifact.bytecode, deployer);
            const deployedImplementation = await factory.deploy()
            const implementation  = await deployedImplementation.waitForDeployment()
            implementationAddress = implementation.target;
            
        }

        implementation = {
            implementationType: implTypes.indexOf(releaseConfig.implementationType),
            target: implementationAddress,
            selector: releaseConfig.selector
        };

        console.log(`🔗 Implementation deployed: ${implementationAddress}`)
    }


    const manifest = {
        dependencies: convertDeps(releaseConfig.dependencies), 
        note: releaseNoteCid,
        tarball: tarballCid,
        source: sourceCid,
        abi: abiCid,
    }

    

    const manifestCid = await uploadFile(Buffer.from(JSON.stringify(manifest)))
    await createSymlink(process.env.EVM_PACK_DIR+'/packages', './@evmpack');

    return {
        version: releaseConfig.version,
        manifest:manifestCid,
        implementation
    }
}


async function addRelease(external_implementation_address = false) {
    const deployer = await accountSelection();
    
    const evmPack = await getEVMPack(deployer);

    
    try {
        
        const packageConfig = loadConfig('evmpack.json');
        
        const releaseConfig = loadConfig('release.json');
        
        execSync('rm -f @evmpack')
        const errors = validateConfig(packageConfig, releaseConfig);

        if (errors.length > 0) {
            throw new Error(`Configuration errors: \n - ${errors.join('\n - ')}`);
        }

        const release = await prepareRelease(deployer,external_implementation_address, packageConfig, releaseConfig)        

        let tx;

        if(release.implementation){
            console.log("add implementation ver")
            tx = await evmPack['addRelease(string,(string,string),(uint8,address,string))'](
                packageConfig.name,
                {
                    version: release.version,
                    manifest: release.manifest
                },
                release.implementation
            );
        }else{
            console.log("add library ver")
            tx = await evmPack['addRelease(string,(string,string))'](
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
