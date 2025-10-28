const { ethers, upgrades } = require("hardhat");
const { getImplementationAddress } = require("@openzeppelin/upgrades-core");
require("dotenv").config();

// 03_upgrade_TUTToken.js
//
// Performs the proxy upgrade to a new TUTToken implementation.  It
// requires the environment variable PROXY_ADDRESS to be set to the
// address of the existing proxy contract.  The script upgrades to
// TUTTokenV2 and prints the new implementation address.  To run:
//   PROXY_ADDRESS=0xYourProxy npx hardhat run scripts/deployment/03_upgrade_TUTToken.js --network <network>

async function main() {
  const proxyAddress = process.env.PROXY_ADDRESS;
  if (!proxyAddress) {
    throw new Error("Set PROXY_ADDRESS in your environment to the deployed proxy");
  }

  const TUTTokenV2 = await ethers.getContractFactory("TUTTokenV2");
  const upgraded = await upgrades.upgradeProxy(proxyAddress, TUTTokenV2);
  await upgraded.deployed();

  const impl = await getImplementationAddress(ethers.provider, upgraded.address);
  console.log("Proxy upgraded:", upgraded.address);
  console.log("New implementation deployed at:", impl);
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});