import dotenv from 'dotenv';
const { ethers } = require("hardhat");
dotenv.config();

async function main() {
    const [deployer] = await ethers.getSigners();
    const multiSigContractAddress = process.env.MULTI_SGIN_TIME_LOCK_CONTRACT;


    const address = await deployer.getAddress();
    console.log(" deployer address:", address);

    // Attach to the deployed MultiSigTimeLock contract
    const multiSigContract = await ethers.getContractAt("MultiSigTimeLock", multiSigContractAddress);

    // Create an upgrade proposal
    const tx = await multiSigContract.connect(deployer).createUpgradeContractProposal(address);
    console.log("Upgrade proposal created tx hash:", tx.hash);

    // Wait for the proposal to be mined
    await tx.wait();

    const proposalCount = (await multiSigContract.proposalCount()).valueOf();
    console.log("Upgrade proposal submitted. Wait for multi-signature approvals.");
    console.log("Proposal ID for approval:", (proposalCount - BigInt(1)));

}

main();

