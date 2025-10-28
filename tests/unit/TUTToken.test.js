const { expect } = require("chai");
const { ethers } = require("hardhat");

/**
 * Unit tests for the TUTToken contract. This suite verifies core ERC‑20
 * properties such as decimals, cap, and initial supply, and it checks the
 * proper assignment of roles for minting, pausing, and upgrading. It also
 * exercises minting, pausing/unpausing, transfers while paused, and burning.
 */
describe("TUTToken", function () {
  let owner, addr1, addr2;
  let TUTToken, tut;
  const INITIAL_SUPPLY = ethers.utils.parseUnits("1000000", 18); // 1M TUT
  const CAP_SUPPLY = ethers.utils.parseUnits("10000000", 18); // 10M TUT cap

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();
    TUTToken = await ethers.getContractFactory("TUTToken");
    tut = await TUTToken.deploy();
    await tut.initialize(owner.address, INITIAL_SUPPLY, CAP_SUPPLY);
  });

  it("should have 18 decimals", async function () {
    expect(await tut.decimals()).to.equal(18);
  });

  it("should set name and symbol correctly", async function () {
    expect(await tut.name()).to.equal("Tolani Utility Token");
    expect(await tut.symbol()).to.equal("TUT");
  });

  it("should mint initial supply to owner", async function () {
    const ownerBal = await tut.balanceOf(owner.address);
    expect(ownerBal).to.equal(INITIAL_SUPPLY);
    expect(await tut.totalSupply()).to.equal(INITIAL_SUPPLY);
  });

  it("should respect cap", async function () {
    expect(await tut.cap()).to.equal(CAP_SUPPLY);
  });

  it("owner has roles", async function () {
    const minter = await tut.MINTER_ROLE();
    const pauser = await tut.PAUSER_ROLE();
    const upgrader = await tut.UPGRADER_ROLE();
    expect(await tut.hasRole(minter, owner.address)).to.be.true;
    expect(await tut.hasRole(pauser, owner.address)).to.be.true;
    expect(await tut.hasRole(upgrader, owner.address)).to.be.true;
  });

  it("minting increases supply and balances", async function () {
    const amount = ethers.utils.parseUnits("100", 18);
    await tut.mint(addr1.address, amount);
    expect(await tut.balanceOf(addr1.address)).to.equal(amount);
    expect(await tut.totalSupply()).to.equal(INITIAL_SUPPLY.add(amount));
  });

  it("non‑minter cannot mint", async function () {
    const amount = ethers.utils.parseUnits("50", 18);
    await expect(
      tut.connect(addr1).mint(addr1.address, amount)
    ).to.be.revertedWith(/missing role/);
  });

  it("pause and unpause blocks transfers", async function () {
    const amount = ethers.utils.parseUnits("100", 18);
    // transfer some tokens to addr1 first
    await tut.transfer(addr1.address, amount);
    // pause
    await tut.pause();
    await expect(
      tut.connect(addr1).transfer(addr2.address, ethers.utils.parseUnits("10", 18))
    ).to.be.revertedWith("Token is paused");
    // unpause and transfer should succeed
    await tut.unpause();
    await tut.connect(addr1).transfer(addr2.address, ethers.utils.parseUnits("10", 18));
    expect(await tut.balanceOf(addr2.address)).to.equal(ethers.utils.parseUnits("10", 18));
  });

  it("burn reduces supply and balances", async function () {
    const burnAmount = ethers.utils.parseUnits("50000", 18);
    await tut.burn(burnAmount);
    expect(await tut.balanceOf(owner.address)).to.equal(INITIAL_SUPPLY.sub(burnAmount));
    expect(await tut.totalSupply()).to.equal(INITIAL_SUPPLY.sub(burnAmount));
  });
});