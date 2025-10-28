const { ethers, upgrades, network } = require("hardhat");
const { getImplementationAddress } = require("@openzeppelin/upgrades-core");
require("dotenv").config();

// 01_deploy_TUTToken.js
//
// This script deploys an upgradeable instance of the TUTToken contract.  It
// accepts initializer arguments via the `INIT_ARGS` environment variable in
// JSON array form.  When `INIT_ARGS` is not provided the script falls back
// to sensible defaults: the deployer's address as the owner, an initial
// supply of 50 million tokens (with 18 decimals) and a cap of 100 million.
// After deployment, the script prints both the proxy and implementation
// addresses.  To run:
//   PROXY_OWNER=0xYourOwner INIT_ARGS='["0xOwner","50000000000000000000000000","100000000000000000000000000"]' npx hardhat run scripts/deployment/01_deploy_TUTToken.js --network <network>

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log(
    `Deploying TUTToken with account: ${deployer.address} on network: ${network.name}`
  );

  const TUTToken = await ethers.getContractFactory("TUTToken");

  // Default initializer arguments: owner, initial supply and cap.  Adjust as
  // necessary for your deployment.  The values are expected to be strings
  // containing the integer amounts in wei (i.e. with 18 decimals).
  const defaultOwner = deployer.address;
  const decimals = 18;
  const defaultSupply = ethers.utils.parseUnits("50000000", decimals);
  const defaultCap = ethers.utils.parseUnits("100000000", decimals);

  let initArgs;
  if (process.env.INIT_ARGS) {
    try {
      initArgs = JSON.parse(process.env.INIT_ARGS);
    } catch (e) {
      throw new Error(
        `INIT_ARGS environment variable must be valid JSON: ${process.env.INIT_ARGS}`
      );
    }
  } else {
    initArgs = [defaultOwner, defaultSupply, defaultCap];
  }

  // Deploy proxy with initializer
  const proxy = await upgrades.deployProxy(TUTToken, initArgs, {
    initializer: "initialize",
  });
  await proxy.deployed();

  const impl = await getImplementationAddress(ethers.provider, proxy.address);
  console.log("TUTToken proxy deployed to:", proxy.address);
  console.log("TUTToken implementation at:", impl);
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});