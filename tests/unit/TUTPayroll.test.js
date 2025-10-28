const { expect } = require("chai");
const { ethers, network } = require("hardhat");

/**
 * Unit tests for the TUTPayroll contract. The payroll allows employers to
 * register employees with a salary and pay interval, deposit funds, and
 * employees can claim their accrued wages. Employers can update salaries
 * and remove employees. These tests verify correct accrual calculation,
 * claims, updates, and removal logic.
 */
describe("TUTPayroll", function () {
  let admin, employer, employee, other;
  let TUTToken, tut;
  let Payroll, payroll;
  const salary = ethers.utils.parseUnits("100", 18);
  const interval = 60; // 60 seconds interval
  const cap = ethers.utils.parseUnits("1000000", 18);

  beforeEach(async function () {
    [admin, employer, employee, other] = await ethers.getSigners();
    // Deploy token and mint supply
    TUTToken = await ethers.getContractFactory("TUTToken");
    tut = await TUTToken.deploy();
    await tut.initialize(admin.address, 0, cap);
    // Mint tokens to employer
    await tut.mint(employer.address, ethers.utils.parseUnits("10000", 18));
    // Deploy payroll
    Payroll = await ethers.getContractFactory("TUTPayroll");
    payroll = await Payroll.deploy();
    await payroll.initialize(tut.address, admin.address);
    // Grant employer role to employer (admin can grant role)
    const EMPLOYER_ROLE = await payroll.EMPLOYER_ROLE();
    await payroll.grantRole(EMPLOYER_ROLE, employer.address);
  });

  it("employer can add employee and deposit funds", async function () {
    await payroll.connect(employer).addEmployee(employee.address, salary, interval);
    const emp = await payroll.employees(employee.address);
    expect(emp.exists).to.be.true;
    expect(emp.salary).to.equal(salary);
    expect(emp.interval).to.equal(interval);
    // deposit funds
    const depositAmount = ethers.utils.parseUnits("1000", 18);
    await tut.connect(employer).approve(payroll.address, depositAmount);
    await payroll.connect(employer).deposit(depositAmount);
    expect(await tut.balanceOf(payroll.address)).to.equal(depositAmount);
  });

  it("employee accrues and claims salary over time", async function () {
    await payroll.connect(employer).addEmployee(employee.address, salary, interval);
    // fund payroll
    await tut.connect(employer).approve(payroll.address, ethers.utils.parseUnits("1000", 18));
    await payroll.connect(employer).deposit(ethers.utils.parseUnits("1000", 18));
    // fast forward one interval
    await network.provider.send("evm_increaseTime", [interval]);
    await network.provider.send("evm_mine");
    const owed = await payroll.getAccrued(employee.address);
    expect(owed).to.equal(salary);
    const balBefore = await tut.balanceOf(employee.address);
    await payroll.connect(employee).claim();
    const balAfter = await tut.balanceOf(employee.address);
    expect(balAfter.sub(balBefore)).to.equal(salary);
  });

  it("employer can update salary and employee claims new rate", async function () {
    await payroll.connect(employer).addEmployee(employee.address, salary, interval);
    await tut.connect(employer).approve(payroll.address, ethers.utils.parseUnits("2000", 18));
    await payroll.connect(employer).deposit(ethers.utils.parseUnits("2000", 18));
    // wait one interval and claim initial salary
    await network.provider.send("evm_increaseTime", [interval]);
    await network.provider.send("evm_mine");
    await payroll.connect(employee).claim();
    // update salary to a higher amount
    const newSalary = ethers.utils.parseUnits("150", 18);
    await payroll.connect(employer).updateSalary(employee.address, newSalary);
    // wait another interval and claim new salary
    await network.provider.send("evm_increaseTime", [interval]);
    await network.provider.send("evm_mine");
    const owed = await payroll.getAccrued(employee.address);
    expect(owed).to.equal(newSalary);
    const balBefore = await tut.balanceOf(employee.address);
    await payroll.connect(employee).claim();
    const balAfter = await tut.balanceOf(employee.address);
    expect(balAfter.sub(balBefore)).to.equal(newSalary);
  });

  it("employer can remove employee", async function () {
    await payroll.connect(employer).addEmployee(employee.address, salary, interval);
    await payroll.connect(employer).removeEmployee(employee.address);
    const emp = await payroll.employees(employee.address);
    expect(emp.exists).to.be.false;
    // cannot claim after removal
    await network.provider.send("evm_increaseTime", [interval]);
    await network.provider.send("evm_mine");
    await expect(
      payroll.connect(employee).claim()
    ).to.be.revertedWith("Not an employee");
  });
});