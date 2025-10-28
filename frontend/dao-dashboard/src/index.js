import React from 'react';
import { createRoot } from 'react-dom/client';
import App from './App';

// Entry point for the DAO dashboard. This script looks for an element
// with id "root" in the HTML and mounts the React application there.
const container = document.getElementById('root');
const root = createRoot(container);
root.render(<React.StrictMode><App /></React.StrictMode>);