const { ethers } = require("hardhat");
require("dotenv").config();

// 05_grant_role_TUTToken.js
//
// Grants a role to a target address on the TUTToken proxy.  You must
// specify the proxy via PROXY_ADDRESS and the address to grant via
// TARGET_ADDRESS.  Optionally override ROLE_KEY from the default of
// MINTER_ROLE.  If the role constant exists on the contract it will be
// used; otherwise the script falls back to hashing the role name.  The
// script checks whether the target already has the role before granting.
// Example usage:
//   PROXY_ADDRESS=0xYourProxy TARGET_ADDRESS=0xRecipient ROLE_KEY=UPGRADER_ROLE npx hardhat run scripts/deployment/05_grant_role_TUTToken.js --network <network>

async function main() {
  const proxyAddress = process.env.PROXY_ADDRESS;
  const targetAddress = process.env.TARGET_ADDRESS;
  const roleKey = process.env.ROLE_KEY || "MINTER_ROLE";
  if (!proxyAddress || !targetAddress) {
    throw new Error("Set PROXY_ADDRESS and TARGET_ADDRESS in your environment");
  }

  const [caller] = await ethers.getSigners();
  const token = await ethers.getContractAt("TUTToken", proxyAddress, caller);
  // Determine the role constant
  let role;
  try {
    role = await token[roleKey]();
  } catch (err) {
    role = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(roleKey));
  }
  const hasRole = await token.hasRole(role, targetAddress);
  if (hasRole) {
    console.log(`${targetAddress} already has role ${roleKey}`);
    return;
  }
  console.log(`Granting role ${roleKey} to ${targetAddress}`);
  const tx = await token.grantRole(role, targetAddress);
  await tx.wait();
  const hasRoleAfter = await token.hasRole(role, targetAddress);
  console.log(`Role ${roleKey} granted?`, hasRoleAfter);
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});