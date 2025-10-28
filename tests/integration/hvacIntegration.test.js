const { expect } = require("chai");
const { ethers, network } = require("hardhat");

/**
 * Integration test for TUTHVACServices combined with TUTFaucet and TUTToken.
 * A customer claims tokens from the faucet and uses them to create a service
 * order. The manager assigns a technician, who completes the job, and the
 * customer confirms and rates. Tokens flow from faucet to customer to HVAC
 * and finally to the technician.
 */
describe("HVAC Services Integration", function () {
  let owner, manager, technician, customer;
  let tut, faucet, hvac;
  const DRIP = ethers.utils.parseUnits("1000", 18);
  const CAP = ethers.utils.parseUnits("1000000", 18);

  beforeEach(async function () {
    [owner, manager, technician, customer] = await ethers.getSigners();
    // deploy token and initialize
    const TUTToken = await ethers.getContractFactory("TUTToken");
    tut = await TUTToken.deploy();
    await tut.initialize(owner.address, 0, CAP);
    // deploy faucet with drip 1000 tokens
    const TUTFaucet = await ethers.getContractFactory("TUTFaucet");
    faucet = await TUTFaucet.deploy();
    await faucet.initialize(tut.address, DRIP, 3600);
    // fund faucet
    await tut.mint(faucet.address, ethers.utils.parseUnits("10000", 18));
    // deploy hvac
    const TUTHVACServices = await ethers.getContractFactory("TUTHVACServices");
    hvac = await TUTHVACServices.deploy();
    await hvac.initialize(tut.address, manager.address);
    // manager registers technician
    await hvac.connect(manager).registerTechnician(technician.address);
  });

  it("customer uses faucet tokens to pay for HVAC service", async function () {
    // customer claims from faucet
    await faucet.connect(customer).claim();
    const custBal = await tut.balanceOf(customer.address);
    expect(custBal).to.equal(DRIP);
    // customer approves hvac
    await tut.connect(customer).approve(hvac.address, DRIP);
    // create order
    const tx = await hvac.connect(customer).createOrder(DRIP, "Service A");
    const receipt = await tx.wait();
    const orderId = receipt.events.find(e => e.event === "OrderCreated").args.orderId;
    // assign technician
    await hvac.connect(manager).assignTechnician(orderId, technician.address);
    // start and complete
    await hvac.connect(technician).startWork(orderId);
    await hvac.connect(technician).markCompleted(orderId);
    // confirm and rate
    const techBalBefore = await tut.balanceOf(technician.address);
    await hvac.connect(customer).confirmAndRate(orderId, 4);
    const techBalAfter = await tut.balanceOf(technician.address);
    expect(techBalAfter.sub(techBalBefore)).to.equal(DRIP);
  });
});