/*
 * Team Task Guide
 * Owner: Member 5
 *
 * Implement in this file:
 * - Render stream summary (status, earned, withdrawn, withdrawable).
 * - Support employer and worker action variants.
 * - Show transaction pending/success/error states for action buttons.
 */
import { formatAddress, formatDuration, formatTimestamp, formatWei, paymentPeriodLabel, statusLabel } from '../utils/contract'
import { classNames, percentOf } from '../utils/helpers'

export default function StreamCard({ stream, onStartWork, onWithdraw, onClawback, onCancel }) {
  if (!stream) {
    return <div className="empty-inline">Select a stream to inspect it.</div>
  }

  const canStart = Number(stream.status) === 0 && typeof onStartWork === 'function'
  const canWithdraw = Number(stream.status) === 1 && typeof onWithdraw === 'function'
  const canClawback = Number(stream.status) === 1 && typeof onClawback === 'function'
  const canCancel = Number(stream.status) === 0 && typeof onCancel === 'function'

  return (
    <article className="stream-card">
      <div className="stream-card__header">
        <div>
          <p className="eyebrow">{paymentPeriodLabel(stream.paymentPeriod)}</p>
          <h3>{formatAddress(stream.stream)}</h3>
        </div>
        <span className={classNames('status-pill', `status-${statusLabel(stream.status).toLowerCase()}`)}>
          {statusLabel(stream.status)}
        </span>
      </div>

      <div className="stream-card__grid">
        <div>
          <small>Employer</small>
          <strong>{formatAddress(stream.employer)}</strong>
        </div>
        <div>
          <small>Worker</small>
          <strong>{formatAddress(stream.worker)}</strong>
        </div>
        <div>
          <small>Total salary</small>
          <strong>{formatWei(stream.totalSalary)}</strong>
        </div>
        <div>
          <small>Withdrawable</small>
          <strong>{formatWei(stream.withdrawable)}</strong>
        </div>
        <div>
          <small>Earned</small>
          <strong>{formatWei(stream.earned)}</strong>
        </div>
        <div>
          <small>Withdrawn</small>
          <strong>{formatWei(stream.withdrawn)}</strong>
        </div>
        <div>
          <small>Balance</small>
          <strong>{formatWei(stream.balance)}</strong>
        </div>
        <div>
          <small>Next claim</small>
          <strong>{formatDuration(stream.nextClaim)}</strong>
        </div>
        <div>
          <small>Created</small>
          <strong>{formatTimestamp(stream.createdAt)}</strong>
        </div>
        <div>
          <small>Progress</small>
          <strong>{percentOf(Number(stream.earned), Number(stream.totalSalary))}</strong>
        </div>
      </div>

      <div className="stream-card__actions">
        {canStart ? (
          <button className="primary-button" type="button" onClick={() => onStartWork(stream.stream)}>
            Start work
          </button>
        ) : null}
        {canWithdraw ? (
          <button className="primary-button" type="button" onClick={() => onWithdraw(stream.stream)}>
            Withdraw
          </button>
        ) : null}
        {canClawback ? (
          <button className="secondary-button" type="button" onClick={() => onClawback(stream.stream)}>
            Clawback
          </button>
        ) : null}
        {canCancel ? (
          <button className="secondary-button" type="button" onClick={() => onCancel(stream.stream)}>
            Cancel if not started
          </button>
        ) : null}
      </div>
    </article>
  )
}
