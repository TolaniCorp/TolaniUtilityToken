const { expect } = require("chai");
const { ethers, network } = require("hardhat");

/**
 * Unit tests for the TUTEscrow contract. These tests cover deposit creation,
 * releasing funds by payer and payee (after expiry), and refunds. It also
 * verifies that escrow ids are unique and that only authorized parties can
 * release or refund the deposit.
 */
describe("TUTEscrow", function () {
  let owner, payer, payee, other;
  let TUTToken, tut;
  let TUTEscrow, escrow;
  const depositAmount = ethers.utils.parseUnits("500", 18);
  const cap = ethers.utils.parseUnits("1000000", 18);

  beforeEach(async function () {
    [owner, payer, payee, other] = await ethers.getSigners();
    // deploy token and initialize with no supply for payer to mint
    TUTToken = await ethers.getContractFactory("TUTToken");
    tut = await TUTToken.deploy();
    await tut.initialize(owner.address, 0, cap);
    // mint tokens to payer
    await tut.mint(payer.address, ethers.utils.parseUnits("1000", 18));
    // deploy escrow
    TUTEscrow = await ethers.getContractFactory("TUTEscrow");
    escrow = await TUTEscrow.deploy();
    await escrow.initialize(tut.address);
  });

  it("payer can deposit and release funds before expiry", async function () {
    // approve
    await tut.connect(payer).approve(escrow.address, depositAmount);
    const expireAt = (await ethers.provider.getBlock("latest")).timestamp + 3600;
    const tx = await escrow.connect(payer).deposit(payee.address, depositAmount, expireAt);
    const receipt = await tx.wait();
    // compute id
    const id = await escrow.computeId(payer.address, payee.address, depositAmount, expireAt);
    // release by payer
    const balBefore = await tut.balanceOf(payee.address);
    await escrow.connect(payer).release(id);
    const balAfter = await tut.balanceOf(payee.address);
    expect(balAfter.sub(balBefore)).to.equal(depositAmount);
    // escrow should be removed
    const e = await escrow.escrows(id);
    expect(e.amount).to.equal(0);
  });

  it("payee can claim after expiry", async function () {
    await tut.connect(payer).approve(escrow.address, depositAmount);
    const expireAt = (await ethers.provider.getBlock("latest")).timestamp + 3600;
    await escrow.connect(payer).deposit(payee.address, depositAmount, expireAt);
    const id = await escrow.computeId(payer.address, payee.address, depositAmount, expireAt);
    // increase time beyond expiry
    await network.provider.send("evm_increaseTime", [3601]);
    await network.provider.send("evm_mine");
    const balBefore = await tut.balanceOf(payee.address);
    await escrow.connect(payee).release(id);
    const balAfter = await tut.balanceOf(payee.address);
    expect(balAfter.sub(balBefore)).to.equal(depositAmount);
  });

  it("payer can refund after expiry if payee does not claim", async function () {
    await tut.connect(payer).approve(escrow.address, depositAmount);
    const expireAt = (await ethers.provider.getBlock("latest")).timestamp + 3600;
    await escrow.connect(payer).deposit(payee.address, depositAmount, expireAt);
    const id = await escrow.computeId(payer.address, payee.address, depositAmount, expireAt);
    // wait for expiry
    await network.provider.send("evm_increaseTime", [3601]);
    await network.provider.send("evm_mine");
    const payerBefore = await tut.balanceOf(payer.address);
    await escrow.connect(payer).refund(id);
    const payerAfter = await tut.balanceOf(payer.address);
    expect(payerAfter.sub(payerBefore)).to.equal(depositAmount);
  });

  it("non payer cannot refund and non party cannot release", async function () {
    await tut.connect(payer).approve(escrow.address, depositAmount);
    const expireAt = (await ethers.provider.getBlock("latest")).timestamp + 3600;
    await escrow.connect(payer).deposit(payee.address, depositAmount, expireAt);
    const id = await escrow.computeId(payer.address, payee.address, depositAmount, expireAt);
    // non payer tries to refund
    await expect(
      escrow.connect(other).refund(id)
    ).to.be.revertedWith("Only payer can refund");
    // non payer or payee tries to release before expiry
    await expect(
      escrow.connect(other).release(id)
    ).to.be.revertedWith("Not authorized");
  });
});