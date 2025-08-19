async function upgradeMultiSig() {
  const contract = await ethers.getContractFactory("MultiSig");

  await upgrades.upgradeProxy(process.env.MULTI_SIG_CONTRACT, contract);
  console.log("contract upgraded");
}

upgradeMultiSig();
