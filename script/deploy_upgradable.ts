import dotenv from 'dotenv';
const { ethers } = require("hardhat");
dotenv.config();

async function main() {
    const contractFactory = await ethers.getContractFactory("Token");
    const contract = await upgrades.deployProxy(contractFactory,[process.env.OWNER,process.env.MULTI_SGIN_TIME_LOCK_CONTRACT], { initializer: 'initialize' });
    console.log("deployed to:", contract.target);
}

main();