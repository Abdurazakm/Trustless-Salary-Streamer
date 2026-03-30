/*
 * Team Task Guide
 * Owner: Member 5 (Frontend + Web3 Integration)
 *
 * Implement in this file:
 * - Wire global providers (routing, wallet context, and any data cache provider).
 * - Keep bootstrap setup minimal and deterministic.
 */
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './styles/globals.css'
import App from './App.jsx'

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
