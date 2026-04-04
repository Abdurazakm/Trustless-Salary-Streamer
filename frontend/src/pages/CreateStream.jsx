/*
 * Team Task Guide
 * Owner: Member 5
 * Reviewer: Member 2
 *
 * Implement in this file:
 * - Create-stream form with validation for worker, duration, period, and funding.
 * - Unit conversions to on-chain values before write calls.
 * - Success and failure transaction feedback UX.
 */
import { useState } from 'react'
import { PERIOD_LABELS } from '../utils/contract'

const initialForm = {
  worker: '',
  totalDurationDays: '30',
  salaryEth: '1.0',
  paymentPeriod: '0',
}

export default function CreateStream({ onCreateStream, disabled, loading }) {
  const [form, setForm] = useState(initialForm)
  const [message, setMessage] = useState('')

  async function handleSubmit(event) {
    event.preventDefault()
    setMessage('')

    try {
      await onCreateStream({
        worker: form.worker.trim(),
        totalDurationDays: Number(form.totalDurationDays),
        salaryEth: form.salaryEth,
        paymentPeriod: Number(form.paymentPeriod),
      })
      setMessage('Stream created successfully.')
      setForm(initialForm)
    } catch (error) {
      setMessage(error instanceof Error ? error.message : 'Failed to create stream')
    }
  }

  return (
    <section className="surface-panel">
      <div className="section-heading">
        <div>
          <p className="eyebrow">Create stream</p>
          <h2>Lock salary for a new engagement</h2>
        </div>
      </div>

      <form className="form-grid" onSubmit={handleSubmit}>
        <label>
          <span>Worker address</span>
          <input
            type="text"
            value={form.worker}
            onChange={(event) => setForm({ ...form, worker: event.target.value })}
            placeholder="0x..."
            disabled={disabled || loading}
            required
          />
        </label>

        <label>
          <span>Duration (days)</span>
          <input
            type="number"
            min="1"
            value={form.totalDurationDays}
            onChange={(event) => setForm({ ...form, totalDurationDays: event.target.value })}
            disabled={disabled || loading}
            required
          />
        </label>

        <label>
          <span>Salary (ETH)</span>
          <input
            type="number"
            step="0.0001"
            min="0"
            value={form.salaryEth}
            onChange={(event) => setForm({ ...form, salaryEth: event.target.value })}
            disabled={disabled || loading}
            required
          />
        </label>

        <label>
          <span>Payment period</span>
          <select
            value={form.paymentPeriod}
            onChange={(event) => setForm({ ...form, paymentPeriod: event.target.value })}
            disabled={disabled || loading}
          >
            {PERIOD_LABELS.map((label, index) => (
              <option key={label} value={index}>
                {label}
              </option>
            ))}
          </select>
        </label>

        <button className="primary-button create-button" type="submit" disabled={disabled || loading}>
          {loading ? 'Working…' : 'Deploy stream'}
        </button>
      </form>

      {message ? <p className="helper-message">{message}</p> : null}
    </section>
  )
}
