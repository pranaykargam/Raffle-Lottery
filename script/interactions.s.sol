// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.19;
import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract CreateSubscription is Script{
    function CreateSubscriptionUsingConfig() external {
        // HelperConfig helperConfig = new HelperConfig();
        // HelperConfig.NetworkConfig memory activeNetworkConfig = helperConfig.getConfigChainId(block.chainid);
        // vm.startBroadcast();
        // Raffle raffle = new Raffle(
        //     activeNetworkConfig.entranceFee,
        //     activeNetworkConfig.interval,
        //     activeNetworkConfig.vrfCoordinator,
        //     activeNetworkConfig.gasLane,
        //     activeNetworkConfig.subscriptionId,
        //     activeNetworkConfig.callbackGasLimit
        // );
        // vm.stopBroadcast();
    }
    function run() external returns(Raffle, HelperConfig){
        // HelperConfig helperConfig = new HelperConfig();
        // HelperConfig.NetworkConfig memory activeNetworkConfig = helperConfig.getConfigChainId(block.chainid);
        // vm.startBroadcast();
        // Raffle raffle = new Raffle(
        //     activeNetworkConfig.entranceFee,
        //     activeNetworkConfig.interval,
        //     activeNetworkConfig.vrfCoordinator,
        //     activeNetworkConfig.gasLane,
        //     activeNetworkConfig.subscriptionId,
        //     activeNetworkConfig.callbackGasLimit
        // );
        // vm.stopBroadcast();
        // return (raffle,helperConfig);
    }

}