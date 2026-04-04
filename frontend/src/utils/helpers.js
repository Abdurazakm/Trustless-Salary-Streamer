/*
 * Team Task Guide
 * Owner: Member 5
 *
 * Implement in this file:
 * - Formatting helpers for ETH values, timestamps, and durations.
 * - Safe parsing utilities for chain-returned numeric values.
 * - Reusable UI helper functions to reduce page-level duplication.
 */
export function classNames(...values) {
	return values.filter(Boolean).join(' ')
}

export function formatCompact(value) {
	const numeric = Number(value ?? 0)

	if (Number.isNaN(numeric)) {
		return '0'
	}

	if (numeric >= 1_000_000) {
		return `${(numeric / 1_000_000).toFixed(1)}M`
	}

	if (numeric >= 1_000) {
		return `${(numeric / 1_000).toFixed(1)}K`
	}

	return `${numeric}`
}

export function normalizeAddressInput(value) {
	return String(value ?? '').trim()
}

export function safeBigInt(value) {
	try {
		return BigInt(value ?? 0)
	} catch {
		return 0n
	}
}

export function percentOf(part, total) {
	const numerator = Number(part ?? 0)
	const denominator = Number(total ?? 0)

	if (!denominator) {
		return '0%'
	}

	return `${Math.min(100, Math.max(0, (numerator / denominator) * 100)).toFixed(1)}%`
}
