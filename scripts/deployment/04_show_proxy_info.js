const { ethers } = require("hardhat");
const {
  getImplementationAddress,
  getAdminAddress,
} = require("@openzeppelin/upgrades-core");
require("dotenv").config();

// 04_show_proxy_info.js
//
// Utility script to display proxy information.  It prints the proxy,
// implementation and admin addresses for a UUPS or transparent proxy.  If
// called on a UUPS proxy, the admin may not be set.  To run:
//   PROXY_ADDRESS=0xYourProxy npx hardhat run scripts/deployment/04_show_proxy_info.js --network <network>

async function main() {
  const proxyAddress = process.env.PROXY_ADDRESS;
  if (!proxyAddress) {
    throw new Error("Set PROXY_ADDRESS in your environment to the deployed proxy");
  }
  const impl = await getImplementationAddress(ethers.provider, proxyAddress);
  let admin;
  try {
    admin = await getAdminAddress(ethers.provider, proxyAddress);
  } catch (err) {
    admin = "<not applicable>";
  }
  console.log("Proxy address:", proxyAddress);
  console.log("Implementation address:", impl);
  console.log("Admin address:", admin);
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});