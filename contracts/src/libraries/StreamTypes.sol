// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/*
 * Team Task Guide
 * Owner: Member 2 (Factory + Integration)
 *
 * Implement in this file:
 * - Shared enums for stream status and payment frequency.
 * - Shared structs for stream creation params and stream metadata.
 * - Types that reduce duplication between factory, contract, tests, and frontend.
 */
library StreamTypes {
    /**
     * @notice Defines the agreed payment frequency for a salary stream.
     */
    enum PaymentPeriod {
        WEEKLY,
        BIWEEKLY,
        MONTHLY
    }

    /**
     * @notice Tracks lifecycle progression for an individual stream.
     */
    enum Status {
        PENDING,
        ACTIVE,
        ENDED
    }

    /**
     * @notice Factory-level metadata used by the app/indexers.
     */
    struct StreamRecord {
        address stream;
        address employer;
        address worker;
        uint256 totalSalary;
        uint256 totalDuration;
        PaymentPeriod paymentPeriod;
        uint256 createdAt;
    }
}
