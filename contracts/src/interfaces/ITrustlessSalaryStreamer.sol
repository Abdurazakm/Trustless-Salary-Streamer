// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {StreamTypes} from "../libraries/StreamTypes.sol";

/*
 * Team Task Guide
 * Owner: Member 2 (Integration Contract Engineer)
 *
 * Implement in this file:
 * - Canonical external interface for TrustlessSalaryStreamer.
 * - Function signatures for lifecycle actions and read-only queries.
 * - Event declarations needed by frontend/indexers.
 * - Keep signatures synchronized with concrete contract implementation.
 */
interface ITrustlessSalaryStreamer {
    event ContractFunded(
        address indexed employer,
        address indexed worker,
        uint256 totalSalary,
        uint256 totalDuration,
        StreamTypes.PaymentPeriod paymentPeriod
    );

    event WorkStarted(uint256 startTime);

    event Withdrawn(
        address indexed worker,
        uint256 amount,
        uint256 totalWithdrawn
    );

    event Clawback(address indexed employer, uint256 amount);

    event ContractCancelled(address indexed worker, uint256 refund);

    function employer() external view returns (address);

    function worker() external view returns (address);

    function totalSalary() external view returns (uint256);

    function totalDuration() external view returns (uint256);

    function deployTime() external view returns (uint256);

    function workStartTime() external view returns (uint256);

    function lastClaimTime() external view returns (uint256);

    function amountWithdrawn() external view returns (uint256);

    function paymentPeriod() external view returns (StreamTypes.PaymentPeriod);

    function status() external view returns (StreamTypes.Status);

    function startWork() external;

    function clawback() external;

    function withdraw() external;

    function cancelIfNotStarted() external;

    function getEarned() external view returns (uint256);

    function getWithdrawable() external view returns (uint256);

    function timeUntilNextClaim() external view returns (uint256);

    function getContractBalance() external view returns (uint256);

    function getPeriodDuration() external view returns (uint256);
}
