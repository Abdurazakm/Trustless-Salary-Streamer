/*
 * Team Task Guide
 * Owner: Member 2 + Member 5
 *
 * Implement in this file:
 * - Central ABI/address exports and contract config validation.
 * - Environment variable parsing for chain and factory address.
 * - Shared contract wiring utilities used by hooks and pages.
 */
import { defineChain, formatEther, getAddress, isAddress, parseEther } from 'viem'

export const DEFAULT_CHAIN_ID = Number(import.meta.env.VITE_CHAIN_ID ?? 31337)
export const DEFAULT_RPC_URL = import.meta.env.VITE_RPC_URL ?? 'http://127.0.0.1:8545'
export const FACTORY_ADDRESS =
	import.meta.env.VITE_FACTORY_ADDRESS ?? import.meta.env.VITE_STREAM_FACTORY_ADDRESS ?? ''

export const TRUSTLESS_STREAMER_ABI = [
	{
		type: 'function',
		name: 'employer',
		stateMutability: 'view',
		inputs: [],
		outputs: [{ type: 'address' }],
	},
	{
		type: 'function',
		name: 'worker',
		stateMutability: 'view',
		inputs: [],
		outputs: [{ type: 'address' }],
	},
	{
		type: 'function',
		name: 'totalSalary',
		stateMutability: 'view',
		inputs: [],
		outputs: [{ type: 'uint256' }],
	},
	{
		type: 'function',
		name: 'totalDuration',
		stateMutability: 'view',
		inputs: [],
		outputs: [{ type: 'uint256' }],
	},
	{
		type: 'function',
		name: 'deployTime',
		stateMutability: 'view',
		inputs: [],
		outputs: [{ type: 'uint256' }],
	},
	{
		type: 'function',
		name: 'workStartTime',
		stateMutability: 'view',
		inputs: [],
		outputs: [{ type: 'uint256' }],
	},
	{
		type: 'function',
		name: 'lastClaimTime',
		stateMutability: 'view',
		inputs: [],
		outputs: [{ type: 'uint256' }],
	},
	{
		type: 'function',
		name: 'amountWithdrawn',
		stateMutability: 'view',
		inputs: [],
		outputs: [{ type: 'uint256' }],
	},
	{
		type: 'function',
		name: 'paymentPeriod',
		stateMutability: 'view',
		inputs: [],
		outputs: [{ type: 'uint8' }],
	},
	{
		type: 'function',
		name: 'status',
		stateMutability: 'view',
		inputs: [],
		outputs: [{ type: 'uint8' }],
	},
	{
		type: 'function',
		name: 'startWork',
		stateMutability: 'nonpayable',
		inputs: [],
		outputs: [],
	},
	{
		type: 'function',
		name: 'clawback',
		stateMutability: 'nonpayable',
		inputs: [],
		outputs: [],
	},
	{
		type: 'function',
		name: 'withdraw',
		stateMutability: 'nonpayable',
		inputs: [],
		outputs: [],
	},
	{
		type: 'function',
		name: 'cancelIfNotStarted',
		stateMutability: 'nonpayable',
		inputs: [],
		outputs: [],
	},
	{
		type: 'function',
		name: 'getEarned',
		stateMutability: 'view',
		inputs: [],
		outputs: [{ type: 'uint256' }],
	},
	{
		type: 'function',
		name: 'getWithdrawable',
		stateMutability: 'view',
		inputs: [],
		outputs: [{ type: 'uint256' }],
	},
	{
		type: 'function',
		name: 'timeUntilNextClaim',
		stateMutability: 'view',
		inputs: [],
		outputs: [{ type: 'uint256' }],
	},
	{
		type: 'function',
		name: 'getContractBalance',
		stateMutability: 'view',
		inputs: [],
		outputs: [{ type: 'uint256' }],
	},
	{
		type: 'function',
		name: 'getPeriodDuration',
		stateMutability: 'view',
		inputs: [],
		outputs: [{ type: 'uint256' }],
	},
]

