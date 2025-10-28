const { ethers, upgrades } = require("hardhat");
require("dotenv").config();

// 02_validate_and_prepare_upgrade_TUTToken.js
//
// This script validates the storage layout of a pending TUTToken V2 contract
// against an existing proxy and prepares the new implementation.  It will
// throw an error if the storage layout is incompatible.  After a
// successful validation the script prints out the new implementation
// address.  To run:
//   PROXY_ADDRESS=0xYourProxy npx hardhat run scripts/deployment/02_validate_and_prepare_upgrade_TUTToken.js --network <network>

async function main() {
  const proxyAddress = process.env.PROXY_ADDRESS;
  if (!proxyAddress) {
    throw new Error("Set PROXY_ADDRESS in your environment to the deployed proxy");
  }

  // Replace this contract name with the name of your upgraded implementation
  const TUTTokenV2 = await ethers.getContractFactory("TUTTokenV2");

  // Validate the upgrade.  This will throw if the storage layout does not
  // match and is critical to run before preparing the upgrade.
  await upgrades.validateUpgrade(proxyAddress, TUTTokenV2);

  // Prepare the upgrade to obtain the implementation address.  This does
  // not perform the upgrade but returns the new implementation address so
  // that you can inspect or verify it.
  const newImplAddress = await upgrades.prepareUpgrade(proxyAddress, TUTTokenV2);
  console.log("Validated upgrade. New implementation prepared at:", newImplAddress);
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});