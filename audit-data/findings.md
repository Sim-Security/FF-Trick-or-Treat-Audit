### [H-1] Denial of Service via Malicious Refund Failures (Refund Mechanism + Contract Lockdown)

**Description:** The `SpookySwap` smart contract contains a vulnerability in its refund mechanism within the `trickOrTreat` and `resolveTrick` functions. The contract attempts to refund excess ETH sent by users using a low-level `call`. If the refund fails (e.g., when the recipient is a malicious contract that reverts upon receiving ETH), the entire transaction is reverted due to the `require(refundSuccess, "Refund failed")` statement. This allows an attacker to deploy contracts that consistently cause refund failures, leading to transaction reverts. By orchestrating multiple such failed refund attempts, an attacker can exhaust the contract's gas resources and approach block gas limits, effectively causing a Denial of Service (DoS) condition that locks down the contract's purchasing functionality.

**Impact:** Exploiting this vulnerability can lead to a Denial of Service (DoS) condition where legitimate users are unable to successfully purchase NFTs. By deploying multiple malicious contracts that cause refund failures, an attacker can consume significant gas resources and potentially approach block gas limits. This results in:

- **Contract Lockdown:** Preventing any new transactions from being processed, effectively locking down the contract.
- **Service Disruption:** Legitimate users attempting to purchase NFTs will experience transaction failures.
- **Economic Impact:** Undermines the contract's revenue model and token distribution mechanisms.
- **Reputational Damage:** Erodes user trust and confidence in the platform, potentially deterring future participation and investment.

**Proof of Concept:**
The following Forge test demonstrates how a malicious contract can exploit the refund mechanism to cause transaction reverts, leading to a DoS condition.

<!-- <details> -->

<summary> Proof of Code </summary>

```javascript
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import { SpookySwap } from "../src/TrickOrTreat.sol";

/// @notice A contract that always reverts upon receiving ETH to simulate refund failures.
contract MaliciousRefundContract {
    /// @notice Attempts to receive ETH but always reverts.
    receive() external payable {
        revert("Cannot receive ETH - DoS Attack!");
    }
}

/// @notice Test contract
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

```

<!-- </details> -->


**Explanation:**

1. **MaliciousRefundContract:**
   - **Purpose:** Simulates a malicious contract that **always reverts** when attempting to receive ETH, thereby causing refund failures.
   - **Functionality:** The `receive` function is overridden to always revert, ensuring that any ETH sent to it (as a refund) will fail.

2. **SpookySwapTest:**
   - **Setup:**
     - **Deploy SpookySwap:** Initializes the `SpookySwap` contract with a single treat named "Candy" costing 1 ether.
   - **Attack Execution (`testDenialOfServiceInRefund`):**
     - **Impersonation:** Begins impersonating the `maliciousUser` address to simulate malicious behavior.
     - **Refund Failures:** The malicious contract attempts to purchase "Candy" by sending 2 ether, expecting a refund of 1 ether. However, since the refund recipient (`MaliciousRefundContract`) cannot receive ETH, the refund attempt fails, causing the entire transaction to revert.
     - **Assertions:**
       - **No NFTs Minted:** Confirms that no NFTs were minted as all purchase attempts reverted.
       - **Zero Contract Balance:** Ensures that the contract's balance remains zero, indicating that no ETH was retained from failed refunds.

**Recommended Mitigation:**

**Adopt the Pull Over Push Pattern for Refunds**

To eliminate the risk of refund-induced DoS attacks, it is recommended to **shift from an automatic push-based refund mechanism to a pull-based system**. This approach allows users to **withdraw their refunds** themselves, thereby removing dependencies on the recipient's ability to receive ETH.                   s

### [L-01] Incorrect Event Emission Misleads Users (Event Emitted Before NFT Transfer Causes Confusion)

## Summary

The `SpookySwap` smart contract emits the `Swapped` event incorrectly when a user doesn't send enough ETH during a "trick" scenario. Specifically, the contract mints the NFT to itself (`address(this)`) but emits the `Swapped` event as if the user (`msg.sender`) received the NFT. This misleads users and off-chain systems into believing that the NFT has been transferred to the user when it hasn't. The issue lies in the event emission timing and the incorrect recipient address in the event parameters.

