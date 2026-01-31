// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";

import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

abstract contract CodeConstants {
    uint256 public constant ETH_SEPOLIA_CHAINID = 11155111;
    uint256 public constant ETH_ANVIL_CHAIN_ID = 31337;

    uint96 public constant MOCK_BASE_FEE = 0.25 ether;
    uint96 public constant MOCK_GAS_PRICE_LINK = 1e9;
    int256 public constant MOCK_WEI_PER_UNIT_LINK = 4e15;
}

contract HelperConfig is CodeConstants, Script {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
        address link;
    }

    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfig;

    constructor() {
        networkConfig[ETH_SEPOLIA_CHAINID] = getSepoliaEthConfig();
    }

    function getConfigChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (networkConfig[chainId].vrfCoordinator != address(0)) {
            NetworkConfig memory config = networkConfig[chainId];
            return config;
        } else if (chainId == ETH_ANVIL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCoordinator: 0x5CE8D5A2BC84beb22a398CCA51996F7930313D61,
            gasLane: 0x1770bdc7eec7771f7ba4ffd640f34260d7f095b79c92d34a5b2551d6f6cfd2be,
            subscriptionId: 13557940721780492232995911419241512491181819446548373209648180088534678505900, // my first subscriptionId 
            callbackGasLimit: 500000,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.vrfCoordinator != address(0)) {
            return localNetworkConfig;
        }

        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(
            MOCK_BASE_FEE,
            MOCK_GAS_PRICE_LINK,
            MOCK_WEI_PER_UNIT_LINK
        );
        LinkToken linkToken = new LinkToken();
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCoordinator: address(vrfCoordinatorMock),
            gasLane: 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15,
            subscriptionId: 0,
            callbackGasLimit: 500000,
            link: address(linkToken)
        });

        return localNetworkConfig;
    }
}
