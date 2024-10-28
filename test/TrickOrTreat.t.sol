// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import { SpookySwap } from "../src/TrickOrTreat.sol";
// import { IERC721Receiver } from "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";

contract SpookySwapTest is Test {
    SpookySwap spookySwap;
    address attacker = makeAddr("attacker");
    address user = makeAddr("user");
    ReentrantContract public reentrantAttacker;

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
        // vm.expectRevert(bytes("Insufficient ETH sent for treat"));
        vm.expectEmit(true, false, false, true);
        emit SpookySwap.Swapped(attacker, "Candy", 1);
        spookySwap.trickOrTreat{value: 1 ether}("Candy"); // not enough eth to pay for the treat because it is a trick!.

        // Check the pending nft is reserved for the user
        console2.log("Pending NFT: ", spookySwap.pendingNFTs(1));
        console2.log("Attacker: ", attacker);
        assertEq(spookySwap.pendingNFTs(1), attacker);
        
        // We need to send an aditional 1.0 ether to resolve the nft
        spookySwap.resolveTrick{value: 1 ether}(1);
        assertEq(attacker.balance, 8 ether);
        assertEq(address(spookySwap).balance, 2 ether);
        assertEq(spookySwap.ownerOf(1), attacker); // check to see that the user is the owner of the nft
        assertEq(spookySwap.balanceOf(attacker), 1); // check to see that the user has the nft
    }

    function testSetTreatCostChangeBetweenTrickAndResolution() public fundAttacker(10 ether) {
        // we have found the random numbers that will set the trick
        // block.timestamp = 1700000000
        // block.prevrandao = 260
        // msg.sender = address(attacker)
        // nextTokenId = 1
        // cost is 2 ether since a trick has happened. If the user only send 1 ether, the nft will be minted to the contract and then the user will need to resolve it. Lets make sure the price is correct
        vm.warp(1700000000);// to ensure the random number is 2
        vm.prevrandao(260); //to ensure the random number is 2 and the trick is set.

        vm.startPrank(attacker);
        vm.expectEmit(true, false, false, true);
        emit SpookySwap.Swapped(attacker, "Candy", 1);
        spookySwap.trickOrTreat{value: 1 ether}("Candy"); // not enough eth to pay for the treat because it is a trick!.
        vm.stopPrank();
        
        // owner changes the price of the nft
        vm.prank(spookySwap.owner());
        spookySwap.setTreatCost("Candy", 10 ether);

        // We should only need to send an additional 1.0 ether to resolve the nft
        // Since the owner changed the price, we have insufficient funds to resolve the nft
        vm.startPrank(attacker);
        vm.expectRevert(bytes("Insufficient ETH sent to complete purchase"));
        spookySwap.resolveTrick{value: 1 ether}(1);
    }

    function testRefundInTrickOrTreat() public fundUser(10 ether) {
        vm.startPrank(user);
        spookySwap.trickOrTreat{value: 3 ether}("Candy");
        assertEq(user.balance, 9 ether);
        assertEq(address(spookySwap).balance, 1 ether);
        assertEq(spookySwap.ownerOf(1), user); // check to see that the user is the owner of the nft
        assertEq(spookySwap.balanceOf(user), 1); // check to see that the user has the nft
    }

    function testReentrancyAttack() public {
        // Deploy the attacker contract
        reentrantAttacker = new ReentrantContract(address(spookySwap));

        // Fund the attacker contract
        vm.deal(address(reentrantAttacker), 10 ether);
        console2.log("ReentancyContract Balance: ", address(reentrantAttacker).balance);

        // Expect that reentrancy is prevented and the second call fails
        vm.startPrank(address(reentrantAttacker));

        // Attempt to perform the attack
        reentrantAttacker.initiateAttack{value: 1 ether}("Candy");

 // Calculate the expected tokenId after the first mint
        uint256 expectedTokenId = 1; // nextTokenId starts at 1

        // Assert that the attacker received the NFT
        assertEq(spookySwap.ownerOf(expectedTokenId), address(reentrantAttacker), "Attacker should own the minted NFT");

        // Assert that the tokenIdToReenter was set correctly
        // assertEq(reentrantAttacker.tokenIdToReenter(), expectedTokenId, "tokenIdToReenter should match the minted tokenId");

        // Verify that no additional NFTs were minted due to the failed reentrant call
        uint256 finalNextTokenId = spookySwap.nextTokenId();
        assertEq(finalNextTokenId, expectedTokenId + 1, "No additional NFTs should be minted due to reentrancy");

        vm.stopPrank();
    }

    function testDenialOfServiceInRefund() public {
        MaliciousRefundContract maliciousUser = new MaliciousRefundContract();
        vm.deal(address(maliciousUser), 10 ether);

        // Start impersonating the malicious contract's address
        vm.startPrank(address(maliciousUser));

        // Attempt to purchase a treat with excess ETH to trigger a refund
        // Since the contract cannot receive ETH, the refund should fail
        // Expect the transaction to revert with "Refund failed"
        vm.expectRevert("Refund failed");
        spookySwap.trickOrTreat{value: 2 ether}("Candy");

        // Stop impersonating the malicious contract
        vm.stopPrank();

        // Additional Assertions (Optional):

        // Ensure that no NFT was minted since the transaction reverted
        uint256 finalNextTokenId = spookySwap.nextTokenId();
        assertEq(finalNextTokenId, 1, "No NFT should be minted due to refund failure");

        // Ensure that the contract's balance remains unchanged (only the initial treat setup)
        uint256 contractBalance = address(spookySwap).balance;
        assertEq(contractBalance, 0, "Contract balance should remain zero after failed refund");
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

contract ReentrantContract {
    SpookySwap public spookySwap;
    address public owner;
    uint256 public tokenIdToReenter;
    bool public reentered;

    event ReentrancySuccessful();

    constructor(address _spookySwap) {
        spookySwap = SpookySwap(_spookySwap);
        owner = msg.sender;
        reentered = false;
    }

       // Fallback function that attempts to re-enter trickOrTreat upon receiving ETH
    fallback() external payable {
        if (!reentered) {
            reentered = true;
            spookySwap.trickOrTreat{value: 1 ether}("Candy");
        }
    }

    receive() external payable {
        revert ("Do not send ETH directly to this contract - DoS attack!");
    }

    // Function to initiate the attack
    function initiateAttack(string memory _treatName) external payable {
        spookySwap.trickOrTreat{value: msg.value}(_treatName);
    }
}

/// @title MaliciousRefundContract
/// @notice A contract that always reverts upon receiving ETH to simulate refund failures.
contract MaliciousRefundContract {
    /// @notice Attempts to receive ETH but always reverts.
    receive() external payable {
        revert("Cannot receive ETH - DoS Attack!");
    }
}