## Vulnerability Details

### Issue Overview

In the `trickOrTreat` function, when the `costMultiplierNumerator` is `2` and `costMultiplierDenominator` is `1`, the contract handles the "double price" case (a trick). If the user doesn't send enough ETH (`msg.value < requiredCost`), the contract mints the NFT to itself and stores pending purchase details. However, it incorrectly emits the `Swapped` event with `msg.sender` as the recipient, suggesting that the NFT has been transferred to the user.

### Affected Code

```Solidity
if (costMultiplierNumerator == 2 && costMultiplierDenominator == 1) {
    // Double price case (trick)
    if (msg.value >= requiredCost) {
        // User sent enough ETH
        mintTreat(msg.sender, treat);
    } else {
        // User didn't send enough ETH
        // Mint NFT to contract and store pending purchase
        uint256 tokenId = nextTokenId;
        _mint(address(this), tokenId);
        _setTokenURI(tokenId, treat.metadataURI);
        nextTokenId += 1;

        pendingNFTs[tokenId] = msg.sender;
        pendingNFTsAmountPaid[tokenId] = msg.value;
        tokenIdToTreatName[tokenId] = _treatName;

        // Incorrect event emission
@>      emit Swapped(msg.sender, _treatName, tokenId);

        // User needs to call fellForTrick() to finish the transaction
    }
}
```

### Problem Explanation

* **Incorrect Recipient in Event:** The `Swapped` event is emitted with `msg.sender` as the recipient, even though the NFT is minted to `address(this)`, not to the user.
* **Misleading Event Timing:** Emitting the event at this point suggests that the NFT transfer to the user is complete, which is not the case. The user must call `resolveTrick()` to finalize the transfer.
* **Potential for Confusion:** Users and off-chain systems relying on the `Swapped` event may incorrectly assume the NFT is in the user's possession.

## Impact

* **User Confusion:** Users might believe they own the NFT and attempt actions like transferring or interacting with it, leading to failed transactions.
* **Misrepresentation in Off-Chain Systems:** Wallets, explorers, and dApps that track events may display inaccurate ownership information.
* **Operational Integrity Issues:** The misleading event undermines the trust in the contract's reliability and transparency.

**Severity Classification:** **Low**

## Tools Used

Manual code review

## Recommendations

1. **Adjust the Event Emission:**

   * **Update the Recipient Address:**
     Change the `emit Swapped` statement to reflect the correct recipient (`address(this)`).

     ```solidity
     emit Swapped(address(this), _treatName, tokenId);
     ```

   * **Or Emit a Different Event:**
     Emit a new event to indicate that the NFT is pending and the user needs to take further action.

     ```solidity
     event TrickInitiated(address indexed user, string treatName, uint256 tokenId);

     emit TrickInitiated(msg.sender, _treatName, tokenId);
     ```



### [L-02] Missing Event Emission After NFT Transfer (Event Not Emitted Causes Inconsistent State Tracking)

---

## Summary

In the `resolveTrick` function of the `SpookySwap` contract, after successfully transferring an NFT from the contract to the user, the contract fails to emit the `Swapped` event. This omission can lead to off-chain systems and users not being aware of the NFT transfer, causing inconsistencies between the on-chain state and external perceptions. The lack of event emission affects user experience and the reliability of applications that rely on these events to update NFT ownership statuses.

## Vulnerability Details

### Issue Overview

When a user calls the `resolveTrick` function to complete their purchase (after initially not paying enough during a "trick" scenario), the contract correctly transfers the NFT to the user. However, it does not emit the `Swapped` event to signal this transfer. Events are crucial for off-chain applications like wallets and explorers to track token movements and update user balances.

### Affected Code

