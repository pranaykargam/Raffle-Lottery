// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription,AddConsumer} from "../script/interactions.s.sol";

contract DeployRaffle is Script {
    function run() public {
        deployContract();
    }

    function deployContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfigChainId(block.chainid);

        if (config.subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            (uint256 subscriptionId, ) = createSubscription.createSubscription(config.vrfCoordinator);
            config.subscriptionId = subscriptionId;
        }

        // fund it
        FundSubscription fundSubscription = new FundSubscription();
        fundSubscription.fundSubscriptionUsingConfig(config.vrfCoordinator, config.subscriptionId, config.link);

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );


        vm.stopBroadcast();

        // add consumer
        AddConsumer addConsumer = new AddConsumer();
        // dont need of Broadcast here 
        addConsumer.addConsumerUsingConfig(address(raffle), config.vrfCoordinator, config.subscriptionId);
        return (raffle, helperConfig);
    }
}
