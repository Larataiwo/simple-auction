// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Auction} from "../src/Auction.sol";
import {Deploy} from "../script/DeployAuction.s.sol";

contract TestAuction is Test {
    Auction public auction;
    Deploy public deploy;

    uint256 public constant BIDDING_PERIOD = 5 days;
    address public constant BOB = address(1);
    address public constant ALICE = address(2);

    function setUp() public {
        auction = new Auction(BIDDING_PERIOD);
        deploy = new Deploy();

        vm.deal(BOB, 50 ether);
        vm.deal(ALICE, 50 ether);
    }

    function test_onlyOwnerModifier() public {
        vm.warp(block.timestamp + 6 days);
        vm.prank(BOB);
        vm.expectRevert(Auction.Auction__OnlyOwnerCanCall.selector);
        auction.withdraw();
    }

    function test_auctionEndedModifier() public {
        vm.warp(block.timestamp + 3 days);
        vm.expectRevert(Auction.Auction__BiddingNotOver.selector);
        auction.withdraw();
        vm.expectRevert(Auction.Auction__BiddingNotOver.selector);
        auction.pickWinner();
    }

    function test_placeBid() public {
        vm.prank(BOB);
        auction.placeBid{value: 10 ether}();

        vm.prank(ALICE);
        auction.placeBid{value: 15 ether}();

        vm.prank(BOB);
        auction.placeBid{value: 20 ether}();

        assertEq(auction.getHighestBid(), 20 ether);
        assertEq(auction.getContractBalance(), 35 ether);
        assertEq(auction.getHighestBidder(), BOB);
        auction.getContractBalance();
    }

    function test_refund() public {
        vm.warp(block.timestamp + BIDDING_PERIOD);

        vm.prank(BOB);
        auction.placeBid{value: 10 ether}();
        vm.prank(ALICE);
        auction.placeBid{value: 15 ether}();
        assertEq(auction.getContractBalance(), 25 ether);

        vm.prank(BOB);
        auction.placeBid{value: 20 ether}();
        vm.prank(ALICE);
        auction.placeBid{value: 25 ether}();
        assertEq(auction.getContractBalance(), 45 ether);

        vm.prank(BOB);
        auction.refund();
        assertEq(auction.getContractBalance(), 25 ether);
        auction.getHighestBid();
        auction.getHighestBidder();
    }

    function test_remainingTime() public {
        uint256 time = 5 days - block.timestamp + 1;
        assertEq(auction.getTimeLeft(), time);

        vm.warp(block.timestamp + 7 days);
        assertEq(auction.getTimeLeft(), 0);
    }

    function test_recieveFunction() public {
        vm.prank(BOB);
        (bool success,) = address(auction).call{value: 6 ether}("");
        require(success);

        assertEq(auction.getHighestBid(), 6 ether);
        assertEq(auction.getHighestBidder(), BOB);
    }

    function test_FallbackFunction() public {
        vm.prank(BOB);
        (bool success,) = address(auction).call{value: 10 ether}(abi.encodeWithSignature("invalidFunction()"));
        require(success);
        assertEq(address(auction).balance, 10 ether);
    }

    function test_pickWinner() public {
        vm.prank(BOB);
        auction.placeBid{value: 20 ether}();

        vm.prank(ALICE);
        (bool success,) = address(auction).call{value: 30 ether}(abi.encodeWithSignature("invalidFunction()"));
        require(success);

        vm.warp(block.timestamp + 5 days); // Move time past the auction end
        auction.pickWinner();

        assertEq(auction.getHighestBid(), 30 ether);
        assertEq(auction.getHighestBidder(), ALICE);
        auction.getContractBalance();
        auction.getHighestBidder();
    }

    function test_withdraw() public {
        vm.prank(BOB);
        auction.placeBid{value: 20 ether}();

        auction.getHighestBid();
        auction.getContractBalance();

        vm.warp(block.timestamp + 5 days);
        vm.startPrank(auction.getOwner());
        auction.withdraw();
        assertEq(address(auction).balance, 0);
        vm.stopPrank();
    }

    function test_deployment() public {
        auction = deploy.run();
        assertTrue(address(auction) != address(0), "Auction not deployed");

        uint256 auctionPeriod = BIDDING_PERIOD;
        uint256 currentTime = block.timestamp;
        uint256 expectedAuctionEnd = currentTime + 5 days;

        assertTrue(
            auctionPeriod >= expectedAuctionEnd - 2 && auctionPeriod <= expectedAuctionEnd + 2,
            "Auction duration should be approximately 5 days"
        );
    }
}
