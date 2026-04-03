// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {StreamTypes} from "./libraries/StreamTypes.sol";

/*
 * Team Task Guide
 * Owner: Member 1 (Core Streaming Logic)
 * Reviewer: Member 3
 *
 * Implement in this file:
 * - Full lifecycle state machine: PENDING -> ACTIVE -> ENDED.
 * - startWork(), withdraw(), clawback(), cancelIfNotStarted() with role checks.
 * - Time-proportional earnings and withdrawable math.
 * - Checks-Effects-Interactions ordering before ETH transfers.
 * - Event emission for start, withdraw, clawback, and cancellation actions.
 */
contract TrustlessSalaryStreamer {
    // =========================================================================
    // STATE VARIABLES
    // =========================================================================

    address public employer;
    address public worker;
    uint256 public totalSalary;
    uint256 public totalDuration;
    uint256 public deployTime;
    uint256 public workStartTime;
    uint256 public lastClaimTime;
    uint256 public amountWithdrawn;
    StreamTypes.PaymentPeriod public paymentPeriod;
    StreamTypes.Status public status;

    // =========================================================================
    // EVENTS
    // =========================================================================

    event ContractFunded(
        address indexed employer,
        address indexed worker,
        uint256 totalSalary,
        uint256 totalDuration,
        StreamTypes.PaymentPeriod paymentPeriod
    );

    event WorkStarted(uint256 startTime);
    event Withdrawn(address indexed worker, uint256 amount, uint256 totalWithdrawn);
    event Clawback(address indexed employer, uint256 amount);
    event ContractCancelled(address indexed worker, uint256 refund);

    // =========================================================================
    // MODIFIERS
    // =========================================================================

    modifier onlyEmployer() {
        require(msg.sender == employer, "SalaryStreamer: caller is not the employer");
        _;
    }

    modifier onlyWorker() {
        require(msg.sender == worker, "SalaryStreamer: caller is not the worker");
        _;
    }

    modifier onlyActive() {
        require(
            status == StreamTypes.Status.ACTIVE,
            "SalaryStreamer: contract is not active"
        );
        _;
    }

    // =========================================================================
    // CONSTRUCTOR
    // =========================================================================

    constructor(
        address _worker,
        uint256 _totalDuration,
        StreamTypes.PaymentPeriod _paymentPeriod
    ) payable {
        require(msg.value > 0, "SalaryStreamer: salary must be greater than zero");
        require(_totalDuration > 0, "SalaryStreamer: duration must be greater than zero");
        require(_worker != address(0), "SalaryStreamer: worker cannot be zero address");
        require(
            _worker != msg.sender,
            "SalaryStreamer: employer and worker cannot be the same address"
        );

        employer = msg.sender;
        worker = _worker;
        totalSalary = msg.value;
        totalDuration = _totalDuration;
        paymentPeriod = _paymentPeriod;
        deployTime = block.timestamp;

        status = StreamTypes.Status.PENDING;

        emit ContractFunded(employer, worker, totalSalary, totalDuration, paymentPeriod);
    }

    // =========================================================================
    // EMPLOYER FUNCTIONS
    // =========================================================================

    function startWork() external onlyEmployer {
        require(
            status == StreamTypes.Status.PENDING,
            "SalaryStreamer: work has already started or contract has ended"
        );

        workStartTime = block.timestamp;
        lastClaimTime = block.timestamp;
        status = StreamTypes.Status.ACTIVE;

        emit WorkStarted(block.timestamp);
    }

    function clawback() external onlyEmployer onlyActive {
        uint256 earned = _calculateEarned();
        require(
            earned < totalSalary,
            "SalaryStreamer: no unearned funds available to clawback"
        );

        uint256 unearned = totalSalary - earned;

        status = StreamTypes.Status.ENDED;

        (bool success, ) = employer.call{value: unearned}("");
        require(success, "SalaryStreamer: clawback transfer failed");

        emit Clawback(employer, unearned);
    }

    // =========================================================================
    // WORKER FUNCTIONS
    // =========================================================================

    function withdraw() external onlyWorker onlyActive {
        uint256 withdrawable = getWithdrawable();
        require(withdrawable > 0, "SalaryStreamer: no withdrawable funds available");

        amountWithdrawn += withdrawable;
        lastClaimTime = block.timestamp;

        if (amountWithdrawn >= totalSalary) {
            status = StreamTypes.Status.ENDED;
        }

        (bool success, ) = worker.call{value: withdrawable}("");
        require(success, "SalaryStreamer: withdraw transfer failed");

        emit Withdrawn(worker, withdrawable, amountWithdrawn);
    }

    function cancelIfNotStarted() external onlyWorker {
        require(
            status == StreamTypes.Status.PENDING,
            "SalaryStreamer: work has already started or contract has ended"
        );
        require(
            block.timestamp >= deployTime + 7 days,
            "SalaryStreamer: must wait 7 days after deployment before cancelling"
        );

        uint256 refundAmount = address(this).balance;

        status = StreamTypes.Status.ENDED;

        (bool success, ) = employer.call{value: refundAmount}("");
        require(success, "SalaryStreamer: cancellation transfer failed");

        emit ContractCancelled(worker, refundAmount);
    }

    // =========================================================================
    // EXTERNAL GETTERS
    // =========================================================================

    function getEarned() public view returns (uint256) {
        return _calculateEarned();
    }

    function getWithdrawable() public view returns (uint256) {
        if (status != StreamTypes.Status.ACTIVE) {
            return 0;
        }

        uint256 periodDuration = _getPeriodDuration();
        if (block.timestamp < lastClaimTime + periodDuration) {
            return 0;
        }

        uint256 earned = _calculateEarned();
        if (earned <= amountWithdrawn) {
            return 0;
        }

        return earned - amountWithdrawn;
    }

    function timeUntilNextClaim() external view returns (uint256) {
        if (status != StreamTypes.Status.ACTIVE) {
            return 0;
        }

        uint256 periodDuration = _getPeriodDuration();
        uint256 nextClaimTime = lastClaimTime + periodDuration;

        if (block.timestamp >= nextClaimTime) {
            return 0;
        }

        return nextClaimTime - block.timestamp;
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getPeriodDuration() external view returns (uint256) {
        return _getPeriodDuration();
    }

    // =========================================================================
    // INTERNAL HELPERS
    // =========================================================================

    function _calculateEarned() internal view returns (uint256) {
        if (status == StreamTypes.Status.PENDING || workStartTime == 0) {
            return 0;
        }

        if (status == StreamTypes.Status.ENDED) {
            return amountWithdrawn;
        }

        uint256 elapsed = _elapsedWorkTime();
        return (totalSalary * elapsed) / totalDuration;
    }

    function _elapsedWorkTime() internal view returns (uint256) {
        if (workStartTime == 0) {
            return 0;
        }

        uint256 streamEndTime = workStartTime + totalDuration;
        uint256 effectiveTime = block.timestamp;

        if (effectiveTime > streamEndTime) {
            effectiveTime = streamEndTime;
        }

        if (effectiveTime <= workStartTime) {
            return 0;
        }

        return effectiveTime - workStartTime;
    }

    function _getPeriodDuration() internal view returns (uint256) {
        if (paymentPeriod == StreamTypes.PaymentPeriod.WEEKLY) {
            return 7 days;
        }

        if (paymentPeriod == StreamTypes.PaymentPeriod.BIWEEKLY) {
            return 14 days;
        }

        return 30 days;
    }
}
