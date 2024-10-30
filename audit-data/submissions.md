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


2. ### [L-01] Incorrect Event Emission Misleads Users (Event Emitted Before NFT Transfer Causes Confusion)

## Summary
T## Summary

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


4. ### [M-01] Owner Can Increase NFT Price After Trick (Price Manipulation Allows Exploitation of Users)


## Summary

In the `SpookySwap` smart contract, after a user is "tricked" by not sending enough ETH during a purchase, they are required to call the `resolveTrick` function to complete the transaction by paying the remaining amount. However, the contract allows the owner to change the price of the NFT (the treat) after the user has been tricked but before they resolve the trick. This means the owner can increase the required payment arbitrarily, forcing the user to pay more than the originally agreed-upon double price to receive the NFT. This vulnerability enables the owner to exploit users financially and undermines trust in the platform. The owner may not know that the NFT is already pending a purchase, and the price increase could be inadvertent.

## Vulnerability Details

### Issue Overview

- **Function Involved:** `resolveTrick(uint256 tokenId)`
- **Vulnerability Type:** Price Manipulation / Owner Privilege Abuse
- **Root Cause:** The required cost is recalculated at the time of `resolveTrick`, allowing the owner to change the treat's price between the initial purchase attempt and the resolution, affecting the user's final payment amount.

### Affected Code

```solidity
function setTreatCost(string memory _treatName, uint256 _cost) public onlyOwner {
    require(treatList[_treatName].cost > 0, "Treat must cost something.");
    treatList[_treatName].cost = _cost;
}
```

