/*
 * Team Task Guide
 * Owner: Member 5
 *
 * Implement in this file:
 * - App layout shell and route composition for dashboard/create/employer/worker views.
 * - Global fallback UI for loading and top-level error boundaries.
 */
import { useEffect, useState } from 'react'
import { useContract } from './hooks/useContract'
import { formatAddress, formatDuration, formatWei, paymentPeriodLabel, statusLabel } from './utils/contract'
import { classNames, percentOf } from './utils/helpers'
import './App.css'
import CreateStream from './pages/CreateStream'
import Dashboard from './pages/Dashboard'
import EmployerView from './pages/EmployerView'
import StreamCard from './components/StreamCard'
import WalletConnect from './components/WalletConnect'
import WorkerView from './pages/WorkerView'

export default function App() {
  const contract = useContract()
  const [selectedStream, setSelectedStream] = useState(null)

  useEffect(() => {
    void contract.refresh()
  }, [contract.refresh])

  useEffect(() => {
    if (!selectedStream && contract.streams.length > 0) {
      setSelectedStream(contract.streams[0])
    }
  }, [contract.streams, selectedStream])

  const connected = Boolean(contract.account)
  const employerStreams = contract.streams.filter((stream) => stream.employer === contract.account)
  const workerStreams = contract.streams.filter((stream) => stream.worker === contract.account)

  return (
    <main className="app-shell">
      <section className="hero-panel">
        <div className="hero-copy">
          <p className="eyebrow">Trustless Salary Streamer</p>
          <h1>Salary that releases itself, on-chain and on schedule.</h1>
          <p className="hero-text">
            Lock salary in a factory, stream it by time, and keep employers and workers aligned with transparent contract state.
          </p>
          <div className="hero-stats">
            <div>
              <span>{formatWei(contract.summary.earned)}</span>
              <small>Total earned</small>
            </div>
            <div>
              <span>{contract.summary.total}</span>
              <small>Streams tracked</small>
            </div>
            <div>
              <span>{connected ? 'Connected' : 'Offline'}</span>
              <small>{formatAddress(contract.account)}</small>
            </div>
          </div>
        </div>

        <WalletConnect
          account={contract.account}
          chainId={contract.chainId}
          loading={contract.loading}
          error={contract.error}
          onConnect={contract.connect}
          onDisconnect={contract.disconnect}
          onSwitchNetwork={contract.switchNetwork}
        />
      </section>

      <section className="content-grid">
        <Dashboard summary={contract.summary} loading={contract.loading} factoryAddress={contract.factoryAddress} />
        <CreateStream onCreateStream={contract.createStream} disabled={!connected} loading={contract.loading} />
      </section>

      <section className="streams-grid">
        <EmployerView
          streams={employerStreams}
          onStartWork={contract.startWork}
          onClawback={contract.clawback}
          connected={connected}
        />
        <WorkerView
          streams={workerStreams}
          onWithdraw={contract.withdraw}
          onCancel={contract.cancelIfNotStarted}
          connected={connected}
        />
      </section>

      <section className="list-panel">
        <div className="section-heading">
          <div>
            <p className="eyebrow">Registry</p>
            <h2>All known streams</h2>
          </div>
          <button className="ghost-button" type="button" onClick={contract.refresh} disabled={contract.loading}>
            Refresh
          </button>
        </div>

        {contract.streams.length === 0 ? (
          <div className="empty-state">
            <h3>No streams indexed yet</h3>
            <p>Deploy the factory, set `VITE_FACTORY_ADDRESS`, and create the first stream.</p>
          </div>
        ) : (
          <div className="stream-list">
            {contract.streams.map((stream) => (
              <button
                key={stream.stream}
                type="button"
                className={classNames('stream-list-item', selectedStream?.stream === stream.stream && 'is-selected')}
                onClick={() => setSelectedStream(stream)}
              >
                <span>{formatAddress(stream.stream)}</span>
                <small>
                  {paymentPeriodLabel(stream.paymentPeriod)} · {statusLabel(stream.status)} · {formatWei(stream.balance)}
                </small>
              </button>
            ))}
          </div>
        )}
      </section>

      {selectedStream ? (
        <section className="detail-panel">
          <div className="section-heading">
            <div>
              <p className="eyebrow">Selected stream</p>
              <h2>{formatAddress(selectedStream.stream)}</h2>
            </div>
            <span className={classNames('status-pill', `status-${selectedStream.statusLabel.toLowerCase()}`)}>
              {selectedStream.statusLabel}
            </span>
          </div>

          <StreamCard
            stream={selectedStream}
            onStartWork={contract.startWork}
            onWithdraw={contract.withdraw}
            onClawback={contract.clawback}
            onCancel={contract.cancelIfNotStarted}
          />

          <div className="detail-metrics">
            <div>
              <small>Earned</small>
              <strong>{formatWei(selectedStream.earned)}</strong>
            </div>
            <div>
              <small>Withdrawable</small>
              <strong>{formatWei(selectedStream.withdrawable)}</strong>
            </div>
            <div>
              <small>Withdrawn</small>
              <strong>{formatWei(selectedStream.withdrawn)}</strong>
            </div>
            <div>
              <small>Progress</small>
              <strong>{percentOf(Number(selectedStream.earned), Number(selectedStream.totalSalary))}</strong>
            </div>
            <div>
              <small>Duration</small>
              <strong>{formatDuration(selectedStream.totalDuration)}</strong>
            </div>
          </div>
        </section>
      ) : null}
    </main>
  )
}
