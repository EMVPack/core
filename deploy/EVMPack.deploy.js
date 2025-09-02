

module.exports = async () => {
    const { deploy } = require("../lib/deploy")
    const hre = require("hardhat")
    const [deployer] = await hre.ethers.getSigners();

    console.log("Deploy from:" , deployer.address)
    console.log("Balance: ", hre.ethers.formatEther(await hre.ethers.provider.getBalance(deployer.address)))

    await deploy(hre.ethers.provider, deployer);

};
module.exports.tags = ['EVMPack'];