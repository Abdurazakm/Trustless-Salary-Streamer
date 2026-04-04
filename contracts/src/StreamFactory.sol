// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {StreamTypes} from "./libraries/StreamTypes.sol";
import {TrustlessSalaryStreamer} from "./TrustlessSalaryStreamer.sol";

/*
 * Team Task Guide
 * Owner: Member 2 (Factory + Integration)
 * Reviewer: Member 1
 *
 * Implement in this file:
 * - Stream creation with strict validation (worker != 0x0, duration > 0, funded salary).
 * - Registry mappings for employer and worker stream discovery.
 * - Events optimized for frontend indexing.
 * - Getter functions for pagination-friendly stream queries.
 */
contract StreamFactory {
    address[] private allStreams;

    mapping(address employer => address[] streams) private streamsByEmployer;
    mapping(address worker => address[] streams) private streamsByWorker;
    mapping(address stream => StreamTypes.StreamRecord record) private streamRecords;

    event StreamCreated(
        address indexed stream,
        address indexed employer,
        address indexed worker,
        uint256 totalSalary,
        uint256 totalDuration,
        StreamTypes.PaymentPeriod paymentPeriod,
        uint256 createdAt
    );

    function createStream(
        address worker,
        uint256 totalDuration,
        StreamTypes.PaymentPeriod paymentPeriod
    ) external payable returns (address streamAddress) {
        require(msg.value > 0, "StreamFactory: salary must be greater than zero");
        require(totalDuration > 0, "StreamFactory: duration must be greater than zero");
        require(worker != address(0), "StreamFactory: worker cannot be zero address");
        require(
            worker != msg.sender,
            "StreamFactory: employer and worker cannot be the same address"
        );

        TrustlessSalaryStreamer stream = new TrustlessSalaryStreamer{value: msg.value}(
            msg.sender,
            worker,
            totalDuration,
            paymentPeriod
        );

        streamAddress = address(stream);

        StreamTypes.StreamRecord memory record = StreamTypes.StreamRecord({
            stream: streamAddress,
            employer: msg.sender,
            worker: worker,
            totalSalary: msg.value,
            totalDuration: totalDuration,
            paymentPeriod: paymentPeriod,
            createdAt: block.timestamp
        });

        allStreams.push(streamAddress);
        streamsByEmployer[msg.sender].push(streamAddress);
        streamsByWorker[worker].push(streamAddress);
        streamRecords[streamAddress] = record;

        emit StreamCreated(
            streamAddress,
            msg.sender,
            worker,
            msg.value,
            totalDuration,
            paymentPeriod,
            block.timestamp
        );
    }

    function getAllStreams() external view returns (address[] memory) {
        return allStreams;
    }

    function getStreamsByEmployer(address employer)
        external
        view
        returns (address[] memory)
    {
        return streamsByEmployer[employer];
    }

    function getStreamsByWorker(address worker)
        external
        view
        returns (address[] memory)
    {
        return streamsByWorker[worker];
    }

    function getStreamCount() external view returns (uint256) {
        return allStreams.length;
    }

    function getEmployerStreamCount(address employer) external view returns (uint256) {
        return streamsByEmployer[employer].length;
    }

    function getWorkerStreamCount(address worker) external view returns (uint256) {
        return streamsByWorker[worker].length;
    }

    function getStreamRecord(address stream)
        external
        view
        returns (StreamTypes.StreamRecord memory)
    {
        StreamTypes.StreamRecord memory record = streamRecords[stream];
        require(record.stream != address(0), "StreamFactory: stream not found");
        return record;
    }
}
