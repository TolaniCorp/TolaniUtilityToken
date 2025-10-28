const { expect } = require("chai");
const { ethers, network } = require("hardhat");

/**
 * Unit tests for the TUTFaucet contract. The faucet dispenses a fixed
 * amount of TUT tokens to users subject to a cooldown. The owner can
 * adjust the drip amount and wait time and withdraw funds. These tests
 * verify correct claim behavior, cooldown enforcement, parameter updates,
 * and secure ownership checks.
 */
describe("TUTFaucet", function () {
  let owner, user, other;
  let TUTToken, tut;
  let TUTFaucet, faucet;
  const DRIP = ethers.utils.parseUnits("100", 18);
  const WAIT = 3600; // 1 hour

  beforeEach(async function () {
    [owner, user, other] = await ethers.getSigners();
    // Deploy token and mint some supply to owner
    TUTToken = await ethers.getContractFactory("TUTToken");
    tut = await TUTToken.deploy();
    const initial = ethers.utils.parseUnits("100000", 18);
    const cap = ethers.utils.parseUnits("1000000", 18);
    await tut.initialize(owner.address, initial, cap);

    // Deploy faucet and initialize
    TUTFaucet = await ethers.getContractFactory("TUTFaucet");
    faucet = await TUTFaucet.deploy();
    await faucet.initialize(tut.address, DRIP, WAIT);

    // Fund faucet with tokens from owner
    await tut.transfer(faucet.address, ethers.utils.parseUnits("10000", 18));
  });

  it("allows user to claim tokens once per cooldown", async function () {
    const balBefore = await tut.balanceOf(user.address);
    await faucet.connect(user).claim();
    const balAfter = await tut.balanceOf(user.address);
    expect(balAfter.sub(balBefore)).to.equal(DRIP);

    // second claim should fail due to cooldown
    await expect(faucet.connect(user).claim()).to.be.revertedWith("Wait time not passed");
    // simulate passage of time
    await network.provider.send("evm_increaseTime", [WAIT]);
    await network.provider.send("evm_mine");
    // now claim again
    await faucet.connect(user).claim();
    const balAfter2 = await tut.balanceOf(user.address);
    expect(balAfter2.sub(balAfter)).to.equal(DRIP);
  });

  it("owner can update drip amount and wait time", async function () {
    // update drip amount
    const newDrip = ethers.utils.parseUnits("200", 18);
    await faucet.setDripAmount(newDrip);
    expect(await faucet.dripAmount()).to.equal(newDrip);
    // update wait time
    const newWait = 7200;
    await faucet.setWaitTime(newWait);
    expect(await faucet.waitTime()).to.equal(newWait);
    // non owner cannot update
    await expect(
      faucet.connect(user).setDripAmount(newDrip)
    ).to.be.revertedWith("Ownable: caller is not the owner");
  });

  it("owner can withdraw tokens from faucet", async function () {
    const withdrawAmount = ethers.utils.parseUnits("1000", 18);
    const ownerBefore = await tut.balanceOf(owner.address);
    await faucet.withdraw(owner.address, withdrawAmount);
    const ownerAfter = await tut.balanceOf(owner.address);
    expect(ownerAfter.sub(ownerBefore)).to.equal(withdrawAmount);
    // non owner cannot withdraw
    await expect(
      faucet.connect(user).withdraw(user.address, withdrawAmount)
    ).to.be.revertedWith("Ownable: caller is not the owner");
  });
});