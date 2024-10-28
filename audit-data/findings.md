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


### [S-#] TITLE (Root Cause + Impact)

**Description:** 

**Impact:** 

**Proof of Concept:**

**Recommended Mitigation:**                                                                                                                                                                                                                                             




# What I sent as report.
## Summary

The `SpookySwap` smart contract contains a vulnerability in its refund mechanism within the `trickOrTreat` and `resolveTrick` functions. The contract attempts to refund excess ETH sent by users using a low-level `call`. If the refund fails (e.g., when the recipient is a malicious contract that reverts upon receiving ETH), the entire transaction is reverted due to the `require(refundSuccess, "Refund failed")` statement. This allows an attacker to deploy contracts that consistently cause refund failures, leading to transaction reverts. By orchestrating multiple such failed refund attempts, an attacker can exhaust the contract's gas resources and approach block gas limits, effectively causing a Denial of Service (DoS) condition that locks down the contract's purchasing functionality.

## Vulnerability Details

The vulnerability stems from how the `SpookySwap` contract handles refunds when users overpay for NFTs. Specifically, in both the `trickOrTreat` and `resolveTrick` functions, the contract uses a low-level `call` to refund excess ETH sent by the user:

```solidity
(bool refundSuccess, ) = msg.sender.call{value: refund}("");
require(refundSuccess, "Refund failed");
```

This refund mechanism has the following issues:

1. **Dependence on Recipient's Ability to Receive ETH**: If the `msg.sender` is a smart contract that does not implement a payable `receive` or `fallback` function, or deliberately reverts upon receiving ETH, the refund will fail.

2. **Transaction Reversion on Refund Failure**: The use of `require(refundSuccess, "Refund failed")` means that if the refund fails, the entire transaction reverts. This not only prevents the user from purchasing the NFT but also ensures that no state changes occur.

3. **Potential for Repeated Failures**: An attacker can deploy multiple malicious contracts that always revert on receiving ETH. By repeatedly attempting to purchase NFTs using these contracts, the attacker can cause numerous transaction reverts.

**Proof of Concept:**
The following Forge test demonstrates how a malicious contract can exploit the refund mechanism to cause transaction reverts, leading to a DoS condition.

## Impact

Exploiting this vulnerability can lead to a Denial of Service (DoS) condition where legitimate users are unable to successfully purchase NFTs. By deploying multiple malicious contracts that cause refund failures, an attacker can consume significant gas resources and potentially approach block gas limits. This results in:

* **Contract Lockdown:** Preventing any new transactions from being processed, effectively locking down the contract.
* **Service Disruption:** Legitimate users attempting to purchase NFTs will experience transaction failures.
* **Economic Impact:** Undermines the contract's revenue model and token distribution mechanisms.
* **Reputational Damage:** Erodes user trust and confidence in the platform, potentially deterring future participation and investment.

**Proof of Concept:**

The following Forge test demonstrates how a malicious contract can exploit the refund mechanism to cause transaction reverts, leading to a DoS condition.

```Solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import { SpookySwap } from "../src/TrickOrTreat.sol";

// @notice A contract that always reverts upon receiving ETH to simulate refund failures.
contract MaliciousRefundContract {
    // @notice Attempts to receive ETH but always reverts.
    receive() external payable {
        revert("Cannot receive ETH - DoS Attack!");
    }
}

// @notice Test contract
contract SpookySwapTest is Test {
    SpookySwap spookySwap;

    function setUp() public {
        // Initialize the contract with a sample treat
        SpookySwap.Treat[] memory treats = new SpookySwap.Treat[]();
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

**Explanation:**

1. **MaliciousRefundContract:**
   * **Purpose:** Simulates a malicious contract that **always reverts** when attempting to receive ETH, thereby causing refund failures.
   * **Functionality:** The `receive` function is overridden to always revert, ensuring that any ETH sent to it (as a refund) will fail.

2. **SpookySwapTest:**
   * **Setup:**
     * **Deploy SpookySwap:** Initializes the `SpookySwap` contract with a single treat named "Candy" costing 1 ether.
   * **Attack Execution (`testDenialOfServiceInRefund`):**
     * **Impersonation:** Begins impersonating the `maliciousUser` address to simulate malicious behavior.
     * **Refund Failures:** The malicious contract attempts to purchase "Candy" by sending 2 ether, expecting a refund of 1 ether. However, since the refund recipient (`MaliciousRefundContract`) cannot receive ETH, the refund attempt fails, causing the entire transaction to revert.
     * **Assertions:**
       * **No NFTs Minted:** Confirms that no NFTs were minted as all purchase attempts reverted.
       * **Zero Contract Balance:** Ensures that the contract's balance remains zero, indicating that no ETH was retained from failed refunds.

## Tools Used

Manual Review

## Recommendations

To mitigate the identified Denial of Service (DoS) vulnerability in the `SpookySwap` contract's refund mechanism, the following measures are strongly recommended:

1. **Adopt the Pull Over Push Pattern for Refunds**

**Description:**
Instead of **automatically sending refunds** to users (push), **allow users to withdraw** their refunds themselves (pull). This approach eliminates dependencies on the recipient's ability to receive ETH, thereby preventing refund-induced transaction reverts.

**Implementation Steps:**

1. **Track Pending Refunds:**
   * Introduce a mapping to record pending refunds for each user.

     ```solidity
     mapping(address => uint256) public pendingRefunds;
     ```

2. **Modify** **`trickOrTreat`** **Function to Record Refunds:**
   * Instead of sending the refund directly, record it in the `pendingRefunds` mapping.

     ```solidity
     if (msg.value > requiredCost) {
         uint256 refund = msg.value - requiredCost;
         pendingRefunds[msg.sender] += refund;
         emit RefundRecorded(msg.sender, refund);
     }
     ```

3. **Modify** **`resolveTrick`** **Function to Record Refunds:**

   * Instead of sending the refund directly, record it in the `pendingRefunds` mapping.

   ```solidity
   if (totalPaid > requiredCost) {
       uint256 refund = totalPaid - requiredCost;
       pendingRefunds[msg.sender] += refund;
       emit RefundRecorded(msg.sender, refund);
   }
   ```

4. **Implement** **`withdrawRefund`** **Function:**
   * Allow users to withdraw their pending refunds at their convenience.

     ```Solidity
     // @notice Allows users to withdraw their pending refunds.
     function withdrawRefund() external nonReentrant {
         uint256 refundAmount = pendingRefunds[msg.sender];
         require(refundAmount > 0, "No refunds available");

         // Reset the refund before transferring to prevent reentrancy
         pendingRefunds[msg.sender] = 0;

         (bool success, ) = msg.sender.call{value: refundAmount}("");
         require(success, "Refund withdrawal failed");

         emit RefundWithdrawn(msg.sender, refundAmount);
     }
     ```

5. **Define Relevant Events:**
   * Emit events to track refund records and withdrawals.

     ```Solidity
     // @notice Emitted when a refund is recorded.
     event RefundRecorded(address indexed user, uint256 amount);

     // @notice Emitted when a refund is withdrawn.
     event RefundWithdrawn(address indexed user, uint256 amount);

     ```

## Conclusion

The identified **Denial of Service (DoS)** vulnerability in the `SpookySwap` contract's refund mechanism poses a significant threat by allowing malicious actors to **prevent legitimate users** from purchasing NFTs, effectively **locking down** the contract's functionality. By implementing the recommended mitigation strategies—**Adopting the Pull Over Push pattern**—the contract can be fortified against such exploits. Addressing this vulnerability is crucial to ensure the contract's **operational integrity**, **economic viability**, and **user trust**.
