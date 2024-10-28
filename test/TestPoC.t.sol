// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import { SpookySwap } from "../src/TrickOrTreat.sol";

contract SpookySwapTest is Test {
    SpookySwap spookySwap;

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

        // Ensure that no NFT was minted since the transaction reverted
        uint256 finalNextTokenId = spookySwap.nextTokenId();
        assertEq(finalNextTokenId, 1, "No NFT should be minted due to refund failure");

        // Ensure that the contract's balance remains unchanged (only the initial treat setup)
        uint256 contractBalance = address(spookySwap).balance;
        assertEq(contractBalance, 0, "Contract balance should remain zero after failed refund");
    }

}

/// @notice A contract that always reverts upon receiving ETH to simulate refund failures.
contract MaliciousRefundContract {
    /// @notice Attempts to receive ETH but always reverts.
    receive() external payable {
        revert("Cannot receive ETH - DoS Attack!");
    }
}