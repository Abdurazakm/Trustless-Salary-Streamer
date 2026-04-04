/*
 * Team Task Guide
 * Owner: Member 5
 *
 * Implement in this file:
 * - Employer-only stream management actions.
 * - Clawback controls with state-aware guardrails.
 * - Visibility of earned vs unearned funds per stream.
 */
import StreamCard from '../components/StreamCard'

export default function EmployerView({ streams, onStartWork, onClawback, connected }) {
  return (
    <section className="surface-panel">
      <div className="section-heading">
        <div>
          <p className="eyebrow">Employer</p>
          <h2>Manage employer-owned streams</h2>
        </div>
      </div>

      {connected ? null : <div className="empty-inline">Connect a wallet to see employer actions.</div>}

      {streams.length === 0 ? (
        <div className="empty-inline">No employer streams indexed for this account.</div>
      ) : (
        <div className="stack-list">
          {streams.map((stream) => (
            <StreamCard key={stream.stream} stream={stream} onStartWork={onStartWork} onClawback={onClawback} />
          ))}
        </div>
      )}
    </section>
  )
}
