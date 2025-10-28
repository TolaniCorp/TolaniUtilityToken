const { expect } = require("chai");
const { ethers, network } = require("hardhat");

/**
 * Unit tests for the TUTHVACServices contract. This suite verifies the full
 * lifecycle of a service order: creation, technician registration, assignment,
 * start, completion, customer confirmation and rating. It also tests
 * cancellation by the customer and refunds issued by the manager.
 */
describe("TUTHVACServices", function () {
  let owner, manager, technician, customer, other;
  let TUTToken, tut;
  let HVAC, hvac;
  const depositAmount = ethers.utils.parseUnits("1000", 18);
  const cap = ethers.utils.parseUnits("1000000", 18);

  beforeEach(async function () {
    [owner, manager, technician, customer, other] = await ethers.getSigners();
    // Deploy token and initialize
    TUTToken = await ethers.getContractFactory("TUTToken");
    tut = await TUTToken.deploy();
    await tut.initialize(owner.address, 0, cap);
    // Mint tokens for customer
    await tut.mint(customer.address, depositAmount.mul(2));
    // Deploy HVAC services contract; manager is given roles
    HVAC = await ethers.getContractFactory("TUTHVACServices");
    hvac = await HVAC.deploy();
    await hvac.initialize(tut.address, manager.address);
    // Manager registers technician
    await hvac.connect(manager).registerTechnician(technician.address);
  });

  it("full order flow: create, assign, work, complete, confirm", async function () {
    // Customer approves deposit
    await tut.connect(customer).approve(hvac.address, depositAmount);
    // Create order
    const tx = await hvac.connect(customer).createOrder(depositAmount, "Fix AC");
    const receipt = await tx.wait();
    const orderId = receipt.events.find(e => e.event === "OrderCreated").args.orderId;
    // Manager assigns technician
    await hvac.connect(manager).assignTechnician(orderId, technician.address);
    // Technician starts work
    await hvac.connect(technician).startWork(orderId);
    // Technician marks completed
    await hvac.connect(technician).markCompleted(orderId);
    // Customer confirms and rates with 5 stars
    const techBalBefore = await tut.balanceOf(technician.address);
    await hvac.connect(customer).confirmAndRate(orderId, 5);
    const techBalAfter = await tut.balanceOf(technician.address);
    expect(techBalAfter.sub(techBalBefore)).to.equal(depositAmount);
    // Order status should be Cancelled (closed)
    const order = await hvac.orders(orderId);
    expect(order.status).to.equal(4); // Cancelled enum value
    expect(order.rating).to.equal(5);
  });

  it("customer can cancel before work starts and receive refund", async function () {
    await tut.connect(customer).approve(hvac.address, depositAmount);
    const tx = await hvac.connect(customer).createOrder(depositAmount, "Install heater");
    const orderId = tx.logs ? tx.logs[0].args.orderId : (await tx.wait()).events.find(e => e.event === "OrderCreated").args.orderId;
    const custBalBefore = await tut.balanceOf(customer.address);
    await hvac.connect(customer).cancelOrder(orderId);
    const custBalAfter = await tut.balanceOf(customer.address);
    expect(custBalAfter.sub(custBalBefore)).to.equal(depositAmount);
    // Order status should be Cancelled
    const order = await hvac.orders(orderId);
    expect(order.status).to.equal(4);
  });

  it("manager can refund after assignment but before completion", async function () {
    await tut.connect(customer).approve(hvac.address, depositAmount);
    const tx = await hvac.connect(customer).createOrder(depositAmount, "Clean ducts");
    const orderId = (await tx.wait()).events.find(e => e.event === "OrderCreated").args.orderId;
    // Assign technician and start work
    await hvac.connect(manager).assignTechnician(orderId, technician.address);
    await hvac.connect(technician).startWork(orderId);
    const custBalBefore = await tut.balanceOf(customer.address);
    // Manager refunds (dispute)
    await hvac.connect(manager).managerRefund(orderId);
    const custBalAfter = await tut.balanceOf(customer.address);
    expect(custBalAfter.sub(custBalBefore)).to.equal(depositAmount);
    const order = await hvac.orders(orderId);
    expect(order.status).to.equal(4);
  });
});