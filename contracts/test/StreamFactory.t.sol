// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {StreamFactory} from "../src/StreamFactory.sol";
import {ITrustlessSalaryStreamer} from "../src/interfaces/ITrustlessSalaryStreamer.sol";
import {StreamTypes} from "../src/libraries/StreamTypes.sol";

/*
 * Team Task Guide
 * Owner: Member 4 (Testing/QA)
 * Reviewer: Member 2
 *
 * Implement in this file:
 * - Test valid stream creation and expected emitted events.
 * - Test revert paths for invalid worker/duration/funding input.
 * - Test registry consistency for multiple employers and workers.
 */
contract StreamFactoryTest is Test {
    event StreamCreated(
        address indexed stream,
        address indexed employer,
        address indexed worker,
        uint256 totalSalary,
        uint256 totalDuration,
        StreamTypes.PaymentPeriod paymentPeriod,
        uint256 createdAt
    );

    StreamFactory internal factory;
    address internal employerA = makeAddr("employerA");
    address internal employerB = makeAddr("employerB");
    address internal workerA = makeAddr("workerA");
    address internal workerB = makeAddr("workerB");

    function setUp() public {
        factory = new StreamFactory();
        vm.deal(employerA, 100 ether);
        vm.deal(employerB, 100 ether);
    }

    function testCreateStreamDeploysAndIndexes() public {
        uint256 salary = 5 ether;
        uint256 duration = 30 days;

        vm.prank(employerA);
        address streamAddress = factory.createStream{value: salary}(
            workerA,
            duration,
            StreamTypes.PaymentPeriod.WEEKLY
        );

        ITrustlessSalaryStreamer stream = ITrustlessSalaryStreamer(streamAddress);

        assertEq(stream.employer(), employerA);
        assertEq(stream.worker(), workerA);
        assertEq(stream.totalSalary(), salary);
        assertEq(stream.totalDuration(), duration);
        assertEq(uint256(stream.status()), uint256(StreamTypes.Status.PENDING));

        assertEq(factory.getStreamCount(), 1);
        assertEq(factory.getEmployerStreamCount(employerA), 1);
        assertEq(factory.getWorkerStreamCount(workerA), 1);

        address[] memory all = factory.getAllStreams();
        assertEq(all.length, 1);
        assertEq(all[0], streamAddress);
    }

    function testCreateStreamEmitsEvent() public {
        uint256 salary = 1 ether;
        uint256 duration = 14 days;

        vm.expectEmit(false, true, true, true);
        emit StreamCreated(
            address(0),
            employerA,
            workerA,
            salary,
            duration,
            StreamTypes.PaymentPeriod.BIWEEKLY,
            block.timestamp
        );

        vm.prank(employerA);
        factory.createStream{value: salary}(
            workerA,
            duration,
            StreamTypes.PaymentPeriod.BIWEEKLY
        );
    }

    function testCreateStreamRevertsOnZeroSalary() public {
        vm.expectRevert("StreamFactory: salary must be greater than zero");
        vm.prank(employerA);
        factory.createStream{value: 0}(
            workerA,
            30 days,
            StreamTypes.PaymentPeriod.WEEKLY
        );
    }

    function testCreateStreamRevertsOnZeroDuration() public {
        vm.expectRevert("StreamFactory: duration must be greater than zero");
        vm.prank(employerA);
        factory.createStream{value: 1 ether}(
            workerA,
            0,
            StreamTypes.PaymentPeriod.WEEKLY
        );
    }

    function testCreateStreamRevertsOnZeroWorker() public {
        vm.expectRevert("StreamFactory: worker cannot be zero address");
        vm.prank(employerA);
        factory.createStream{value: 1 ether}(
            address(0),
            30 days,
            StreamTypes.PaymentPeriod.WEEKLY
        );
    }

    function testCreateStreamRevertsWhenWorkerEqualsEmployer() public {
        vm.expectRevert("StreamFactory: employer and worker cannot be the same address");
        vm.prank(employerA);
        factory.createStream{value: 1 ether}(
            employerA,
            30 days,
            StreamTypes.PaymentPeriod.WEEKLY
        );
    }

    function testRegistryConsistencyAcrossEmployersAndWorkers() public {
        vm.prank(employerA);
        address s1 = factory.createStream{value: 1 ether}(
            workerA,
            30 days,
            StreamTypes.PaymentPeriod.WEEKLY
        );

        vm.prank(employerA);
        address s2 = factory.createStream{value: 2 ether}(
            workerB,
            60 days,
            StreamTypes.PaymentPeriod.MONTHLY
        );

        vm.prank(employerB);
        address s3 = factory.createStream{value: 3 ether}(
            workerA,
            45 days,
            StreamTypes.PaymentPeriod.BIWEEKLY
        );

        assertEq(factory.getStreamCount(), 3);
        assertEq(factory.getEmployerStreamCount(employerA), 2);
        assertEq(factory.getEmployerStreamCount(employerB), 1);
        assertEq(factory.getWorkerStreamCount(workerA), 2);
        assertEq(factory.getWorkerStreamCount(workerB), 1);

        address[] memory employerAStreams = factory.getStreamsByEmployer(employerA);
        address[] memory workerAStreams = factory.getStreamsByWorker(workerA);

        assertEq(employerAStreams.length, 2);
        assertEq(employerAStreams[0], s1);
        assertEq(employerAStreams[1], s2);

        assertEq(workerAStreams.length, 2);
        assertEq(workerAStreams[0], s1);
        assertEq(workerAStreams[1], s3);

        StreamTypes.StreamRecord memory record = factory.getStreamRecord(s2);
        assertEq(record.stream, s2);
        assertEq(record.employer, employerA);
        assertEq(record.worker, workerB);
        assertEq(record.totalSalary, 2 ether);
        assertEq(record.totalDuration, 60 days);
        assertEq(uint256(record.paymentPeriod), uint256(StreamTypes.PaymentPeriod.MONTHLY));
    }

    function testGetStreamRecordRevertsForUnknownStream() public {
        vm.expectRevert("StreamFactory: stream not found");
        factory.getStreamRecord(makeAddr("unknown"));
    }
}
