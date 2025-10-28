const express = require('express');
const { ethers } = require('ethers');
const path = require('path');

// Load addresses and ABI relative to this file. Using path join ensures
// compatibility across environments.
const addresses = require('../../frontend/dao-dashboard/src/config/addresses.json');
const ABI = require('../../frontend/dao-dashboard/src/abi/TUTToken.json');

// Initialise provider. The RPC URL should be provided via environment
// variable. For local testing you can set RPC_URL=http://localhost:8545.
const provider = new ethers.providers.JsonRpcProvider(process.env.RPC_URL);

const app = express();
app.use(express.json());

// Helper to get contract instance for a given chain ID
function getContract(chainId) {
  const addrInfo = addresses[chainId];
  if (!addrInfo || !addrInfo.proxy) {
    throw new Error(`Unsupported chain id: ${chainId}`);
  }
  return new ethers.Contract(addrInfo.proxy, ABI, provider);
}

// GET /balance/:chainId/:account — returns the TUT balance for an account
app.get('/balance/:chainId/:account', async (req, res) => {
  try {
    const { chainId, account } = req.params;
    const contract = getContract(chainId);
    const balance = await contract.balanceOf(account);
    res.json({ balance: balance.toString() });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// POST /transfer — sends tokens from the signer to a recipient. The request
// body must include chainId, privateKey, to (address) and amount (string).
app.post('/transfer', async (req, res) => {
  const { chainId, privateKey, to, amount } = req.body;
  try {
    const wallet = new ethers.Wallet(privateKey, provider);
    const contract = getContract(chainId).connect(wallet);
    const decimals = await contract.decimals();
    const value = ethers.utils.parseUnits(amount, decimals);
    const tx = await contract.transfer(to, value);
    await tx.wait();
    res.json({ txHash: tx.hash });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// Health check
app.get('/', (req, res) => {
  res.json({ status: 'TUT API is running' });
});

// Start server
const PORT = process.env.PORT || 3000;
if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`TUT API listening on port ${PORT}`);
  });
}

module.exports = app;