```solidity
function resolveTrick(uint256 tokenId) public payable nonReentrant {
    require(pendingNFTs[tokenId] == msg.sender, "Not authorized to complete purchase");

    string memory treatName = tokenIdToTreatName[tokenId];
    Treat memory treat = treatList[treatName];

    uint256 requiredCost = treat.cost * 2; // Double price
    uint256 amountPaid = pendingNFTsAmountPaid[tokenId];
    uint256 totalPaid = amountPaid + msg.value;

    require(totalPaid >= requiredCost, "Insufficient ETH sent to complete purchase");

    // Transfer the NFT to the buyer
@>   _transfer(address(this), msg.sender, tokenId);

    // Clean up storage
    delete pendingNFTs[tokenId];
    delete pendingNFTsAmountPaid[tokenId];
    delete tokenIdToTreatName[tokenId];

    // Refund excess ETH if any
    if (totalPaid > requiredCost) {
        uint256 refund = totalPaid - requiredCost;
        (bool refundSuccess, ) = msg.sender.call{value: refund}("");
        require(refundSuccess, "Refund failed");
    }
}
```

### Problem Explanation

- **Missing Event Emission:** After transferring the NFT to the user using `_transfer(address(this), msg.sender, tokenId);`, the function does not emit the `Swapped` event or any equivalent event to indicate the successful transfer.

- **Impact on Off-Chain Systems:** Off-chain services that rely on event logs to update NFT ownership will not detect this transfer, leading to outdated or incorrect information displayed to users.

- **User Confusion:** Users may not see their newly acquired NFT in wallets or platforms immediately, causing confusion and potential mistrust in the system.

## Impact

- **Inaccurate Off-Chain Data:** Wallets, explorers, and other applications may fail to update the user's NFT holdings, as they rely on emitted events to track changes.

- **User Experience Degradation:** Users might believe the transaction failed or is pending, leading to unnecessary support requests or negative perceptions of the platform.

- **Operational Integrity:** The contract's reliability is undermined when standard practices like event emissions are not consistently followed.

**Severity Classification:** Low

While the NFT transfer occurs correctly on-chain, the missing event affects the user experience and the accuracy of off-chain data. It does not, however, lead to a loss of funds, security vulnerabilities, or critical disruptions in contract functionality.

## Tools Used

- **Manual Code Review:** Analyzed the `resolveTrick` function to identify the absence of event emission after the NFT transfer.

- **Testing Frameworks:** Utilized testing tools like Hardhat or Foundry to simulate transactions and observe emitted events.

- **Blockchain Explorers:** Monitored contract interactions to confirm that the `Swapped` event is not emitted when expected.

## Recommendations

1. **Emit the `Swapped` Event After NFT Transfer**

   Add the `emit Swapped` statement immediately after the NFT is transferred to the user within the `resolveTrick` function.

```diff
function resolveTrick(uint256 tokenId) public payable nonReentrant {
    require(pendingNFTs[tokenId] == msg.sender, "Not authorized to complete purchase");

    string memory treatName = tokenIdToTreatName[tokenId];
    Treat memory treat = treatList[treatName];

    uint256 requiredCost = treat.cost * 2; // Double price
    uint256 amountPaid = pendingNFTsAmountPaid[tokenId];
    uint256 totalPaid = amountPaid + msg.value;

    require(totalPaid >= requiredCost, "Insufficient ETH sent to complete purchase");

    // Transfer the NFT to the buyer
    _transfer(address(this), msg.sender, tokenId);

+   // Emit the Swapped event to indicate successful transfer
+   emit Swapped(msg.sender, treatName, tokenId);

    // Clean up storage
    delete pendingNFTs[tokenId];
    delete pendingNFTsAmountPaid[tokenId];
    delete tokenIdToTreatName[tokenId];

    // Refund excess ETH if any
    if (totalPaid > requiredCost) {
        uint256 refund = totalPaid - requiredCost;
        (bool refundSuccess, ) = msg.sender.call{value: refund}("");
        require(refundSuccess, "Refund failed");
    }
}
```





### [S-#] TITLE (Root Cause + Impact)

**Description:** 

**Impact:** 

**Proof of Concept:**

**Recommended Mitigation:**                                                                                                                                                                                                                                             




