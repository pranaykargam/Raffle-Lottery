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
    error Raffle__UpkeepNotNeeded(uint256 balance, uint256 numPlayers, uint256 raffleState);

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
    uint256 private immutable I_ENTRANCE_FEE;
    uint256 private immutable I_INTERVAL; // duration in seconds

    address payable[] private splayers;
    uint256 private sLastTimeStamp;
    address payable private sRecentWinner;
    RaffleState private sRaffleState;

    // Chainlink VRF variables
    bytes32 private immutable S_GAS_LANE;
    uint256 private immutable S_SUBSCRIPTION_ID;
    uint32 private immutable _CALLBACK_GAS_LIMIT;

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
        I_ENTRANCE_FEE = entranceFee;
        I_INTERVAL = interval;
        sLastTimeStamp = block.timestamp;

        S_GAS_LANE = gasLane;
        S_SUBSCRIPTION_ID = subscriptionId;
        _CALLBACK_GAS_LIMIT = callbackGasLimit;
        sRaffleState = RaffleState.OPEN;
    }

    /*//////////////////////////////////////////////////////////////
                              External
    //////////////////////////////////////////////////////////////*/
    function enterRaffle() external payable {
        if (msg.value < I_ENTRANCE_FEE) {
            revert NotEnoughEth();
        }
        if (sRaffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }

        splayers.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    /**
     * @dev Called by Automation to check if upkeep is needed.
     */
    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        bool isOpen = (sRaffleState == RaffleState.OPEN);
        bool timePassed = (block.timestamp - sLastTimeStamp) >= I_INTERVAL;
        bool hasPlayers = splayers.length > 0;
        bool hasBalance = address(this).balance > 0;

        upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0");
    }

    /**
     * @dev Called by Automation to perform the upkeep (request randomness).
     */
    function performUpkeep(
        bytes calldata /* performData */
    )
        external
    {
        (bool upkeepNeeded,) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(address(this).balance, splayers.length, uint256(sRaffleState));
        }

        sRaffleState = RaffleState.CALCULATING;

        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: S_GAS_LANE,
                subId: S_SUBSCRIPTION_ID,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: _CALLBACK_GAS_LIMIT,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
            })
        );

        emit RequestedRaffleWinner(requestId);
    }

    /*//////////////////////////////////////////////////////////////
                        VRF Callback (internal)
    //////////////////////////////////////////////////////////////*/
    function fulfillRandomWords(
        uint256,
        /* requestId */
        uint256[] calldata randomWords
    )
        internal
        override
    {
        uint256 indexOfWinner = randomWords[0] % splayers.length;
        address payable winner = splayers[indexOfWinner];

        sRecentWinner = winner;
        sRaffleState = RaffleState.OPEN;
        splayers = new address payable[](0);
        sLastTimeStamp = block.timestamp;

        emit WinnerPicked(winner);

        (bool success,) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    /*//////////////////////////////////////////////////////////////
                          View / Pure Getters
    //////////////////////////////////////////////////////////////*/
    function getEntranceFee() external view returns (uint256) {
        return I_ENTRANCE_FEE;
    }

    function getRaffleState() external view returns (RaffleState) {
        return sRaffleState;
    }

    function getPlayer(uint256 index) external view returns (address) {
        return splayers[index];
    }

    function getLastTimeStamp() public view returns (uint256) {
        return sLastTimeStamp;
    }

    function getRecentWinner() public view returns (address) {
        return sRecentWinner;
    }
}

