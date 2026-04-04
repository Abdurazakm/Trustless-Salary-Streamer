// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {TrustlessSalaryStreamer} from "../src/TrustlessSalaryStreamer.sol";
import {StreamTypes} from "../src/libraries/StreamTypes.sol";

/*
 * Team Task Guide
 * Owner: Member 4 (Testing/QA)
 * Reviewer: Member 3
 *
 * Implement in this file:
 * - Full lifecycle tests: pending, active, ended.
 * - Withdrawal timing tests for weekly/biweekly/monthly rules.
 * - Clawback and cancel-if-not-started edge-case tests.
 * - Fuzz tests for earned and withdrawable amount correctness.
 */
contract TrustlessSalaryStreamerTest is Test {
    address internal employer = makeAddr("employer");
    address internal worker = makeAddr("worker");

    uint256 internal constant TOTAL_SALARY = 10 ether;
    uint256 internal constant TOTAL_DURATION = 100 days;

    TrustlessSalaryStreamer internal stream;

    function setUp() public {
        vm.deal(employer, 100 ether);
        vm.deal(worker, 0);

        stream = _deployStream(worker, TOTAL_DURATION, TOTAL_SALARY, StreamTypes.PaymentPeriod.WEEKLY);
    }

    function testConstructorInitializesState() public view {
        assertEq(stream.employer(), employer);
        assertEq(stream.worker(), worker);
        assertEq(stream.totalSalary(), TOTAL_SALARY);
        assertEq(stream.totalDuration(), TOTAL_DURATION);
        assertEq(uint256(stream.paymentPeriod()), uint256(StreamTypes.PaymentPeriod.WEEKLY));
        assertEq(uint256(stream.status()), uint256(StreamTypes.Status.PENDING));
    }

    function testConstructorRevertsOnZeroSalary() public {
        vm.expectRevert("SalaryStreamer: salary must be greater than zero");
        vm.prank(employer);
        new TrustlessSalaryStreamer{value: 0}(
            employer,
            worker,
            TOTAL_DURATION,
            StreamTypes.PaymentPeriod.WEEKLY
        );
    }

    function testConstructorRevertsOnZeroDuration() public {
        vm.expectRevert("SalaryStreamer: duration must be greater than zero");
        vm.prank(employer);
        new TrustlessSalaryStreamer{value: TOTAL_SALARY}(
            employer,
            worker,
            0,
            StreamTypes.PaymentPeriod.WEEKLY
        );
    }

    function testConstructorRevertsOnZeroWorker() public {
        vm.expectRevert("SalaryStreamer: worker cannot be zero address");
        vm.prank(employer);
        new TrustlessSalaryStreamer{value: TOTAL_SALARY}(
            employer,
            address(0),
            TOTAL_DURATION,
            StreamTypes.PaymentPeriod.WEEKLY
        );
    }

    function testConstructorRevertsWhenWorkerEqualsEmployer() public {
        vm.expectRevert("SalaryStreamer: employer and worker cannot be the same address");
        vm.prank(employer);
        new TrustlessSalaryStreamer{value: TOTAL_SALARY}(
            employer,
            employer,
            TOTAL_DURATION,
            StreamTypes.PaymentPeriod.WEEKLY
        );
    }

    function testOnlyEmployerCanStartWork() public {
        vm.expectRevert("SalaryStreamer: caller is not the employer");
        vm.prank(worker);
        stream.startWork();
    }

    function testStartWorkTransitionsToActive() public {
        vm.prank(employer);
        stream.startWork();

        assertEq(uint256(stream.status()), uint256(StreamTypes.Status.ACTIVE));
        assertEq(stream.workStartTime(), block.timestamp);
        assertEq(stream.lastClaimTime(), block.timestamp);
    }

    function testCannotWithdrawBeforeStart() public {
        vm.expectRevert("SalaryStreamer: contract is not active");
        vm.prank(worker);
        stream.withdraw();
    }

    function testWithdrawRespectsWeeklyTiming() public {
        vm.prank(employer);
        stream.startWork();

        vm.warp(block.timestamp + 6 days);
        vm.expectRevert("SalaryStreamer: no withdrawable funds available");
        vm.prank(worker);
        stream.withdraw();

        vm.warp(block.timestamp + 1 days);

        uint256 expected = (TOTAL_SALARY * 7 days) / TOTAL_DURATION;
        uint256 workerBalanceBefore = worker.balance;

        vm.prank(worker);
        stream.withdraw();

        assertEq(worker.balance - workerBalanceBefore, expected);
        assertEq(stream.amountWithdrawn(), expected);
    }

    function testCannotDoubleClaimInSamePeriod() public {
        vm.prank(employer);
        stream.startWork();

        vm.warp(block.timestamp + 7 days);
        vm.prank(worker);
        stream.withdraw();

        vm.expectRevert("SalaryStreamer: no withdrawable funds available");
        vm.prank(worker);
        stream.withdraw();
    }

    function testClawbackPaysWorkerEarnedAndEmployerUnearned() public {
        vm.prank(employer);
        stream.startWork();

        vm.warp(block.timestamp + 10 days);

        uint256 earned = stream.getEarned();
        uint256 unearned = TOTAL_SALARY - earned;
        uint256 workerBalanceBefore = worker.balance;
        uint256 employerBalanceBefore = employer.balance;

        vm.prank(employer);
        stream.clawback();

        assertEq(uint256(stream.status()), uint256(StreamTypes.Status.ENDED));
        assertEq(stream.amountWithdrawn(), earned);
        assertEq(worker.balance - workerBalanceBefore, earned);
        assertEq(employer.balance - employerBalanceBefore, unearned);
        assertEq(address(stream).balance, 0);
    }

    function testCancelIfNotStartedAfterSevenDays() public {
        uint256 employerBalanceBefore = employer.balance;

        vm.warp(block.timestamp + 7 days);
        vm.prank(worker);
        stream.cancelIfNotStarted();

        assertEq(uint256(stream.status()), uint256(StreamTypes.Status.ENDED));
        assertEq(employer.balance - employerBalanceBefore, TOTAL_SALARY);
        assertEq(address(stream).balance, 0);
    }

    function testCancelIfNotStartedRevertsBeforeSevenDays() public {
        vm.warp(block.timestamp + 6 days);
        vm.expectRevert("SalaryStreamer: must wait 7 days after deployment before cancelling");
        vm.prank(worker);
        stream.cancelIfNotStarted();
    }

    function testPeriodDurationMapping() public {
        TrustlessSalaryStreamer weekly = _deployStream(
            worker,
            TOTAL_DURATION,
            TOTAL_SALARY,
            StreamTypes.PaymentPeriod.WEEKLY
        );

        TrustlessSalaryStreamer biweekly = _deployStream(
            worker,
            TOTAL_DURATION,
            TOTAL_SALARY,
            StreamTypes.PaymentPeriod.BIWEEKLY
        );

        TrustlessSalaryStreamer monthly = _deployStream(
            worker,
            TOTAL_DURATION,
            TOTAL_SALARY,
            StreamTypes.PaymentPeriod.MONTHLY
        );

        assertEq(weekly.getPeriodDuration(), 7 days);
        assertEq(biweekly.getPeriodDuration(), 14 days);
        assertEq(monthly.getPeriodDuration(), 30 days);
    }

    function testFuzzEarnedMonotonicAndCapped(uint256 t1, uint256 t2) public {
        vm.prank(employer);
        stream.startWork();

        t1 = bound(t1, 0, TOTAL_DURATION + 30 days);
        t2 = bound(t2, t1, TOTAL_DURATION + 30 days);

        vm.warp(stream.workStartTime() + t1);
        uint256 earned1 = stream.getEarned();

        vm.warp(stream.workStartTime() + t2);
        uint256 earned2 = stream.getEarned();

        assertLe(earned1, earned2);
        assertLe(earned2, TOTAL_SALARY);
    }

    function _deployStream(
        address streamWorker,
        uint256 duration,
        uint256 salary,
        StreamTypes.PaymentPeriod period
    ) internal returns (TrustlessSalaryStreamer deployed) {
        vm.prank(employer);
        deployed = new TrustlessSalaryStreamer{value: salary}(
            employer,
            streamWorker,
            duration,
            period
        );
    }
}
