// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/*
 * Team Task Guide
 * Owner: Member 1 (Core Streaming Logic) - Part 1
 * Owner: Member 2 (Employer & Worker Functions) - Parts 2 & 3
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
    // ENUMS (Part 1 - Member 1)
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
    // STATE VARIABLES (Part 1 - Member 1)
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
    // EVENTS (Part 1 - Member 1)
    // =========================================================================

    event ContractFunded(
        address indexed employer,
        address indexed worker,
        uint256 totalSalary,
        uint256 totalDuration,
        PaymentPeriod paymentPeriod
    );

    event WorkStarted(uint256 startTime);
    event Withdrawn(address indexed worker, uint256 amount, uint256 totalWithdrawn);
    event Clawback(address indexed employer, uint256 amount);
    event ContractCancelled(address indexed worker, uint256 refund);

    // =========================================================================
    // MODIFIERS (Part 1 - Member 1)
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
        require(status == Status.ACTIVE, "SalaryStreamer: contract is not active");
        _;
    }

    // =========================================================================
    // CONSTRUCTOR (Part 1 - Member 1)
    // =========================================================================

    constructor(
        address _worker,
        uint256 _totalDuration,
        PaymentPeriod _paymentPeriod
    ) payable {
        require(msg.value > 0, "SalaryStreamer: salary must be greater than zero");
        require(_totalDuration > 0, "SalaryStreamer: duration must be greater than zero");
        require(_worker != address(0), "SalaryStreamer: worker cannot be zero address");
        require(_worker != msg.sender, "SalaryStreamer: employer and worker cannot be the same address");

        employer = msg.sender;
        worker = _worker;
        totalSalary = msg.value;
        totalDuration = _totalDuration;
        paymentPeriod = _paymentPeriod;
        deployTime = block.timestamp;

        status = Status.PENDING;

        emit ContractFunded(employer, worker, totalSalary, totalDuration, paymentPeriod);
    }

    // =========================================================================
    // EMPLOYER FUNCTIONS (Part 2 - Member 2)
    // =========================================================================

    /**
     * @notice Employer starts the work period
     * @dev Can only be called once, transitions from PENDING to ACTIVE
     */
    function startWork() external onlyEmployer {
        require(status == Status.PENDING, "SalaryStreamer: work has already started or contract has ended");
        
        workStartTime = block.timestamp;
        lastClaimTime = block.timestamp;
        status = Status.ACTIVE;
        
        emit WorkStarted(block.timestamp);
    }

    /**
     * @notice Employer claws back unearned funds if contract ends early
     * @dev Only callable when ACTIVE, transfers unearned portion back to employer
     */
    function clawback() external onlyEmployer onlyActive {
        uint256 earned = getEarned();
        require(earned < totalSalary, "SalaryStreamer: no unearned funds available to clawback");
        
        uint256 unearned = totalSalary - earned;
        
        // Update state before transfer (CEI pattern)
        status = Status.ENDED;
        
        // Transfer unearned funds back to employer
        (bool success, ) = employer.call{value: unearned}("");
        require(success, "SalaryStreamer: clawback transfer failed");
        
        emit Clawback(employer, unearned);
    }

    // =========================================================================
    // WORKER FUNCTIONS (Part 3 - Member 2)
    // =========================================================================

    /**
     * @notice Worker withdraws earned salary for the current period
     * @dev Can only be called when ACTIVE, respects payment period schedule
     */
    function withdraw() external onlyWorker onlyActive {
        uint256 withdrawable = getWithdrawable();
        require(withdrawable > 0, "SalaryStreamer: no withdrawable funds available");
        
        // Update state before transfer (CEI pattern)
        amountWithdrawn += withdrawable;
        lastClaimTime = block.timestamp;
        
        // Check if fully withdrawn
        if (amountWithdrawn >= totalSalary) {
            status = Status.ENDED;
        }
        
        // Transfer to worker
        (bool success, ) = worker.call{value: withdrawable}("");
        require(success, "SalaryStreamer: withdraw transfer failed");
        
        emit Withdrawn(worker, withdrawable, amountWithdrawn);
    }

    /**
     * @notice Worker cancels contract if employer never started work
     * @dev Only callable after 7 days, only when PENDING
     */
    function cancelIfNotStarted() external onlyWorker {
        require(status == Status.PENDING, "SalaryStreamer: work has already started or contract has ended");
        require(block.timestamp >= deployTime + 7 days, "SalaryStreamer: must wait 7 days after deployment before cancelling");
        
        uint256 refundAmount = address(this).balance;
        
        // Update state before transfer (CEI pattern)
        status = Status.ENDED;
        
        // Transfer full balance back to employer
        (bool success, ) = employer.call{value: refundAmount}("");
        require(success, "SalaryStreamer: cancellation transfer failed");
        
        emit ContractCancelled(worker, refundAmount);
    }

    // =========================================================================
    // VIEW FUNCTIONS (Part 4 - To be added by Member 4)
    // =========================================================================

    /**
     * @notice Returns how much salary the worker has earned so far
     * @dev Based on linear time proportion, caps at totalSalary
     */
    function getEarned() public view returns (uint256) {
        if (status == Status.PENDING) {
            return 0;
        }
        
        if (status == Status.ENDED) {
            return amountWithdrawn;
        }
        
        // Status is ACTIVE
        uint256 timeElapsed = block.timestamp - workStartTime;
        if (timeElapsed >= totalDuration) {
            return totalSalary;
        }
        
        return (totalSalary * timeElapsed) / totalDuration;
    }

    /**
     * @notice Returns how much the worker can withdraw right now
     * @dev Based on last claim time and payment period
     */
    function getWithdrawable() public view returns (uint256) {
        if (status != Status.ACTIVE) {
            return 0;
        }
        
        uint256 earned = getEarned();
        if (earned <= amountWithdrawn) {
            return 0;
        }
        
        // Check if enough time has passed since last claim
        uint256 periodDuration = getPeriodDuration();
        if (block.timestamp < lastClaimTime + periodDuration) {
            return 0;
        }
        
        return earned - amountWithdrawn;
    }

    /**
     * @notice Returns seconds remaining until next claim
     */
    function timeUntilNextClaim() public view returns (uint256) {
        if (status != Status.ACTIVE) {
            return 0;
        }
        
        uint256 periodDuration = getPeriodDuration();
        uint256 nextClaimTime = lastClaimTime + periodDuration;
        
        if (block.timestamp >= nextClaimTime) {
            return 0;
        }
        
        return nextClaimTime - block.timestamp;
    }

    /**
     * @notice Returns the contract's current ETH balance
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Returns the duration of one payment period in seconds
     */
    function getPeriodDuration() public view returns (uint256) {
        if (paymentPeriod == PaymentPeriod.WEEKLY) {
            return 7 days;
        } else if (paymentPeriod == PaymentPeriod.BIWEEKLY) {
            return 14 days;
        } else {
            return 30 days;
        }
    }
}