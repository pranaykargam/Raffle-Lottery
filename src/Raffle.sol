// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions
//lib/chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// For your Raffle.sol

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {IVRFCoordinatorV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";

// For mocks in scripts/tests
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";

/**
 * @title Raffle Lottery
 * @author sunny
 * @notice This contract is for creating a sample raffle lottery.
 * @dev It implements Chainlink VRF v2 (written lesson)
 */
contract Raffle is VRFConsumerBaseV2Plus {
    /**
     * Errors
     */
    error NotEnoughEth();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    /**
     * Events
     */
    event RaffleEntered(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);


    function getLastTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    /**
     * Enum & state (type declaration)
     */
    enum RaffleState {
        OPEN, //0
        CALCULATING //1
                     //2
    }
    RaffleState private s_raffleState;

    // Raffle variables
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval; // duration in seconds
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address payable private s_recentWinner;

    bytes32 private immutable s_gasLane;
    uint256 private immutable s_subscriptionId;
    uint32 private immutable s_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;

        // s_vrfCoordinator = IVRFCoordinatorV2Plus(vrfCoordinator);
        s_gasLane = gasLane;
        s_subscriptionId = subscriptionId;
        s_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert NotEnoughEth();
        }
        if (s_raffleState != RaffleState.OPEN){
            revert Raffle__RaffleNotOpen();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    
  
    // 3. Automatically called (later via Automation)
    function pickWinner() external {
        if (block.timestamp - s_lastTimeStamp < i_interval) {
            revert();
        }

        s_raffleState = RaffleState.CALCULATING;

        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: s_gasLane,
                subId: s_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: s_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
            })
        );

        emit RequestedRaffleWinner(requestId);
    }

// CEI - Checks,Effects,Intraction
function fulfillRandomWords(
    // Checks


    // Effect (Internal Contract State)
    uint256 /* requestId */, 
    uint256[] calldata randomWords
) internal override {
    uint256 indexOfWinner = randomWords[0] % s_players.length;
    address payable winner = s_players[indexOfWinner];
    s_recentWinner = winner;
    s_raffleState = RaffleState.OPEN;
    s_players = new address payable[](0);
    s_lastTimeStamp = block.timestamp;
    emit WinnerPicked(s_recentWinner);

    // Interactions (External Contracts Interactions)


    (bool success,) = winner.call{value: address(this).balance}("");
    if (!success) {
        revert Raffle__TransferFailed();
    }

}


    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
 
}