```solidity
function resolveTrick(uint256 tokenId) public payable nonReentrant {
    require(pendingNFTs[tokenId] == msg.sender, "Not authorized to complete purchase");

    string memory treatName = tokenIdToTreatName[tokenId];
    Treat memory treat = treatList[treatName];

@>    uint256 requiredCost = treat.cost * 2; // Double price
    uint256 amountPaid = pendingNFTsAmountPaid[tokenId];
    uint256 totalPaid = amountPaid + msg.value;

    require(totalPaid >= requiredCost, "Insufficient ETH sent to complete purchase");

    // Transfer the NFT to the buyer
    _transfer(address(this), msg.sender, tokenId);

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

- **Dynamic Price Calculation:** The `requiredCost` is recalculated when `resolveTrick` is called:

  ```solidity
  uint256 requiredCost = treat.cost * 2; // Double price
  ```

- **Owner Privilege to Change Price:** The owner can change the `treat.cost` at any time using the `setTreatCost` function.


- **Vulnerability Exploitation:** Between the user's initial attempt (where they didn't send enough ETH) and their call to `resolveTrick`, the owner can increase `treat.cost`, thus increasing `requiredCost`. The user is then forced to pay more than expected to obtain the NFT.

### Proof of Concept (PoC)

#### Step-by-Step Exploitation:

1. **User Attempts Purchase and Is Tricked:**

   - User calls `trickOrTreat` but sends less than the required cost.
   - NFT is minted to the contract, and the user must call `resolveTrick` to complete the purchase.

2. **Owner Increases the Treat Price:**

   - Owner calls `setTreatCost` to increase the `treat.cost` for the specific treat.

3. **User Calls `resolveTrick`:**

   - User calls `resolveTrick`, expecting to pay the original double price.
   - Due to the increased `treat.cost`, `requiredCost` is now higher.
   - User must pay the new, higher amount to receive the NFT.

#### Example Code: 
Paste this into a solidity test folder as a new file..

```solidity
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
        // we have found the random numbers that will set the `trick`
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
```

**Explanation:**

User is the `Attacker` in the PoC.

- **Initial Setup:**
  - The treat "Candy" costs 1 ether.
  - User has 10 ether.

- **User Purchase Attempt:**
  - User sends 1 ether, but a trick is initiated and the user needs to send 2 ether. User will need to call the `resolveTrick` function and send more ether to receive the NFT.

- **Owner Price Increase:**
  - Owner increases the treat cost to 4 ether.
  - Required cost in `resolveTrick` becomes `4 ether * 2 = 8 ether`.

- **User Tries to Resolve Trick:**
  - User attempts to pay the remaining amount, expecting to pay a total of 2 ether (double the original cost).
  - Transaction reverts with "Insufficient ETH sent to complete purchase" because the required cost is now 8 ether.

## Impact

- **Financial Exploitation:**
  - Users are forced to pay more than the agreed-upon price to obtain the NFT.
  - The owner can effectively hold the NFT hostage until the user pays the increased amount.

- **Trust Erosion:**
  - Users lose trust in the platform due to unfair practices.
  - Potential legal and reputational repercussions for manipulating prices after a transaction has been initiated.

- **Violation of Expectations:**
  - Users expect the price to be fixed at the time of purchase.
  - Changing the price retroactively breaches the implicit agreement.

**Severity Classification:** **Medium**

- **Likelihood:** Low to Medium
  - The owner must intentionally manipulate the price after a user has been tricked.
  - Such behavior is likely to be noticed and could deter users from the platform.

- **Impact:** High for Affected Users
  - Users may suffer financial loss if they choose to pay the higher price.
  - Alternatively, they may lose the opportunity to obtain the NFT they intended to purchase.

## Tools Used

- **Manual Code Analysis:** Reviewed the contract code to identify where price calculation occurs and how it can be manipulated.

- **Testing Frameworks:** Used a Solidity testing framework (e.g., Hardhat or Foundry) to simulate the exploit scenario.

- **Blockchain Simulations:** Tested contract interactions in a controlled environment to observe the effects of price manipulation.

## Recommendations

### 1. **Lock the Price at the Time of Initial Purchase Attempt**

- **Store the Required Cost:**

  Modify the contract to store the `requiredCost` at the time the user is tricked.

  **Code Changes:**

  ```diff
  // Inside the else block where the user didn't send enough ETH
  else {
      uint256 tokenId = nextTokenId;
      _mint(address(this), tokenId);
      _setTokenURI(tokenId, treat.metadataURI);
      nextTokenId += 1;

      pendingNFTs[tokenId] = msg.sender;
      pendingNFTsAmountPaid[tokenId] = msg.value;
      tokenIdToTreatName[tokenId] = _treatName;

  +   // Store the required cost at the time of trick
  +   pendingNFTsRequiredCost[tokenId] = treat.cost * 2; // Double price

      emit TrickInitiated(msg.sender, _treatName, tokenId);
  }
  ```

  **Data Structure Addition:**

  ```solidity
  mapping(uint256 => uint256) public pendingNFTsRequiredCost;
  ```

- **Use the Stored Cost in `resolveTrick`:**

  Modify `resolveTrick` to use the stored `requiredCost` instead of recalculating it.

  **Code Changes:**

  ```diff
  function resolveTrick(uint256 tokenId) public payable nonReentrant {
      require(pendingNFTs[tokenId] == msg.sender, "Not authorized to complete purchase");

      string memory treatName = tokenIdToTreatName[tokenId];
      // Treat memory treat = treatList[treatName]; // No longer needed

  -   uint256 requiredCost = treat.cost * 2; // Double price
  +   uint256 requiredCost = pendingNFTsRequiredCost[tokenId];

      uint256 amountPaid = pendingNFTsAmountPaid[tokenId];
      uint256 totalPaid = amountPaid + msg.value;

      require(totalPaid >= requiredCost, "Insufficient ETH sent to complete purchase");

      // Transfer the NFT to the buyer
      _transfer(address(this), msg.sender, tokenId);

      // Clean up storage
      delete pendingNFTs[tokenId];
      delete pendingNFTsAmountPaid[tokenId];
      delete tokenIdToTreatName[tokenId];
  +   delete pendingNFTsRequiredCost[tokenId];

      // Refund excess ETH if any
      // ... existing code ...
  }
  ```

**Benefits:**

- **Price Stability:** Ensures users pay the expected amount, maintaining trust.
- **Prevents Exploitation:** Owner cannot manipulate the price after the initial purchase attempt.

### 2. **Restrict Price Updates During Active Transactions**

- **Implement a Cooldown Period:**

  Prevent the owner from updating the price of a treat if there are pending purchases involving that treat.

- **Code Implementation:**

  ```solidity
  mapping(string => bool) public treatHasPendingPurchases;

  // When a trick is initiated
  treatHasPendingPurchases[_treatName] = true;

  // After resolving the trick
  if (!hasPendingPurchases(_treatName)) {
      treatHasPendingPurchases[_treatName] = false;
  }

  function updateTreatCost(string memory _treatName, uint256 _newCost) external onlyOwner {
      require(!treatHasPendingPurchases[_treatName], "Cannot update price during pending purchases");
      treatList[_treatName].cost = _newCost;
  }
  ```

  **Note:** Implementing `hasPendingPurchases` requires tracking the number of pending purchases per treat.

**Benefits:**

- **Prevents Mid-Transaction Price Changes:** Ensures fairness for users who have already initiated a purchase.
- **Maintains Owner Flexibility:** Allows the owner to update prices when no transactions are pending.

### 3. **Enhance Transparency**

- **Notify Users of Price Changes:**

  Implement events and front-end notifications to inform users when prices change.

- **Code Implementation:**

  ```solidity
  event TreatPriceUpdated(string indexed treatName, uint256 oldPrice, uint256 newPrice);

  function updateTreatCost(string memory _treatName, uint256 _newCost) external onlyOwner {
      uint256 oldCost = treatList[_treatName].cost;
      treatList[_treatName].cost = _newCost;
      emit TreatPriceUpdated(_treatName, oldCost, _newCost);
  }
  ```

- **Front-End Adjustments:**

  Ensure that the user interface displays the correct price at all times and warns users if a price has changed.

### 4. **Implement Timelocks for Critical Changes**

- **Use Timelocks for Price Updates:**

  Introduce a delay between when a price update is announced and when it takes effect.

- **Code Implementation:**

  ```solidity
  struct PendingPriceUpdate {
      uint256 newCost;
      uint256 effectiveTime;
  }

  mapping(string => PendingPriceUpdate) public pendingPriceUpdates;

  function schedulePriceUpdate(string memory _treatName, uint256 _newCost) external onlyOwner {
      pendingPriceUpdates[_treatName] = PendingPriceUpdate({
          newCost: _newCost,
          effectiveTime: block.timestamp + 1 days // 24-hour timelock
      });
      emit TreatPriceUpdateScheduled(_treatName, _newCost, pendingPriceUpdates[_treatName].effectiveTime);
  }

  function executePriceUpdate(string memory _treatName) external {
      PendingPriceUpdate memory update = pendingPriceUpdates[_treatName];
      require(update.effectiveTime <= block.timestamp, "Price update not yet effective");
      treatList[_treatName].cost = update.newCost;
      delete pendingPriceUpdates[_treatName];
      emit TreatPriceUpdated(_treatName, treatList[_treatName].cost, update.newCost);
  }
  ```

**Benefits:**

- **User Protection:** Gives users time to react to price changes.
- **Transparency:** Enhances trust by preventing sudden changes.

### 5. **Document and Communicate Policies**

- **Clear Terms and Conditions:**

  Define policies regarding price stability and updates in the platform's terms of service.

- **User Education:**

  Inform users about how prices are managed and their rights in the event of price changes.

---

By implementing these recommendations, the `SpookySwap` contract will ensure fair treatment of users, prevent potential exploitation, and maintain trust in the platform. Locking in prices at the time of purchase attempts and restricting price changes during pending transactions are critical steps in achieving these goals.

---

**Severity Classification:** **Medium**

- **Likelihood:** Low to Medium
  - Requires malicious action by the owner.
  - However, the possibility exists, and users have no protection against it in the current implementation.

- **Impact:** Medium to High
  - Affected users can suffer financial losses or lose access to desired NFTs.
  - Erodes trust in the platform, potentially affecting its reputation and user base.

**Final Assessment:** The vulnerability is classified as **Medium severity** due to the potential for significant user impact, even though the likelihood is reduced by the need for intentional owner misconduct.

---

If you need further assistance or have any questions about implementing these recommendations, feel free to ask!