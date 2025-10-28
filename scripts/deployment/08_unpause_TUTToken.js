const { ethers } = require("hardhat");
require("dotenv").config();

// 08_unpause_TUTToken.js
//
// Unpauses the TUTToken contract via its proxy.  Requires the caller to
// have the PAUSER_ROLE.  The proxy address must be provided via
// PROXY_ADDRESS.  Example usage:
//   PROXY_ADDRESS=0xYourProxy npx hardhat run scripts/deployment/08_unpause_TUTToken.js --network <network>

async function main() {
  const proxyAddress = process.env.PROXY_ADDRESS;
  if (!proxyAddress) {
    throw new Error("Set PROXY_ADDRESS in your environment to the deployed proxy");
  }
  const [caller] = await ethers.getSigners();
  const token = await ethers.getContractAt("TUTToken", proxyAddress, caller);
  console.log(`Unpausing TUTToken at ${proxyAddress}...`);
  const tx = await token.unpause();
  await tx.wait();
  console.log(`TUTToken unpaused.`);
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});