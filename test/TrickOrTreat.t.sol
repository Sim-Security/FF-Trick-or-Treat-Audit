// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import { SpookySwap } from "../src/TrickOrTreat.sol";

contract SpookySwapTest is Test {
    SpookySwap spookySwap;
    address attacker = makeAddr("attacker");
    address user = makeAddr("user");

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
    
    // Give the user some ETH
    modifier fundUser(uint256 amount) {
        vm.deal(user, amount);
        _;
    }

    // Give the attacker some ETH
    modifier fundAttacker(uint256 amount) {
        vm.deal(attacker, amount);
        _;
    }

    function testForTrick() public {
        uint256 nextTokenId = 1;
        uint256 timestamp = 1700000000;
        uint256 prevrandao = 1;
        
        vm.startPrank(attacker);
        console2.log("Address: ", attacker);
        console2.log("Address: ", address(attacker));
        for (uint256 i = 0; i < 1000; i++) {
            uint256 random = uint256(keccak256(abi.encodePacked(timestamp, attacker, nextTokenId, i))) % 1000 + 1;
            if (random == 2) {
                console2.log("Prevrandao: ", i);
                prevrandao = i;
                break;
            }
        }
        uint256 random =
                uint256(keccak256(abi.encodePacked(timestamp, attacker, nextTokenId, prevrandao))) % 1000 + 1;
        assertEq(random, 2);
        // we have found the random numbers that will set the trick
        // block.timestamp = 1700000000
        // block.prevrandao = 260
        // msg.sender = address(attacker)
        // nextTokenId = 1
    }

    function testAddTreat() public {
        // Add a new treat
        spookySwap.addTreat("Chocolate", 2 ether, "ipfs://Qm...");
        string[] memory treats = spookySwap.getTreats();
        assertEq(treats.length, 2);
    }

    function testTrickOrTreatWithEnoughFundsSent() public fundUser(10 ether) {
        // cost is 1 ether. If the user send 1 ether, the nft will be minted and then the user will need to resolve it
        vm.startPrank(user);
        spookySwap.trickOrTreat{value: 1 ether}("Candy");
        assertEq(user.balance, 9 ether);
        assertEq(address(spookySwap).balance, 1 ether);
        assertEq(spookySwap.ownerOf(1), user); // check to see that the user is the owner of the nft
        assertEq(spookySwap.balanceOf(user), 1); // check to see that the user has the nft
    }
    function testCostChangeBetweenTrickAndResolution() public fundAttacker(10 ether) {
        // we have found the random numbers that will set the trick
        // block.timestamp = 1700000000
        // block.prevrandao = 260
        // msg.sender = address(attacker)
        // nextTokenId = 1
        // cost is 2 ether since a trick has happened. If the user only send 1 ether, the nft will be minted to the contract and then the user will need to resolve it. Lets make sure the price is correct
        vm.warp(1700000000);// to ensure the random number is 2
        vm.prevrandao(260); //to ensure the random number is 2
        vm.startPrank(attacker);
        vm.expectRevert(bytes("Insufficient ETH sent for treat"));
        // vm.expectEmit(true, false, false, true);
        // emit SpookySwap.Swapped(attacker, "Candy", 1);
        spookySwap.trickOrTreat{value: 1 ether}("Candy"); // not enough eth to pay for the treat because it is a trick!.

        // Check the pending nft is reserved for the user
        // console2.log("Pending NFT: ", spookySwap.pendingNFTs(1));
        // console2.log("Attacker: ", attacker);
        // assertEq(spookySwap.pendingNFTs(1), attacker);
        
        // We need to send an aditional 1.0 ether to resolve the nft
        spookySwap.resolveTrick{value: 1 ether}(1);
        assertEq(attacker.balance, 8 ether);
        assertEq(address(spookySwap).balance, 2 ether);
        assertEq(spookySwap.ownerOf(1), attacker); // check to see that the user is the owner of the nft
        assertEq(spookySwap.balanceOf(attacker), 1); // check to see that the user has the nft
    }

    
    // This is a known issue. No need to test it. 
    // function testManipulateRandomness() public {
    //     vm.deal(attacker, 1 ether); // Give the attacker some ETH
    //     vm.startPrank(attacker);

    //     // Set block variables to manipulate randomness
    //     uint256 desiredRandomNumber = 1; // Half-price treat
    //     uint256 nextTokenId = spookySwap.nextTokenId();
    //     address msgSender = attacker;

    //     // Brute-force block.prevrandao and block.timestamp
    //     // For simplicity, we'll simulate the manipulation

    //     // Calculate the required block.prevrandao to get random == 1
    //     // Note: In an actual attack, the miner would adjust these values
    //     uint256 manipulatedPrevrandao = uint256(
    //         keccak256(
    //             abi.encodePacked(desiredRandomNumber - 1)
    //         )
    //     );

    //     vm.roll(100); // Advance to block 100
    //     vm.warp(1000); // Set block.timestamp

    //     // Set manipulated block variables
    //     vm.prevrandao(manipulatedPrevrandao);

    //     // Call trickOrTreat with manipulated randomness
    //     uint256 initialBalance = attacker.balance;
    //     console2.log("Initial balance", initialBalance);
    //     spookySwap.trickOrTreat{value: 0.5 ether}("Candy");

    //     // Check that the attacker received the NFT at half price
    //     uint256 newBalance = attacker.balance;
    //     console2.log("New balance", newBalance);
    //     assertEq(newBalance, initialBalance - 0.5 ether);

    //     // Verify that the token was minted to the attacker
    //     uint256 tokenId = spookySwap.nextTokenId() - 1;
    //     assertEq(spookySwap.ownerOf(tokenId), attacker);

    //     vm.stopPrank();
    // }
}
