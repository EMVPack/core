const fs = require('fs');
const path = require('path');
const https = require('https');
const os = require('os');
const inquirer = require('inquirer');
const { execSync } = require('child_process');


const packageTypes = ['implementation', 'library'];
const implTypes = ['static', 'transparent', 'diamond'];

async function getSolcVersions() {
  const cacheDir = path.join(os.homedir(), '.evmpack', 'cache');
  if (!fs.existsSync(cacheDir)) {
    fs.mkdirSync(cacheDir, { recursive: true });
  }

  const cachePath = path.join(cacheDir, 'solc-versions.json');
  const cacheDuration = 24 * 60 * 60 * 1000; // 24 hours

  if (fs.existsSync(cachePath)) {
    const stats = fs.statSync(cachePath);
    if (new Date().getTime() - stats.mtime.getTime() < cacheDuration) {
      return Object.keys(JSON.parse(fs.readFileSync(cachePath, 'utf8')));
    }
  }

  return new Promise((resolve, reject) => {
    https.get('https://binaries.soliditylang.org/bin/list.json', (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        const versions = JSON.parse(data).releases;
        fs.writeFileSync(cachePath, JSON.stringify(versions));
        resolve(Object.keys(versions));
      });
    }).on('error', (err) => {
      reject(err);
    });
  });
}


async function init() {
  const solcVersions = await getSolcVersions();

  const answers = await inquirer.default.prompt([
    {
      type: 'input',
      name: 'name',
      message: 'Package name:',
      validate: function (value) {
        var pass = value.match(
          /^[a-z0-9@-]+$/i
        );
        if (pass) {
          return true;
        }

        return 'Please enter a valid package name (lowercase, numbers, -, @).';
      }
    },
    {
      type: 'input',
      name: 'title',
      message: 'Title:'
    },
    {
      type: 'input',
      name: 'description',
      message: 'Description:'
    },
    {
      type: 'input',
      name: 'author',
      message: 'Author:'
    },
    {
      type: 'list',
      name: 'type',
      message: 'Package type:',
      choices: packageTypes
    },
    {
      type: 'input',
      name: 'main_contract',
      message: 'Main contract name (without .sol extension):',
      when: (answers) => answers.type === 'implementation'
    },
    {
      type: 'list',
      name: 'implementationType',
      message: 'Implementation type:',
      choices:implTypes,
      when: (answers) => answers.type === 'implementation'
    },        
    {
      type: 'input',
      name: 'selector',
      message: 'Selector:',
      when: (answers) => answers.implementationType === 'transparent'
    },

    {
      type: 'input',
      name: 'license',
      message: 'License:',
      default: 'MIT'
    },
    {
      type: 'list',
      name: 'solidityVersion',
      message: 'Solidity version:',
      choices: solcVersions
    },
    {
      type: 'input',
      name: 'git',
      message: 'Git repository:'
    },
    {
      type: 'input',
      name: 'homepage',
      message: 'Homepage:'
    },
    {
      type: 'input',
      name: 'tags',
      message: 'Tags (comma-separated):'
    }
  ]);

  const evmpackConfig = {
    name: answers.name,
    type: answers.type,
    title: answers.title,
    description: answers.description,
    author: answers.author,
    license: answers.license,
    git: answers.git,
    tags: answers.tags.split(',').map(t => t.trim()),
    homepage: answers.homepage,
  };

  const releaseConfig = {
    version: "1.0.0",
    dependencies: {},
    compiler: {
      via_ir: true,
      evm_version: "prague",
      optimizer: {
          enabled: true,
          runs: 200
      },
      no_metadata: true,
      solc_version: answers.solidityVersion,
      output_dir: "./artifacts",
      cache_dir: "../cache",
      context_dir: "./",
      root:  "./src"
    }
  }

  if (answers.type == "implementation") {
    releaseConfig.main_contract = answers.main_contract;
    releaseConfig.selector = answers.selector;
    releaseConfig.implementationType = answers.implementationType;
  }


  execSync("forge init", { stdio: 'inherit' });

  fs.writeFileSync(
    path.join(process.cwd(), 'evmpack.json'),
    JSON.stringify(evmpackConfig, null, 2)
  );

  fs.writeFileSync(
    path.join(process.cwd(), 'release.json'),
    JSON.stringify(releaseConfig, null, 2)
  );
  
  console.log('\nevmpack.json and release.json created successfully!');


}

module.exports = {
  init,
  implTypes,
  packageTypes
};