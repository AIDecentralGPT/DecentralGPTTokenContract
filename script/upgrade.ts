const { ethers, upgrades } = require("hardhat");

async function main() {
    const contract = await ethers.getContractFactory("Token");

    await upgrades.upgradeProxy(
        process.env.PROXY_CONTRACT,
        contract
    );
    console.log("contract upgraded");
}

main();