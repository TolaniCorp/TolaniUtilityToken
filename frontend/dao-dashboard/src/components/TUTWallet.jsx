import React, { useEffect, useMemo, useState } from 'react';
import { ethers } from 'ethers';
import ABI from '../abi/TUTToken.json';
import addresses from '../config/addresses.json';
import { tutFormat, tutParse, TUT_DECIMALS } from '../lib/10_TUT_decimal_policy';

/**
 * TUTWallet is a React component that connects to the user's wallet and
 * displays their TUT balance. It also allows the user to send tokens to
 * another address. All amounts are formatted using the payments context
 * defined in the decimal policy.
 */
export default function TUTWallet() {
  const [provider, setProvider] = useState(null);
  const [signer, setSigner] = useState(null);
  const [account, setAccount] = useState('');
  const [network, setNetwork] = useState(null);
  const [symbol, setSymbol] = useState('TUT');
  const [decimals, setDecimals] = useState(TUT_DECIMALS);
  const [balanceBN, setBalanceBN] = useState(null);
  const [sendTo, setSendTo] = useState('');
  const [sendAmt, setSendAmt] = useState('');

  // Initialise the provider when the component mounts
  useEffect(() => {
    if (typeof window !== 'undefined' && window.ethereum) {
      const p = new ethers.providers.Web3Provider(window.ethereum, 'any');
      setProvider(p);
      p.getNetwork().then(setNetwork);
      // Keep account and network in sync when the user changes them
      window.ethereum.on('chainChanged', () => window.location.reload());
      window.ethereum.on('accountsChanged', async (a) => setAccount(a?.[0] ?? ''));
    }
  }, []);

  // Derive the contract address from chainId and addresses config
  const contractAddress = useMemo(() => {
    const chainId = network?.chainId?.toString();
    return chainId && addresses[chainId]?.proxy ? addresses[chainId].proxy : undefined;
  }, [network]);

  // Memoise contract instance to avoid re-instantiating unnecessarily
  const contract = useMemo(() => {
    if (!provider || !contractAddress) return null;
    const base = signer ?? provider;
    return new ethers.Contract(contractAddress, ABI, base);
  }, [provider, signer, contractAddress]);

  // Connect to MetaMask
  const connect = async () => {
    if (!provider) return;
    await provider.send('eth_requestAccounts', []);
    const s = provider.getSigner();
    setSigner(s);
    setAccount(await s.getAddress());
    setNetwork(await provider.getNetwork());
  };

  // Refresh balance and token metadata
  const refresh = async () => {
    if (!contract || !account) return;
    const [sym, dec] = await Promise.all([
      contract.symbol?.().catch(() => 'TUT'),
      contract.decimals?.().catch(() => TUT_DECIMALS),
    ]);
    setSymbol(sym);
    setDecimals(Number(dec));
    const bal = await contract.balanceOf(account);
    setBalanceBN(bal);
  };

  // Fetch balance when account or contract changes
  useEffect(() => {
    if (contract && account) refresh();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [contract, account]);

  // Send tokens using payments precision
  const send = async () => {
    if (!contract || !signer) return;
    const amt = tutParse(sendAmt, 'payments', decimals);
    const tx = await contract.transfer(sendTo, amt);
    await tx.wait();
    setSendAmt('');
    await refresh();
  };

  const balanceDisplay = balanceBN ? tutFormat(balanceBN, 'payments', decimals) : '';

  return (
    <div style={{ border: '1px solid #ddd', padding: '1rem', borderRadius: '8px' }}>
      <h3>Wallet</h3>
      <button onClick={connect}>Connect Wallet</button>
      {account && <div style={{ marginTop: '0.5rem' }}>Connected: {account}</div>}
      {network && (
        <div style={{ marginTop: '0.25rem' }}>
          Network: {network.name} (chainId: {network.chainId})
        </div>
      )}
      {contractAddress && (
        <div style={{ marginTop: '0.25rem' }}>Proxy: {contractAddress}</div>
      )}
      {balanceDisplay && (
        <div style={{ marginTop: '0.25rem' }}>
          {symbol} Balance: {balanceDisplay}
        </div>
      )}
      <div style={{ marginTop: '1rem' }}>
        <h4>Send TUT</h4>
        <input
          placeholder="0.00"
          value={sendAmt}
          onChange={(e) => setSendAmt(e.target.value)}
          style={{ marginRight: '0.5rem' }}
        />
        <input
          placeholder="0xRecipient…"
          value={sendTo}
          onChange={(e) => setSendTo(e.target.value)}
          style={{ marginRight: '0.5rem' }}
        />
        <button onClick={send}>Send {symbol}</button>
      </div>
    </div>
  );
}