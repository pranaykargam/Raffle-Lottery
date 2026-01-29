* git status
git diff

* Raffle.sol = real lottery logic;
* RaffleTest.t.sol = a separate contract that uses Raffle like an external user to prove it behaves


01. git clone https://github.com/Cyfrin/foundry-smart-contract-lottery-cu from cyfrin github repo.

02. command + shift + p

03. forge install 
04. forge build

`view`: Promises no state changes (no writes), but can read state variables,
         blockchain data (block.timestamp, msg.sender), or balances.

`pure`: Promises no state changes and no state reads—only uses function inputs or local variables.

`Creating Custom Errors`:
=> much more gas efficient.
-> visibility from public to external. external is more gas efficient,

`Events`:-
=> An event is declared with the event keyword and parameters
 (e.g. event EnteredRaffle(address indexed player);

=> When you call emit EnteredRaffle(msg.sender); inside a function,
 its data is written into the transaction’s log, not normal storage.

=> These logs live in the transaction receipt and cannot be read by other contracts,
 but are easily read by off-chain code (web3.js, ethers.js, TheGraph, etc.).

 `Why events are important`?
 => contract tells the UI or backend that something happened 
 (e.g. user entered raffle, winner picked, tokens transferred)
 => Cheaper than storage.

 ` block.timestamp`;-

 ⭐ When you deploy/start the raffle, you save:
  s_lastTimeStamp = block.timestamp; → “start time”.

   Later, when someone calls pickWinner, you check:
 ⭐ block.timestamp - s_lastTimeStamp >= i_interval.

   Has at least i_interval seconds passed since the raffle started?

  If yes → allowed to pick winner.
  If no → too early, revert.

  ⭐What if you don’t use it?
   Anyone could call pickWinner immediately, so your “10 minute raffle” could become a “1 second raffle.”

 ⭐⭐⭐⭐ Introduction to Chainlink VRF:-

    01. create subscription.
    02. Add funds to the subscription.
    03. Add consumers

    forge install smartcontractkit/chainlink-brownie-contracts
    forge install smartcontractkit/chainlink


  ⭐⭐  Modulo Operation:

    eg: `123454321` % 10 = 1
   This means that the player with index 1 `(s_players[1])` is the winner of our raffle!
    The random number will always be different and sufficiently large. 
    Using `s_players`.length will ensure that we always include all the players who paid a ticket. 



`What an enum is`?
An enum (enumeration) is a custom type that lists all allowed values as named options, e.g. OPEN, CLOSED.
Under the hood, Solidity stores enums as uints starting from 0, but you work with the names instead of numbers.
Enums are useful for modeling state machines (phases of a process) like “open → calculating → paying out → open again”.
​
Example (simplified):
enum Status {
    PENDING, // 0
    SHIPPED, // 1
    DELIVERED // 2
}
Status private s_status;

* lifecycle is:
01. Start: OPEN (constructor).
02. Users enter: enterRaffle only works if OPEN.
03. Time passes, pickWinner called → state set to CALCULATING, VRF request sent.
04. VRF callback (fulfillRandomWords) picks winner, pays out, sets state back to OPEN


    /*//////////////////////////////////////////////////////////////
                               CEI METHOD
    //////////////////////////////////////////////////////////////*/
****  `CEI` method is just a safe order for writing functions: 
first check, then change your own state, and only at the end talk to other contracts or send ETH.

01. Checks → 2) Effects → 3) Interactions.

1. Checks
You verify that this call is allowed before doing anything important.

`checks`:
require(msg.value >= i_entranceFee, "Not enough ETH");
If a check fails, you revert immediately and nothing else runs.

`Effects`
Now you safely update your own contract storage, before sending any ETH or calling anyone.
Examples of effects:

* Updating balances: s_balances[msg.sender] -= amount;

* Changing raffle state: s_raffleState = RaffleState.CALCULATING;

`Interactions`
Last step: interact with the outside world (most dangerous part)
Sending ETH: (bool success,) = winner.call{value: amount}("");

Calling another contract: otherContract.doSomething();


`Introduction to Chainlink Automation`???
   ==>>  https://automation.chain.link/sepolia/103118182182760145674240696362479762867357394454797975792728511788056267194123

  * `crontab guru`

* Chainlink Automation is a tool that automatically runs your contract functions when certain conditions are true.
* It can trigger based on time, custom logic, or logs.
* ​it replaces your own cron server or scripts.
*  It is more reliable, decentralized, and saves gas by checking off-chain first.
*  In your lottery, it auto-runs the raffle steps without you calling functions manually

`Example`: 
you set the interval to 30 minutes; Automation checks every block (off-chain), 
and once 30 minutes have passed and there are players with balance, it triggers performUpkeep to pick a winner automatically.

// Deploy Script
// Deploy a mock chainlink VRF
// Test AND dEploy the l;ottery 

    /*//////////////////////////////////////////////////////////////
                         INSTALLATION OF HEADERS
    //////////////////////////////////////////////////////////////*/
//.  `npm install -g sol-headers`
//.  `sol-headers "installation of headers"`


    /*//////////////////////////////////////////////////////////////
                          SUBSCRIBING TO EVENTS
    //////////////////////////////////////////////////////////////*/

created script/interactions
  `cast sig "createSubscription()"`
  open.xyz/signatures


  // Creating the Subscription UI

      /*//////////////////////////////////////////////////////////////
                           FUND SUBSCRIPTIONS
    //////////////////////////////////////////////////////////////*/
`my account` keystore was saved successfully. Address: 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266

`forge install transmissions11/solmate`
    




​