import React from 'react';
import TUTWallet from './components/TUTWallet';
import AdminPanel from './components/AdminPanel';

/**
 * Top level application component for the DAO dashboard. It renders the
 * wallet view and the admin panel one after the other separated by a
 * horizontal rule. Additional pages or routes could be added here in
 * future iterations.
 */
export default function App() {
  return (
    <main style={{ maxWidth: '800px', margin: '2rem auto', fontFamily: 'sans-serif' }}>
      <h1>TUT DAO Dashboard</h1>
      <TUTWallet />
      <hr style={{ margin: '2rem 0' }} />
      <AdminPanel />
    </main>
  );
}