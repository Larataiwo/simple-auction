## Auction Smart Contract

This project implements a decentralized auction system on the Ethereum blockchain using Solidity. The contract allows users to place bids in an auction for a specific period. 

The owner can withdraw the highest bid, and participants who are outbid are refunded their previous bids automatically. The auction runs for a fixed duration, and at the end, the highest bidder is declared the winner.


## Features

**Bid management:** Users can place bids, and their previous bids are refunded if they are outbid.

**Owner controls:** The contract owner can withdraw funds and pick the auction winner.

**Refund system:** Users who are outbid receive their previous bid back.

**Dynamic bidding:** The highest bidder is continuously updated, and only bids higher than the current highest bid are accepted.

**Automatic winner selection:** The contract automatically tracks the highest bid and allows the owner to declare the winner at the end of the auction.