const { ethers } = require("hardhat");
require("dotenv").config();

// 07_pause_TUTToken.js
//
// Pauses the TUTToken contract via its proxy.  Requires the caller to
// have the PAUSER_ROLE.  The proxy address must be provided via
// PROXY_ADDRESS.  Example usage:
//   PROXY_ADDRESS=0xYourProxy npx hardhat run scripts/deployment/07_pause_TUTToken.js --network <network>

async function main() {
  const proxyAddress = process.env.PROXY_ADDRESS;
  if (!proxyAddress) {
    throw new Error("Set PROXY_ADDRESS in your environment to the deployed proxy");
  }
  const [caller] = await ethers.getSigners();
  const token = await ethers.getContractAt("TUTToken", proxyAddress, caller);
  console.log(`Pausing TUTToken at ${proxyAddress}...`);
  const tx = await token.pause();
  await tx.wait();
  console.log(`TUTToken paused.`);
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});