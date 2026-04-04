/*
 * Team Task Guide
 * Owner: Member 5
 *
 * Implement in this file:
 * - Worker withdrawal flow with timing eligibility checks.
 * - Earned/withdrawable breakdown and next withdrawal window display.
 * - Transaction status and retry-safe UX for withdraw actions.
 */
import StreamCard from '../components/StreamCard'

export default function WorkerView({ streams, onWithdraw, onCancel, connected }) {
  return (
    <section className="surface-panel">
      <div className="section-heading">
        <div>
          <p className="eyebrow">Worker</p>
          <h2>Worker earnings and escape hatch</h2>
        </div>
      </div>

      {connected ? null : <div className="empty-inline">Connect a wallet to see worker actions.</div>}

      {streams.length === 0 ? (
        <div className="empty-inline">No worker streams indexed for this account.</div>
      ) : (
        <div className="stack-list">
          {streams.map((stream) => (
            <StreamCard key={stream.stream} stream={stream} onWithdraw={onWithdraw} onCancel={onCancel} />
          ))}
        </div>
      )}
    </section>
  )
}
