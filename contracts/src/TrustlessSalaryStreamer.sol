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

    
    event Withdrawn(
        address indexed worker,
        uint256 amount,
        uint256 totalWithdrawn
    );

    
    event Clawback(address indexed employer, uint256 amount);

   
    event ContractCancelled(address indexed worker, uint256 refund);

    // =========================================================================
    // MODIFIERS
    // =========================================================================

    
    modifier onlyEmployer() {
        require(
            msg.sender == employer,
            "SalaryStreamer: caller is not the employer"
        );
        _;
    }

   
    modifier onlyWorker() {
        require(
            msg.sender == worker,
            "SalaryStreamer: caller is not the worker"
        );
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
        require(
            msg.value > 0,
            "SalaryStreamer: salary must be greater than zero"
        );

        require(
            _totalDuration > 0,
            "SalaryStreamer: duration must be greater than zero"
        );

        require(
            _worker != address(0),
            "SalaryStreamer: worker cannot be zero address"
        );

        require(
            _worker != msg.sender,
            "SalaryStreamer: employer and worker cannot be the same address"
        );

        employer      = msg.sender;
        worker        = _worker;
        totalSalary   = msg.value;
        totalDuration = _totalDuration;
        paymentPeriod = _paymentPeriod;
        deployTime    = block.timestamp;

        status = StreamTypes.Status.PENDING;

        emit ContractFunded(
            employer,
            worker,
            totalSalary,
            totalDuration,
            paymentPeriod
        );
    }

    // =========================================================================
    // EXTERNAL GETTERS
    // =========================================================================

    function getEarned() external view returns (uint256) {
        return _calculateEarned();
    }

    function getWithdrawable() external view returns (uint256) {
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
