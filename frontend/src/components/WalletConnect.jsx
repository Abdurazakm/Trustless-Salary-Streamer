/*
 * Team Task Guide
 * Owner: Member 5
 *
 * Implement in this file:
 * - Wallet connect/disconnect controls and account preview.
 * - Chain mismatch warning and switch-network action.
 * - Clear UI states: disconnected, connecting, connected, wrong network.
 */
import { formatAddress } from '../utils/contract'

export default function WalletConnect({ account, chainId, loading, error, onConnect, onDisconnect, onSwitchNetwork }) {
  const connected = Boolean(account)
  const wrongNetwork = chainId && chainId !== Number(import.meta.env.VITE_CHAIN_ID ?? 31337)

  return (
    <aside className="wallet-panel">
      <div>
        <p className="eyebrow">Wallet</p>
        <h2>{connected ? 'Connected' : 'Disconnected'}</h2>
        <p className="wallet-copy">{connected ? formatAddress(account) : 'Connect a wallet to manage or inspect streams.'}</p>
      </div>

      <div className="wallet-meta">
        <span>Chain {chainId ?? 'Unknown'}</span>
        <span>{wrongNetwork ? 'Wrong network' : 'Ready'}</span>
      </div>

      {error ? <p className="error-banner">{error}</p> : null}

      <div className="wallet-actions">
        {connected ? (
          <>
            {wrongNetwork ? (
              <button className="secondary-button" type="button" onClick={onSwitchNetwork} disabled={loading}>
                Switch network
              </button>
            ) : null}
            <button className="ghost-button" type="button" onClick={onDisconnect} disabled={loading}>
              Disconnect
            </button>
          </>
        ) : (
          <button className="primary-button" type="button" onClick={onConnect} disabled={loading}>
            {loading ? 'Connecting…' : 'Connect wallet'}
          </button>
        )}
      </div>
    </aside>
  )
}
