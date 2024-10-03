// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

//import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Auction {
    error Auction__OnlyOwnerCanCall();
    error Auction__InvalidWithdrawAmount();
    error Auction__BidTooLow();
    error Auction__MinimumNotMet();
    error Auction__BiddingNotOver();
    error Auction__InvalidAccount();

    error Auction__Ended();

    address payable public i_owner;
    uint256 private immutable i_bidEnded;
    uint256 private constant MINIMUM_BID = 5 ether;
    uint256 public highestBid;
    uint256 private totalBid;
    address public highestBidder;

    mapping(address => uint256) private bidder;

    event PaymentFunction(string message);
    event HighestBid(address user, uint256 amount, string message);
    event Refunded(address user, uint256 amount);
    event WinnerPicked(string message, uint256 bid, address winner);

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert Auction__OnlyOwnerCanCall();
        }
        _;
    }

    modifier auctionEnded() {
        require(block.timestamp >= i_bidEnded, Auction__BiddingNotOver());
        _;
    }

    constructor(uint256 _bidEnded) {
        i_owner = payable(msg.sender);
        i_bidEnded = block.timestamp + _bidEnded;
    }

    receive() external payable {
        placeBid();
        emit PaymentFunction("Receive Function called");
    }

    fallback() external payable {
        if (msg.sender != i_owner) {
            placeBid();
            emit PaymentFunction("Fallback Function called");
        }
    }


    function placeBid() public payable {
        require(msg.value > MINIMUM_BID, Auction__MinimumNotMet());
        require(msg.value > highestBid, Auction__BidTooLow());
        require(msg.sender != address(0), Auction__InvalidAccount());
        require(block.timestamp <= i_bidEnded, Auction__Ended());

        uint256 previousBid = bidder[msg.sender];
        bidder[msg.sender] = msg.value;
        totalBid += msg.value;

        if (previousBid > 0) {
            (bool refundSuccess,) = msg.sender.call{value: previousBid}("");
            require(refundSuccess, "Refund Failed");
            emit Refunded(msg.sender, previousBid);
        }

        highestBidder = msg.sender;
        highestBid = msg.value;

        emit HighestBid(msg.sender, msg.value, "New highestBid added");
    }


    function pickWinner() public onlyOwner auctionEnded {
        require(highestBid > 0 && highestBidder != address(0), "No bids placed");
        emit WinnerPicked("Winner selected!", highestBid, highestBidder);
    }


    function refund() public auctionEnded {
        uint256 biddedAmount = bidder[msg.sender];
        require(msg.sender != address(0) || msg.sender != highestBidder, "Cannot Refund");
        require(biddedAmount < highestBid, "Higghest bidder cannot be Refunded");

        bidder[msg.sender] = 0; // Set their balance to 0
        totalBid -= biddedAmount; // Decrease the total donation amount

        // Send back the amount
        (bool success,) = msg.sender.call{value: biddedAmount}("");
        require(success, "RefundFailed");

        emit Refunded(msg.sender, biddedAmount);
    }


    function withdraw() external onlyOwner auctionEnded {
        uint256 contractBalance = address(this).balance;

        require(contractBalance > 0, "Invalid withdraw amount");
         
        (bool success,) = i_owner.call{value: contractBalance}("");
        require(success, "WithdrawFailed");

        emit PaymentFunction("Withdrawal completed!");
    }

    /////Getter functions/////

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getHighestBid() public view returns (uint256) {
        return highestBid;
    }

    function getHighestBidder() public view returns (address) {
        return highestBidder;
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getTimeLeft() public view returns (uint256) {
        if (block.timestamp >= i_bidEnded) {
            return 0;
        } else {
            return (i_bidEnded - block.timestamp);
        }
    }
}