export const STREAM_FACTORY_ABI = [
	{
		type: 'function',
		name: 'createStream',
		stateMutability: 'payable',
		inputs: [
			{ name: 'worker', type: 'address' },
			{ name: 'totalDuration', type: 'uint256' },
			{ name: 'paymentPeriod', type: 'uint8' },
		],
		outputs: [{ name: 'streamAddress', type: 'address' }],
	},
	{
		type: 'function',
		name: 'getAllStreams',
		stateMutability: 'view',
		inputs: [],
		outputs: [{ type: 'address[]' }],
	},
	{
		type: 'function',
		name: 'getStreamsByEmployer',
		stateMutability: 'view',
		inputs: [{ name: 'employer', type: 'address' }],
		outputs: [{ type: 'address[]' }],
	},
	{
		type: 'function',
		name: 'getStreamsByWorker',
		stateMutability: 'view',
		inputs: [{ name: 'worker', type: 'address' }],
		outputs: [{ type: 'address[]' }],
	},
	{
		type: 'function',
		name: 'getStreamCount',
		stateMutability: 'view',
		inputs: [],
		outputs: [{ type: 'uint256' }],
	},
	{
		type: 'function',
		name: 'getEmployerStreamCount',
		stateMutability: 'view',
		inputs: [{ name: 'employer', type: 'address' }],
		outputs: [{ type: 'uint256' }],
	},
	{
		type: 'function',
		name: 'getWorkerStreamCount',
		stateMutability: 'view',
		inputs: [{ name: 'worker', type: 'address' }],
		outputs: [{ type: 'uint256' }],
	},
	{
		type: 'function',
		name: 'getStreamRecord',
		stateMutability: 'view',
		inputs: [{ name: 'stream', type: 'address' }],
		outputs: [
			{ name: 'stream', type: 'address' },
			{ name: 'employer', type: 'address' },
			{ name: 'worker', type: 'address' },
			{ name: 'totalSalary', type: 'uint256' },
			{ name: 'totalDuration', type: 'uint256' },
			{ name: 'paymentPeriod', type: 'uint8' },
			{ name: 'createdAt', type: 'uint256' },
		],
	},
]

export const PERIOD_LABELS = ['Weekly', 'Biweekly', 'Monthly']
export const STATUS_LABELS = ['Pending', 'Active', 'Ended']

export const LOCAL_CHAIN = defineChain({
	id: DEFAULT_CHAIN_ID,
	name: 'Local',
	nativeCurrency: { name: 'Ether', symbol: 'ETH', decimals: 18 },
	rpcUrls: { default: { http: [DEFAULT_RPC_URL] } },
})

export function getFactoryAddress() {
	return isAddress(FACTORY_ADDRESS) ? getAddress(FACTORY_ADDRESS) : ''
}

export function getConfiguredChainId() {
	return DEFAULT_CHAIN_ID
}

export function getRpcUrl() {
	return DEFAULT_RPC_URL
}

export function formatAddress(address) {
	if (!address || !isAddress(address)) {
		return 'Unavailable'
	}

	const checksummed = getAddress(address)
	return `${checksummed.slice(0, 6)}…${checksummed.slice(-4)}`
}

export function formatDuration(seconds) {
	const totalSeconds = Number(seconds ?? 0)

	if (totalSeconds >= 60 * 60 * 24) {
		const days = Math.round(totalSeconds / (60 * 60 * 24))
		return `${days}d`
	}

	if (totalSeconds >= 60 * 60) {
		const hours = Math.round(totalSeconds / (60 * 60))
		return `${hours}h`
	}

	if (totalSeconds >= 60) {
		const minutes = Math.round(totalSeconds / 60)
		return `${minutes}m`
	}

	return `${totalSeconds}s`
}

export function formatTimestamp(timestamp) {
	const value = Number(timestamp ?? 0)

	if (!value) {
		return 'Not started'
	}

	return new Date(value * 1000).toLocaleString()
}

export function formatWei(value) {
	const bigIntValue = typeof value === 'bigint' ? value : BigInt(value ?? 0)
	return `${Number.parseFloat(formatEther(bigIntValue)).toFixed(4)} ETH`
}

export function toWei(value) {
	return parseEther(String(value ?? '0'))
}

export function paymentPeriodLabel(index) {
	return PERIOD_LABELS[Number(index)] ?? 'Unknown'
}

export function statusLabel(index) {
	return STATUS_LABELS[Number(index)] ?? 'Unknown'
}

export function statusTone(status) {
	const tones = ['status-status-pending', 'status-status-active', 'status-status-ended']
	return tones[Number(status)] ?? tones[0]
}
