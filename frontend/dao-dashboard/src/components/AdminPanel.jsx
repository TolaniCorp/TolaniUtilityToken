import React, { useEffect, useMemo, useState } from 'react';
import { ethers } from 'ethers';
import ABI from '../abi/TUTToken.json';
import addresses from '../config/addresses.json';

/**
 * AdminPanel allows a connected admin to grant and revoke roles on the
 * TUT token contract. It fetches role identifiers from the contract
 * whenever possible to avoid hard coded keccak256 values. The UI
 * exposes inputs for the target address and role selector along with
 * actions to check, grant and revoke roles.
 */
export default function AdminPanel() {
  const [provider, setProvider] = useState(null);
  const [signer, setSigner] = useState(null);
  const [account, setAccount] = useState('');
  const [network, setNetwork] = useState(null);
  const [addr, setAddr] = useState('');
  const [roleKey, setRoleKey] = useState('MINTER_ROLE');
  const [roleMap, setRoleMap] = useState({});
  const [has, setHas] = useState(null);

  // Initialise provider
  useEffect(() => {
    if (typeof window !== 'undefined' && window.ethereum) {
      const p = new ethers.providers.Web3Provider(window.ethereum, 'any');
      setProvider(p);
      p.getNetwork().then(setNetwork);
    }
  }, []);

  // Derive contract address
  const contractAddress = useMemo(() => {
    const chainId = network?.chainId?.toString();
    return chainId && addresses[chainId]?.proxy ? addresses[chainId].proxy : undefined;
  }, [network]);

  // Memoise contract
  const contract = useMemo(() => {
    if (!provider || !contractAddress) return null;
    const base = signer ?? provider;
    return new ethers.Contract(contractAddress, ABI, base);
  }, [provider, signer, contractAddress]);

  // Connect admin wallet
  const connect = async () => {
    await provider.send('eth_requestAccounts', []);
    const s = provider.getSigner();
    setSigner(s);
    setAccount(await s.getAddress());
    setNetwork(await provider.getNetwork());
  };

  // Fetch role constants from contract or derive from keccak
  const readRoles = async () => {
    if (!contract) return;
    const keys = ['DEFAULT_ADMIN_ROLE', 'MINTER_ROLE', 'PAUSER_ROLE', 'UPGRADER_ROLE'];
    const entries = await Promise.all(
      keys.map(async (k) => {
        try {
          return [k, await contract[k]()] as [string, string];
        } catch {
          return [k, ethers.utils.keccak256(ethers.utils.toUtf8Bytes(k))] as [string, string];
        }
      })
    );
    setRoleMap(Object.fromEntries(entries));
  };

  // Check if address has a role
  const checkHasRole = async () => {
    if (!contract || !addr || !roleMap[roleKey]) return;
    try {
      const ok = await contract.hasRole(roleMap[roleKey], addr);
      setHas(Boolean(ok));
    } catch {
      setHas(null);
    }
  };

  // Grant a role
  const grant = async () => {
    if (!contract || !signer) return;
    if (!window.confirm(`Grant ${roleKey} to ${addr}?`)) return;
    const tx = await contract.grantRole(roleMap[roleKey], addr);
    await tx.wait();
    await checkHasRole();
    alert('Role granted.');
  };

  // Revoke a role
  const revoke = async () => {
    if (!contract || !signer) return;
    if (!window.confirm(`Revoke ${roleKey} from ${addr}?`)) return;
    const tx = await contract.revokeRole(roleMap[roleKey], addr);
    await tx.wait();
    await checkHasRole();
    alert('Role revoked.');
  };

  useEffect(() => {
    if (contract) readRoles();
  }, [contract]);

  return (
    <div style={{ border: '1px solid #ddd', padding: '1rem', borderRadius: '8px' }}>
      <h3>Admin Panel</h3>
      <button onClick={connect}>Connect Admin</button>
      {account && <div style={{ marginTop: '0.5rem' }}>Admin: {account}</div>}
      <div style={{ marginTop: '0.5rem' }}>
        <input
          placeholder="Target address"
          value={addr}
          onChange={(e) => setAddr(e.target.value)}
          style={{ marginRight: '0.5rem' }}
        />
        <select
          value={roleKey}
          onChange={(e) => setRoleKey(e.target.value)}
          style={{ marginRight: '0.5rem' }}
        >
          <option>MINTER_ROLE</option>
          <option>PAUSER_ROLE</option>
          <option>UPGRADER_ROLE</option>
          <option>DEFAULT_ADMIN_ROLE</option>
        </select>
        <button onClick={checkHasRole} style={{ marginRight: '0.5rem' }}>
          Check
        </button>
        {has !== null && (
          <span style={{ marginLeft: '0.5rem' }}>
            Has role: {has ? 'Yes' : 'No'}
          </span>
        )}
      </div>
      <div style={{ marginTop: '0.75rem' }}>
        <button onClick={grant} style={{ marginRight: '0.5rem' }}>
          Grant Role
        </button>
        <button onClick={revoke}>Revoke Role</button>
      </div>
    </div>
  );
}