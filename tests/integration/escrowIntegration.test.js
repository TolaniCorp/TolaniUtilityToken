const { expect } = require("chai");
const { ethers, network } = require("hardhat");

/**
 * Integration test combining TUTFaucet and TUTEscrow. A user claims tokens from
 * the faucet and then deposits them into escrow. The payee releases the
 * funds after the expiry. This test ensures contracts interact correctly
 * with one another and token approvals/transfer flows work end‑to‑end.
 */
describe("Escrow Integration", function () {
  let owner, user, payee;
  let tut, faucet, escrow;
  const DRIP = ethers.utils.parseUnits("500", 18);
  const CAP = ethers.utils.parseUnits("1000000", 18);

  beforeEach(async function () {
    [owner, user, payee] = await ethers.getSigners();
    // deploy token and initialize
    const TUTToken = await ethers.getContractFactory("TUTToken");
    tut = await TUTToken.deploy();
    await tut.initialize(owner.address, 0, CAP);
    // deploy faucet
    const TUTFaucet = await ethers.getContractFactory("TUTFaucet");
    faucet = await TUTFaucet.deploy();
    await faucet.initialize(tut.address, DRIP, 3600);
    // fund faucet
    await tut.mint(faucet.address, ethers.utils.parseUnits("10000", 18));
    // deploy escrow
    const TUTEscrow = await ethers.getContractFactory("TUTEscrow");
    escrow = await TUTEscrow.deploy();
    await escrow.initialize(tut.address);
  });

  it("user claims from faucet and deposits into escrow", async function () {
    // user claims tokens
    await faucet.connect(user).claim();
    const userBal = await tut.balanceOf(user.address);
    expect(userBal).to.equal(DRIP);
    // user approves escrow to spend
    await tut.connect(user).approve(escrow.address, DRIP);
    const expireAt = (await ethers.provider.getBlock("latest")).timestamp + 3600;
    const id = await escrow.connect(user).deposit(payee.address, DRIP, expireAt);
    // payee release after expiry
    await network.provider.send("evm_increaseTime", [3601]);
    await network.provider.send("evm_mine");
    const payeeBalBefore = await tut.balanceOf(payee.address);
    await escrow.connect(payee).release(await escrow.computeId(user.address, payee.address, DRIP, expireAt));
    const payeeBalAfter = await tut.balanceOf(payee.address);
    expect(payeeBalAfter.sub(payeeBalBefore)).to.equal(DRIP);
  });
});