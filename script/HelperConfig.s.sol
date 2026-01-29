// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";



abstract contract CodeConstants {
uint256 public constant ETH_SEPOLIA_CHAINID = 11155111;
uint256 public constant LOCAL_CHAINID = 33112;
/*VRF Mock Values */
uint96 public MOCK_BASE_FEE = 0.25 ether;
uint96 public MOCK_GAS_PRICE_LINK =1e9;
/*LINK/ ETH prices */
int256 public  MOCK_WEI_PER_UINT_LINK = 4e15;
}

contract HelperConfig is CodeConstants, Script {
    error  HelperConfig__InvalidchainId();
    struct NetworkConfig {
         uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
    }
    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId=> NetworkConfig) public networkConfig;

    constructor(){
        networkConfig[ETH_SEPOLIA_CHAINID] = getSepoliaEthConfig();
    }

    function getConfigChainId(uint256 chainId) public returns(NetworkConfig memory){
        if(networkConfig[chainId].vrfCoordinator != address(0)){
            return networkConfig[chainId];
        }else if (chainId == LOCAL_CHAINID){
            return getOrCreateAnvilEthConfig();
        }
        else{
            revert HelperConfig__InvalidchainId();
        }
    }
    function getSepoliaEthConfig()public pure returns(NetworkConfig memory){
       return NetworkConfig({
        entranceFee: 0.01 ether, //1e16 or 10000000000000000,
        interval: 30, // 30 seconds
        vrfCoordinator: 0x5CE8D5A2BC84beb22a398CCA51996F7930313D61,
        gasLane: 0x1770bdc7eec7771f7ba4ffd640f34260d7f095b79c92d34a5b2551d6f6cfd2be,
        subscriptionId: 3743, // update this value once you create subscription})
        callbackGasLimit: 5000000 // 500,000 gas
        });
        // return sepoliaConfig;
    }

   function  getOrCreateAnvilEthConfig()public returns (NetworkConfig memory){
    // check to see if we set an actuve Network config
    if (localNetworkConfig.vrfCoordinator != address(0)){
        return localNetworkConfig;
    }
    // Deploy mocks and such
    vm.startBroadcast();
   VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(
        MOCK_BASE_FEE,
        MOCK_GAS_PRICE_LINK,
        MOCK_WEI_PER_UINT_LINK);
    vm.stopBroadcast();

    localNetworkConfig = NetworkConfig({
        entranceFee: 0.01 ether,
        interval: 30,
        vrfCoordinator: address(vrfCoordinatorMock),
        // does not mater
        gasLane: 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15,
        callbackGasLimit: 500000,
        subscriptionId: 1
    });
    return localNetworkConfig;
   }
}





