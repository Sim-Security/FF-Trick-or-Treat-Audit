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
    // A test to show that the price can be changed after the initial trickOrTeat call, causing the `tricked` purchaser to have to pay more to resolve the nft
    function testSetTreatCostChangeBetweenTrickAndResolution() public {
        // we have found the random numbers that will set the trick
        // block.timestamp = 1700000000
        // block.prevrandao = 260
        // msg.sender = address(attacker)
        // nextTokenId = 1
        // cost is 2 ether since a trick has happened. If the user only send 1 ether, the nft will be minted to the contract and then the user will need to resolve it. Lets make sure the price is correct
        vm.warp(1700000000);// to ensure the random number is 2
        vm.prevrandao(260); //to ensure the random number is 2 and the trick is set.

        // Give the attacker some eth
        vm.deal(attacker, 10 ether);

        // Start impersonating the attacker
        vm.startPrank(attacker);

        // Try to purchase the nft, but results in a `trick`.
        spookySwap.trickOrTreat{value: 1 ether}("Candy"); // not enough eth to pay for the treat because it is a trick!.
        vm.stopPrank();
        
        // owner changes the price of the nft
        vm.prank(spookySwap.owner());
        spookySwap.setTreatCost("Candy", 4 ether);

        // We should only need to send an additional 1.0 ether to resolve the nft
        // Since the owner changed the price to 4 ether, we have insufficient funds to resolve the nft
        // This is because the price is calculated inside the resolveTrick function instead  of being saved in the trickOrTreat function. This means the new `trick` price is 8 ether, meaning the user needs to send an additional 7 ether to resolve the nft
        vm.startPrank(attacker);
        vm.expectRevert(bytes("Insufficient ETH sent to complete purchase"));
        spookySwap.resolveTrick{value: 1 ether}(1);

        // Attacker balance should still be 9 ether since the transaction reverted
        assertEq(attacker.balance, 9 ether);
        // Contract balance should still be 1 ether since the transaction reverted
        assertEq(address(spookySwap).balance, 1 ether);
        // Attacker should still have 1 ether paid towards the nft
        assertEq(spookySwap.pendingNFTsAmountPaid(1), 1 ether);
        // Attacker should still be the pending owner of the nft
        assertEq(spookySwap.pendingNFTs(1), attacker);
    }

}