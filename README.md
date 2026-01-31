
# Raffle Lottery ⭐

## Overview

    This project implements a decentralized raffle lottery smart contract using Solidity and Foundry, 
    enabling users to buy entries and randomly select winners on-chain. 
     It exists to demonstrate secure, automated, and transparent prize draws using Chainlink tooling in a real-world-style dApp.

 <img src="./images/Raffle Flow .png" alt="">

## Setup & configuration ⚙️ 

 * Deploy `Raffle.sol` with entrance fee, interval, VRF & Automation settings.

* Create and fund VRF subscription, add raffle as consumer, set up Automation job.


## Players enter raffle 🎟️ 

* Users call enterRaffle and send `msg.value >= i_entranceFee`.

* Contract stores their address in `s_players` and emits an EnteredRaffle event.


## Waiting period ⏳ 

* Time passes until
  `block.timestamp - s_lastTimeStamp >= i_interval`.

* Raffle stays in OPEN state collecting players and ETH.


## Automation check ✅ 

* Chainlink Automation calls checkUpkeep off-chain.

* If conditions true (enough time, players, ETH, raffle OPEN), it returns upkeepNeeded = true.


## Automation perform 🛠️ 

* Automation calls performUpkeep on-chain.

* Contract changes state to CALCULATING, requests randomness from VRF, emits RequestedRaffleWinner.


## VRF randomness fulfilled 🎰 

* VRF Coordinator calls fulfillRandomWords.

* Contract computes `winnerIndex = randomWord % players.length`, picks winner address.


## Payout and reset 🏆

* Contract sends the pot to winner using .call.

* Clears `s_players`, updates `s_lastTimeStamp`, sets state back to `OPEN`, emits WinnerPicked.


## Next round 🔁 

* System is ready again; loop back to step 2 for the next raffle cycle.


## Acknowledgements☘️
Patrick Collins – for the incredible teaching and inspiration. 💙

## 🔗 Useful Links

 https://updraft.cyfrin.io/courses/foundry

Patrick Collins on X: https://twitter.com/PatrickAlphaC


