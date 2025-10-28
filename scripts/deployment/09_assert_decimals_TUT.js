const { ethers } = require("hardhat");
require("dotenv").config();

// 09_assert_decimals_TUT.js
//
// Simple script to verify that the TUTToken contract returns 18
// decimals via its `decimals()` function.  A non-zero exit code is
// returned if the invariant is violated.  Provide the proxy address
// via PROXY_ADDRESS.  To run:
//   PROXY_ADDRESS=0xYourProxy npx hardhat run scripts/deployment/09_assert_decimals_TUT.js --network <network>

async function main() {
  const proxyAddress = process.env.PROXY_ADDRESS;
  if (!proxyAddress) {
    throw new Error("Set PROXY_ADDRESS in your environment to the deployed proxy");
  }
  const token = await ethers.getContractAt("TUTToken", proxyAddress);
  const decimals = await token.decimals();
  if (decimals.toString() !== "18") {
    throw new Error(`DECIMALS_INVARIANT_BROKEN: expected 18, got ${decimals}`);
  }
  console.log("Decimals invariant holds (18)");
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});