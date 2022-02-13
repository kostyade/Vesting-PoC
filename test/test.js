const { expect } = require("chai");
const { ethers, network } = require("hardhat");

describe("Vesting", function () {
  // eslint-disable-next-line no-unused-vars
  let owner, degen1, degen2;
  let token, vesting;

  beforeEach(async function () {
    [owner, degen1, degen2] = await ethers.getSigners();

    // Deploying ERC20 contract
    const SCM = await ethers.getContractFactory("SCM");
    token = await SCM.deploy();
    await token.deployed();

    // Deploying Staking contract
    const Vesting = await ethers.getContractFactory("Vesting");
    const start = (Date.now() / 1000).toFixed();
    console.log(start);
    vesting = await Vesting.deploy(token.address, start, 25, 2629746, 5);
    await vesting.deployed();

    // Set staking address, pre-mint and distribute initial supply
    await token.setVestingAddress(vesting.address);
    await token.preMint(1000000);
    await vesting.addUsers([degen1.address, degen2.address], [100, 1000]);
  });

  describe("Vesting scenarios", function () {
    it("cliff must be available", async function () {
      expect(await vesting.withdrawableOf(degen1.address)).to.be.equal(25);
      expect(await vesting.withdrawableOf(degen2.address)).to.be.equal(250);
    });
    it("cliff + 15% must be available after one month", async function () {
      await network.provider.send("evm_increaseTime", [2629746]);
      await network.provider.send("evm_mine");

      expect(await vesting.withdrawableOf(degen1.address)).to.be.equal(40);
      expect(await vesting.withdrawableOf(degen2.address)).to.be.equal(400);
    });
    it("cliff + 30% must be available to withdraw after two months", async function () {
      await network.provider.send("evm_increaseTime", [2629746]);
      await network.provider.send("evm_mine");

      expect(await vesting.withdrawableOf(degen1.address)).to.be.equal(55);
      expect(await vesting.withdrawableOf(degen2.address)).to.be.equal(550);

      await vesting.connect(degen1).withdraw();
      await vesting.connect(degen2).withdraw();
      expect(await token.balanceOf(degen1.address)).to.be.equal(55);
      expect(await token.balanceOf(degen2.address)).to.be.equal(550);
    });
    it("degens shouldn't be able to withdraw multiple times", async function () {
      await vesting.connect(degen1).withdraw();
      await vesting.connect(degen2).withdraw();
      await vesting.connect(degen1).withdraw();
      await vesting.connect(degen2).withdraw();
      await vesting.connect(degen1).withdraw();
      await vesting.connect(degen2).withdraw();
      expect(await token.balanceOf(degen1.address)).to.be.equal(55);
      expect(await token.balanceOf(degen2.address)).to.be.equal(550);
    });
  });
});
