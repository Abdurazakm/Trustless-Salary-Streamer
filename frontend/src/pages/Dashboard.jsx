/*
 * Team Task Guide
 * Owner: Member 5
 *
 * Implement in this file:
 * - Aggregate all streams for connected account context.
 * - Show key metrics (active streams, total earned, total withdrawn).
 * - Include loading, empty, and error states.
 */
import { formatAddress, formatWei } from '../utils/contract'

export default function Dashboard({ summary, loading, factoryAddress }) {
  return (
    <section className="surface-panel">
      <div className="section-heading">
        <div>
          <p className="eyebrow">Dashboard</p>
          <h2>Protocol snapshot</h2>
        </div>
      </div>

      <div className="metric-grid">
        <div>
          <small>Total streams</small>
          <strong>{loading ? '…' : summary.total}</strong>
        </div>
        <div>
          <small>Active streams</small>
          <strong>{loading ? '…' : summary.active}</strong>
        </div>
        <div>
          <small>Total earned</small>
          <strong>{loading ? '…' : formatWei(summary.earned)}</strong>
        </div>
        <div>
          <small>Total withdrawn</small>
          <strong>{loading ? '…' : formatWei(summary.withdrawn)}</strong>
        </div>
      </div>

      <div className="detail-line">
        <span>Factory</span>
        <strong>{formatAddress(factoryAddress)}</strong>
      </div>
    </section>
  )
}
