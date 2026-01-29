

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// For your Raffle.sol
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {IVRFCoordinatorV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";
/**
 * @title Raffle Lottery
 * @author sunny
 * @notice This contract is for creating a sample raffle lottery.
 * @dev It implements Chainlink VRF v2.5 (Plus) with Automation-style upkeep.
 */
contract Raffle is VRFConsumerBaseV2Plus {
    /*//////////////////////////////////////////////////////////////
                               Errors
    //////////////////////////////////////////////////////////////*/
    error NotEnoughEth();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(
        uint256 balance,
        uint256 numPlayers,
        uint256 raffleState
    );

    /*//////////////////////////////////////////////////////////////
                               Events
    //////////////////////////////////////////////////////////////*/
    event RaffleEntered(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    /*//////////////////////////////////////////////////////////////
                           Type Declarations
    //////////////////////////////////////////////////////////////*/
    enum RaffleState {
        OPEN,
        CALCULATING
    }
    /*//////////////////////////////////////////////////////////////
                           State Variables
    //////////////////////////////////////////////////////////////*/
    // Raffle variables
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval; // duration in seconds

    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address payable private s_recentWinner;
    RaffleState private s_raffleState;

    // Chainlink VRF variables
    bytes32 private immutable s_gasLane;
    uint256 private immutable s_subscriptionId;
    uint32 private immutable s_callbackGasLimit;

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    /*//////////////////////////////////////////////////////////////
                              Constructor
    //////////////////////////////////////////////////////////////*/
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

        s_gasLane = gasLane;
        s_subscriptionId = subscriptionId;
        s_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
    }

    /*//////////////////////////////////////////////////////////////
                              External
    //////////////////////////////////////////////////////////////*/
    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert NotEnoughEth();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }

        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    /**
     * @dev Called by Automation to check if upkeep is needed.
     */
    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool isOpen = (s_raffleState == RaffleState.OPEN);
        bool timePassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;

        upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0");
    }

    /**
     * @dev Called by Automation to perform the upkeep (request randomness).
     */
    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }

        s_raffleState = RaffleState.CALCULATING;

        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: s_gasLane,
                subId: s_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: s_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );

        emit RequestedRaffleWinner(requestId);
    }

    /*//////////////////////////////////////////////////////////////
                        VRF Callback (internal)
    //////////////////////////////////////////////////////////////*/
    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] calldata randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];

        s_recentWinner = winner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;

        emit WinnerPicked(winner);

        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    /*//////////////////////////////////////////////////////////////
                          View / Pure Getters
    //////////////////////////////////////////////////////////////*/
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 index) external view returns (address) {
        return s_players[index];
    }

    function getLastTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }
}

