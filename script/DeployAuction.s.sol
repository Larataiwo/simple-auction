// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {Auction} from "../src/Auction.sol";

contract Deploy is Script {
    uint256 public constant AUCTION_DAYS = 5 days;

    function run() external returns (Auction) {
        vm.startBroadcast();
        Auction auction = new Auction(AUCTION_DAYS);
        vm.stopBroadcast();
        return auction;
    }
}
