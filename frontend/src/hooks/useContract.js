/*
 * Team Task Guide
 * Owner: Member 5
 * Reviewer: Member 2
 *
 * Implement in this file:
 * - Build signer/provider-aware contract instances.
 * - Expose typed read/write helpers for salary stream actions.
 * - Normalize error mapping for frontend components.
 */
import { useCallback, useEffect, useMemo, useState } from 'react'
import {
	createPublicClient,
	createWalletClient,
	custom,
	http,
	isAddress,
	parseEther,
} from 'viem'
import {
	LOCAL_CHAIN,
	STREAM_FACTORY_ABI,
	TRUSTLESS_STREAMER_ABI,
	getConfiguredChainId,
	getFactoryAddress,
	getRpcUrl,
	paymentPeriodLabel,
	statusLabel,
} from '../utils/contract'

function normalizeError(error) {
	if (!error) {
		return 'Unknown error'
	}

	if (error instanceof Error) {
		return error.message
	}

	if (typeof error === 'string') {
		return error
	}

	return 'Transaction failed'
}

function toStreamRecord(record) {
	if (!record) {
		return null
	}

	const [stream, employer, worker, totalSalary, totalDuration, paymentPeriod, createdAt] = record

	return {
		stream,
		employer,
		worker,
		totalSalary,
		totalDuration,
		paymentPeriod,
		paymentPeriodLabel: paymentPeriodLabel(paymentPeriod),
		createdAt,
		status: 0,
		statusLabel: 'Pending',
	}
}

