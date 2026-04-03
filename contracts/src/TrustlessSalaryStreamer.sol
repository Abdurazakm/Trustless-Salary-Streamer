// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

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
    // ENUMS
    // =========================================================================

    
    enum PaymentPeriod {
        WEEKLY,    // Worker can claim every 7 days
        BIWEEKLY,  // Worker can claim every 14 days
        MONTHLY    // Worker can claim every 30 days
    }

    
    enum Status {
        PENDING,
        ACTIVE,
        ENDED
    }

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

    PaymentPeriod public paymentPeriod;

    Status public status;

    // =========================================================================
    // EVENTS
    // =========================================================================

    
    event ContractFunded(
        address indexed employer,
        address indexed worker,
        uint256 totalSalary,
        uint256 totalDuration,
        PaymentPeriod paymentPeriod
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
            status == Status.ACTIVE,
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
        PaymentPeriod _paymentPeriod
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

        status = Status.PENDING;

        emit ContractFunded(
            employer,
            worker,
            totalSalary,
            totalDuration,
            paymentPeriod
        );
    }
}
