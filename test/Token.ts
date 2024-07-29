import {
    time,
    loadFixture,
  } from "@nomicfoundation/hardhat-toolbox/network-helpers";
  import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";

  import { expect } from "chai";
  import hre from "hardhat";
  
  describe("Token", function () {
    // We define a fixture to reuse the same setup in every test.
    // We use loadFixture to run this setup once, snapshot that state,
    // and reset Hardhat Network to that snapshot in every test.
    async function deployFixture() {
      // Contracts are deployed using the first signer/account by default
      const [owner,otherAccount] = await hre.ethers.getSigners();
  
      const cf = await hre.ethers.getContractFactory("Token");
        const contract = await upgrades.deployProxy(cf,[process.env.OWNER], { initializer: 'initialize' });


      return { contract, owner,otherAccount };
    }

    describe("Deployment", function () {
        it("Should deploy the contract with the owner as the deployer", async function () {
            const { contract, owner } = await deployFixture();
            expect(await contract.symbol() ).to.equal('DGC');
        })    
    })
    // todo
  });