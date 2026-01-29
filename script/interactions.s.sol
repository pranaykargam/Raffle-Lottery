// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
// import {console} from "forge-std/Console.sol";
// import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

// Local constant used only in this script
uint256 constant ETH_ANVIL_CHAIN_ID = 31337;

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config =
            helperConfig.getConfigChainId(block.chainid);

        address vrfCoordinator = config.vrfCoordinator;

        (uint256 subId,) = createSubscription(vrfCoordinator);
        return (subId, vrfCoordinator);
    }

    function createSubscription(address vrfCoordinator)
        public
        returns (uint256, address)
    {
        // console.log("Creating subscription on chainId:", block.chainid);

        vm.startBroadcast();
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();

        // console.log("Your subscription Id is:", subId);
        // console.log("Please update the subscriptionId in the HelperConfig.s.sol file");

        return (subId, vrfCoordinator);
    }

    function run() external returns (uint256, address) {
        return createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script {
    uint96 constant FUND_AMOUNT = 2 ether; // 2 LINK

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config =
            helperConfig.getConfigChainId(block.chainid);

        address vrfCoordinator = config.vrfCoordinator;
        uint256 subscriptionId = config.subscriptionId;
        address linkToken = config.link;

        if (subscriptionId == 0) {
            CreateSubscription createSub = new CreateSubscription();
            (uint256 updatedSubId, address updateVrFv2) =
                createSub.createSubscriptionUsingConfig();

            subscriptionId = updatedSubId;
            vrfCoordinator = updateVrFv2;
            // console.log("New SubId Created!", subscriptionId, "VRF Address:", vrfCoordinator);
        }

        fundSubscription(vrfCoordinator, subscriptionId, linkToken);
    }

    function fundSubscription(
        address vrfCoordinator,
        uint256 subscriptionId,
        address linkToken
    ) public {
        // console.log("Funding subscription:", subscriptionId);
        // console.log("Using vrfCoordinator:", vrfCoordinator);
        // console.log("On chainId:", block.chainid);

        if (block.chainid == ETH_ANVIL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            // console.log("LINK balance msg.sender:", LinkToken(linkToken).balanceOf(msg.sender));
            // console.log("msg.sender:", msg.sender);
            // console.log("LINK balance script:", LinkToken(linkToken).balanceOf(address(this)));
            // console.log("script address:", address(this));

            vm.startBroadcast();
            LinkToken(linkToken).transferAndCall(
                vrfCoordinator,
                FUND_AMOUNT,
                abi.encode(subscriptionId)
            );
            vm.stopBroadcast();
        }
    }

    function run() public {
        fundSubscriptionUsingConfig();
    }
}
