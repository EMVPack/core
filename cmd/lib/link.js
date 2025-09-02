const {
    loadConfig,
    validateConfig
} = require("./config");
const { execSync } = require('child_process');
const os = require('os');

async function link() {
    
    const evmpackConfig = loadConfig('evmpack.json');
    const releaseConfig = loadConfig('release.json');

    const errors = validateConfig(evmpackConfig, releaseConfig);

    if (errors.length > 0) {
        throw new Error(`Configuration errors: \n - ${errors.join('\n - ')}`);
    }

    execSync(`rm -f ${os.homedir()}/.evmpack/packages/${evmpackConfig.name}* && ln -s ${process.cwd()} ${os.homedir()}/.evmpack/packages/${evmpackConfig.name}-${releaseConfig.version} `)

}

module.exports = {
    link
}