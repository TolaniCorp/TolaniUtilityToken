const { expect } = require("chai");
const { ethers, network } = require("hardhat");

/**
 * Integration test for TUTPayroll combined with TUTFaucet. An employer
 * claims tokens from the faucet to fund the payroll and pays an employee
 * over time. This test demonstrates cross‑contract interactions and proper
 * salary accrual and claim flow.
 */
describe("Payroll Integration", function () {
  let owner, admin, employer, employee;
  let tut, faucet, payroll;
  const DRIP = ethers.utils.parseUnits("2000", 18);
  const CAP = ethers.utils.parseUnits("1000000", 18);
  const salary = ethers.utils.parseUnits("100", 18);
  const interval = 60; // 60 seconds

  beforeEach(async function () {
    [owner, admin, employer, employee] = await ethers.getSigners();
    // deploy token
    const TUTToken = await ethers.getContractFactory("TUTToken");
    tut = await TUTToken.deploy();
    await tut.initialize(owner.address, 0, CAP);
    // deploy faucet
    const TUTFaucet = await ethers.getContractFactory("TUTFaucet");
    faucet = await TUTFaucet.deploy();
    await faucet.initialize(tut.address, DRIP, 3600);
    // fund faucet
    await tut.mint(faucet.address, ethers.utils.parseUnits("20000", 18));
    // deploy payroll
    const TUTPayroll = await ethers.getContractFactory("TUTPayroll");
    payroll = await TUTPayroll.deploy();
    await payroll.initialize(tut.address, admin.address);
    // grant employer role
    const EMPLOYER_ROLE = await payroll.EMPLOYER_ROLE();
    await payroll.grantRole(EMPLOYER_ROLE, employer.address);
    // add employee
    await payroll.connect(employer).addEmployee(employee.address, salary, interval);
  });

  it("employer funds payroll from faucet and employee claims", async function () {
    // employer claims tokens from faucet
    await faucet.connect(employer).claim();
    const empBal = await tut.balanceOf(employer.address);
    expect(empBal).to.equal(DRIP);
    // employer deposits part of drip to payroll
    const depositAmt = ethers.utils.parseUnits("1000", 18);
    await tut.connect(employer).approve(payroll.address, depositAmt);
    await payroll.connect(employer).deposit(depositAmt);
    expect(await tut.balanceOf(payroll.address)).to.equal(depositAmt);
    // wait one interval and claim
    await network.provider.send("evm_increaseTime", [interval]);
    await network.provider.send("evm_mine");
    const owed = await payroll.getAccrued(employee.address);
    expect(owed).to.equal(salary);
    const balBefore = await tut.balanceOf(employee.address);
    await payroll.connect(employee).claim();
    const balAfter = await tut.balanceOf(employee.address);
    expect(balAfter.sub(balBefore)).to.equal(salary);
  });
});