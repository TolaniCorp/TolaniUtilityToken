/**
 * Hardhat configuration for the Tolani Utility Token (TUT) project.
 *
 * This config enables Solidity v0.8.20 compilation, integrates the
 * modern Ethers v6 plugin (`@nomicfoundation/hardhat-ethers`) for
 * ethers.js support, the @openzeppelin/hardhat-upgrades plugin for
 * deploying and upgrading UUPS proxies, and the
 * @nomicfoundation/hardhat-etherscan plugin for verifying contracts
 * on Etherscan.  RPC URLs and private keys are loaded from environment
 * variables via dotenv.  You can supply either `ALCHEMY_URL` or
 * `INFURA_URL` to point at an Ethereum testnet or mainnet, along with
 * your `PRIVATE_KEY` for signing transactions.
 */

require('dotenv').config();
// Use the Ethers v6 plugin from Nomic Foundation.  This replaces
// `@nomiclabs/hardhat-ethers` (which depends on ethers v5).
require('@nomicfoundation/hardhat-ethers');
// Support for OpenZeppelin upgradeable contracts via UUPS proxies.
require('@openzeppelin/hardhat-upgrades');
// Plugin to verify contracts on Etherscan (Nomic Foundation edition).
require('@nomicfoundation/hardhat-etherscan');

const {
  ALCHEMY_URL,
  INFURA_URL,
  PRIVATE_KEY,
  ETHERSCAN_API_KEY
} = process.env;

module.exports = {
  solidity: '0.8.20',
  // Use Sepolia by default. You can override this at runtime with
  // the --network flag or by editing your .env (ALCHEMY_URL or INFURA_URL).
  defaultNetwork: 'sepolia',
  networks: {
    // Built-in Hardhat local network
    hardhat: {},
    // Sepolia testnet (update URL with your Alchemy or Infura endpoint)
    sepolia: {
      url: ALCHEMY_URL || INFURA_URL || '',
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : []
    },
    // Mainnet configuration can be added here when ready
    // mainnet: {
    //   url: ALCHEMY_MAINNET_URL || INFURA_MAINNET_URL,
    //   accounts: PRIVATE_KEY ? [PRIVATE_KEY] : []
    // }
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY || ''
  }
};