export function useContract() {
	const factoryAddress = getFactoryAddress()
	const [account, setAccount] = useState('')
	const [chainId, setChainId] = useState(getConfiguredChainId())
	const [error, setError] = useState('')
	const [loading, setLoading] = useState(false)
	const [streams, setStreams] = useState([])
	const [summary, setSummary] = useState({ total: 0, active: 0, earned: 0n, withdrawn: 0n })

	const publicClient = useMemo(
		() =>
			createPublicClient({
				chain: LOCAL_CHAIN,
				transport: http(getRpcUrl()),
			}),
		[],
	)

	useEffect(() => {
		if (!window.ethereum) {
			return undefined
		}

		const handleAccountsChanged = (accounts) => {
			setAccount(accounts?.[0] ?? '')
		}

		const handleChainChanged = (nextChainId) => {
			setChainId(Number.parseInt(nextChainId, 16))
		}

		window.ethereum.request({ method: 'eth_accounts' }).then((accounts) => {
			setAccount(accounts?.[0] ?? '')
		})

		window.ethereum.request({ method: 'eth_chainId' }).then((nextChainId) => {
			setChainId(Number.parseInt(nextChainId, 16))
		})

		window.ethereum.on('accountsChanged', handleAccountsChanged)
		window.ethereum.on('chainChanged', handleChainChanged)

		return () => {
			window.ethereum?.removeListener('accountsChanged', handleAccountsChanged)
			window.ethereum?.removeListener('chainChanged', handleChainChanged)
		}
	}, [])

	const getWalletClient = useCallback(async () => {
		if (!window.ethereum) {
			throw new Error('Wallet extension not detected')
		}

		return createWalletClient({
			chain: LOCAL_CHAIN,
			transport: custom(window.ethereum),
		})
	}, [])

	const connect = useCallback(async () => {
		if (!window.ethereum) {
			setError('Wallet extension not detected')
			return
		}

		try {
			setLoading(true)
			const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' })
			const nextChainId = await window.ethereum.request({ method: 'eth_chainId' })
			setAccount(accounts?.[0] ?? '')
			setChainId(Number.parseInt(nextChainId, 16))
			setError('')
		} catch (connectError) {
			setError(normalizeError(connectError))
		} finally {
			setLoading(false)
		}
	}, [])

	const disconnect = useCallback(() => {
		setAccount('')
		setError('')
	}, [])

	const switchNetwork = useCallback(async () => {
		if (!window.ethereum) {
			throw new Error('Wallet extension not detected')
		}

		await window.ethereum.request({
			method: 'wallet_switchEthereumChain',
			params: [{ chainId: `0x${getConfiguredChainId().toString(16)}` }],
		})
	}, [])

	const refresh = useCallback(async () => {
		if (!factoryAddress) {
			setStreams([])
			setSummary({ total: 0, active: 0, earned: 0n, withdrawn: 0n })
			return
		}

		try {
			setLoading(true)
			setError('')

			const streamAddresses = await publicClient.readContract({
				address: factoryAddress,
				abi: STREAM_FACTORY_ABI,
				functionName: 'getAllStreams',
			})

			const records = await Promise.all(
				streamAddresses.map(async (streamAddress) => {
					const record = await publicClient.readContract({
						address: factoryAddress,
						abi: STREAM_FACTORY_ABI,
						functionName: 'getStreamRecord',
						args: [streamAddress],
					})

					const status = await publicClient.readContract({
						address: streamAddress,
						abi: TRUSTLESS_STREAMER_ABI,
						functionName: 'status',
					})

					const earned = await publicClient.readContract({
						address: streamAddress,
						abi: TRUSTLESS_STREAMER_ABI,
						functionName: 'getEarned',
					})

					const withdrawn = await publicClient.readContract({
						address: streamAddress,
						abi: TRUSTLESS_STREAMER_ABI,
						functionName: 'amountWithdrawn',
					})

					const withdrawable = await publicClient.readContract({
						address: streamAddress,
						abi: TRUSTLESS_STREAMER_ABI,
						functionName: 'getWithdrawable',
					})

					const nextClaim = await publicClient.readContract({
						address: streamAddress,
						abi: TRUSTLESS_STREAMER_ABI,
						functionName: 'timeUntilNextClaim',
					})

					const balance = await publicClient.readContract({
						address: streamAddress,
						abi: TRUSTLESS_STREAMER_ABI,
						functionName: 'getContractBalance',
					})

					return {
						...toStreamRecord(record),
						status,
						statusLabel: statusLabel(status),
						earned,
						withdrawn,
						withdrawable,
						nextClaim,
						balance,
					}
				}),
			)

			setStreams(records)
			setSummary({
				total: records.length,
				active: records.filter((stream) => Number(stream.status) === 1).length,
				earned: records.reduce((accumulator, stream) => accumulator + BigInt(stream.earned ?? 0), 0n),
				withdrawn: records.reduce((accumulator, stream) => accumulator + BigInt(stream.withdrawn ?? 0), 0n),
			})
		} catch (refreshError) {
			setError(normalizeError(refreshError))
		} finally {
			setLoading(false)
		}
	}, [factoryAddress, publicClient])

	const createStream = useCallback(async ({ worker, totalDurationDays, paymentPeriod, salaryEth }) => {
		if (!factoryAddress) {
			throw new Error('Factory address is not configured')
		}

		if (!isAddress(worker)) {
			throw new Error('Worker address is invalid')
		}

		const walletClient = await getWalletClient()

		const hash = await walletClient.writeContract({
			address: factoryAddress,
			abi: STREAM_FACTORY_ABI,
			functionName: 'createStream',
			args: [worker, BigInt(Math.max(1, Number(totalDurationDays)) * 24 * 60 * 60), Number(paymentPeriod)],
			value: parseEther(String(salaryEth)),
		})

		await publicClient.waitForTransactionReceipt({ hash })
		await refresh()
	}, [account, factoryAddress, getWalletClient, publicClient, refresh])

	const writeStreamAction = useCallback(async (streamAddress, functionName) => {
		if (!isAddress(streamAddress)) {
			throw new Error('Stream address is invalid')
		}

		const walletClient = await getWalletClient()
		const hash = await walletClient.writeContract({
			address: streamAddress,
			abi: TRUSTLESS_STREAMER_ABI,
			functionName,
		})

		await publicClient.waitForTransactionReceipt({ hash })
		await refresh()
	}, [account, getWalletClient, publicClient, refresh])

	return {
		account,
		chainId,
		error,
		factoryAddress,
		loading,
		summary,
		streams,
		connect,
		disconnect,
		refresh,
		switchNetwork,
		createStream,
		startWork: (streamAddress) => writeStreamAction(streamAddress, 'startWork'),
		withdraw: (streamAddress) => writeStreamAction(streamAddress, 'withdraw'),
		clawback: (streamAddress) => writeStreamAction(streamAddress, 'clawback'),
		cancelIfNotStarted: (streamAddress) => writeStreamAction(streamAddress, 'cancelIfNotStarted'),
	}
}
