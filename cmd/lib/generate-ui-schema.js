const fs = require('fs');
const path = require('path');
const { ethers } = require('ethers');
const { loadConfig } = require('./config');

function generateUiSchema() {
    let releaseConfig;
    try {
        // release.json is the source of truth for the main contract, as used by the release command.
        releaseConfig = loadConfig('release.json');
    } catch (e) {
        console.error('Error: Could not load release.json. Please run this command from your package root.');
        process.exit(1);
    }

    const mainContract = releaseConfig.main_contract;
    if (!mainContract) {
        console.error('Error: `main_contract` not found in release.json.');
        process.exit(1);
    }

    // This logic mimics the path resolution from other parts of the CLI (e.g., release.js)
    // to provide a consistent, zero-config experience.
    let artifactPath;
    const hardhatArtifactPath = path.join(process.cwd(), 'artifacts', 'contracts', mainContract + '.sol', mainContract + '.json');
    const foundryArtifactPath = path.join(process.cwd(), 'out', mainContract + '.sol', mainContract + '.json');

    if (fs.existsSync(hardhatArtifactPath)) {
        artifactPath = hardhatArtifactPath;
    } else if (fs.existsSync(foundryArtifactPath)) {
        artifactPath = foundryArtifactPath;
    } else {
        console.error(`Error: Could not find artifact for "${mainContract}".`);
        console.error('Looked in:');
        console.error(`- ${hardhatArtifactPath} (for Hardhat)`);
        console.error(`- ${foundryArtifactPath} (for Foundry)`);
        console.error('Please ensure your contracts are compiled.');
        process.exit(1);
    }
    
    console.log(`Found artifact at: ${artifactPath}`);

    const artifact = JSON.parse(fs.readFileSync(artifactPath, 'utf8'));
    const { abi, contractName } = artifact;

    if (!abi) {
        console.error('Error: ABI not found in the artifact file.');
        process.exit(1);
    }

    const iface = new ethers.Interface(abi);
    const functions = [];

    iface.forEachFunction(func => {
        // We only care about non-view functions for the UI schema for interaction
        if (func.stateMutability === 'view' || func.stateMutability === 'pure') {
            return;
        }

        const functionEntry = {
            name: func.name,
            stateMutability: func.stateMutability,
            payable: func.payable,
            description: `TODO: Describe the purpose of the ${func.name} function.`,
            questions: []
        };

        func.inputs.forEach(input => {
            const question = {
                name: input.name || input.type, // Use type as fallback name
                message: `Enter value for '${input.name || input.type}' (type: ${input.type}):`,
                type: 'input', 
            };

            if (input.type.startsWith('uint') || input.type.startsWith('int')) {
                question.validate = 'number';
            } else if (input.type === 'bool') {
                question.type = 'confirm';
            } else if (input.type === 'address') {
                question.validate = 'address';
            }

            if (input.type.includes('tuple')) {
                question.message += " (as a JSON string)";
                question.type = 'editor';
                question.description = "TODO: For a better UX, consider splitting this tuple into multiple questions."
            }

            functionEntry.questions.push(question);
        });

        if (func.payable) {
            functionEntry.questions.push({
                name: '_value',
                message: 'Enter the amount of ETH to send with the transaction:',
                type: 'input',
                validate: 'number'
            });
        }

        functions.push(functionEntry);
    });

    const uiSchema = {
        contractName,
        generatedAt: new Date().toISOString(),
        schemaVersion: '1.0.0',
        functions
    };

    const outputFileName = 'ui-schema.json';
    const outputPath = path.resolve(process.cwd(), outputFileName);
    fs.writeFileSync(outputPath, JSON.stringify(uiSchema, null, 2));

    console.log(`Successfully generated UI schema for ${contractName}.`);
    console.log(`File saved to: ${outputPath}`);
}

module.exports = { generateUiSchema };