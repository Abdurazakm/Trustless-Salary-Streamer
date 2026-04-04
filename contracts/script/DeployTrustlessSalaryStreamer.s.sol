// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {StreamFactory} from "../src/StreamFactory.sol";

/*
 * Team Task Guide
 * Owner: Member 6 (DevOps/Deployment)
 * Reviewer: Member 2
 *
 * Implement in this file:
 * - Read deploy config from environment variables.
 * - Deploy contracts in deterministic order and print addresses.
 * - Optionally run source verification and output frontend wiring hints.
 */
contract DeployTrustlessSalaryStreamer is Script {
    function run() external {
        uint256 deployerPrivateKey = _envUintWithFallback(
            "DEPLOYER_PRIVATE_KEY",
            "PRIVATE_KEY"
        );
        string memory rpcUrl = _envStringWithDefault(
            "RPC_URL",
            "SEPOLIA_RPC_URL",
            "http://127.0.0.1:8545"
        );
        string memory chainIdText = vm.envOr("CHAIN_ID", string("31337"));

        vm.startBroadcast(deployerPrivateKey);
        StreamFactory factory = new StreamFactory();
        vm.stopBroadcast();

        console2.log("StreamFactory deployed at:", address(factory));
        console2.log("RPC_URL:", rpcUrl);
        console2.log("CHAIN_ID:", chainIdText);
        console2.log("STREAM_FACTORY_ADDRESS=", address(factory));
        console2.log("VITE_FACTORY_ADDRESS=", address(factory));
        console2.log("VITE_RPC_URL=", rpcUrl);
        console2.log("VITE_CHAIN_ID=", chainIdText);
        console2.log("Next: set frontend env vars and run the Vite app.");
    }

    function _envUintWithFallback(
        string memory primaryName,
        string memory fallbackName
    ) internal view returns (uint256) {
        try vm.envUint(primaryName) returns (uint256 value) {
            return value;
        } catch {
            return vm.envUint(fallbackName);
        }
    }

    function _envStringWithDefault(
        string memory primaryName,
        string memory fallbackName,
        string memory defaultValue
    ) internal view returns (string memory) {
        try vm.envString(primaryName) returns (string memory value) {
            return value;
        } catch {
            try vm.envString(fallbackName) returns (string memory fallbackValue) {
                return fallbackValue;
            } catch {
                return defaultValue;
            }
        }
    }
}
