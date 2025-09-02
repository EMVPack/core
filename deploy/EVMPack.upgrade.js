

module.exports = async () => {
    const { upgrade } = require("../lib/deploy")
    const hre = require("hardhat")
    const [deployer] = await hre.ethers.getSigners();

    console.log("Upgrade from:" , deployer.address)
    console.log("Balance: ", hre.ethers.formatEther(await hre.ethers.provider.getBalance(deployer.address)))

    await upgrade(hre.ethers.provider, deployer);

};
module.exports.tags = ['EVMPackUpgrade'];