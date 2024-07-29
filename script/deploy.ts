import dotenv from 'dotenv';
const { ethers } = require("hardhat");
dotenv.config();

async function main() {
  const contractFactory = await ethers.getContractFactory("Token");
  const contract  = await contractFactory.deploy(process.env.OWNER);
  // const upgrade = await upgrades.deployProxy(contractFactory , [process.env.OWNER,process.env.TOKEN,1], { initializer: 'initialize' });
  console.log("deployed to:", await contract.getAddress());


}

main();