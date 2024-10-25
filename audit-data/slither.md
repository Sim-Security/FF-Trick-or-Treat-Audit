```bash
INFO:Detectors:
SpookySwap.trickOrTreat(string) (src/TrickOrTreat.sol#48-106) uses a weak PRNG: "random = uint256(keccak256(bytes)(abi.encodePacked(block.timestamp,msg.sender,nextTokenId,block.prevrandao))) % 1000 + 1 (src/TrickOrTreat.sol#56-57)" 
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#weak-PRNG


INFO:Detectors:
Math.mulDiv(uint256,uint256,uint256) (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#144-223) has bitwise-xor operator ^ instead of the exponentiation operator **: 
         - inverse = (3 * denominator) ^ 2 (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#205)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#incorrect-exponentiation


INFO:Detectors:
Math.mulDiv(uint256,uint256,uint256) (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#144-223) performs a multiplication on the result of a division:
        - denominator = denominator / twos (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#190)
        - inverse = (3 * denominator) ^ 2 (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#205)
Math.mulDiv(uint256,uint256,uint256) (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#144-223) performs a multiplication on the result of a division:
        - denominator = denominator / twos (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#190)
        - inverse *= 2 - denominator * inverse (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#209)
Math.mulDiv(uint256,uint256,uint256) (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#144-223) performs a multiplication on the result of a division:
        - denominator = denominator / twos (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#190)
        - inverse *= 2 - denominator * inverse (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#210)
Math.mulDiv(uint256,uint256,uint256) (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#144-223) performs a multiplication on the result of a division:
        - denominator = denominator / twos (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#190)
        - inverse *= 2 - denominator * inverse (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#211)
Math.mulDiv(uint256,uint256,uint256) (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#144-223) performs a multiplication on the result of a division:
        - denominator = denominator / twos (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#190)
        - inverse *= 2 - denominator * inverse (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#212)
Math.mulDiv(uint256,uint256,uint256) (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#144-223) performs a multiplication on the result of a division:
        - denominator = denominator / twos (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#190)
        - inverse *= 2 - denominator * inverse (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#213)
Math.mulDiv(uint256,uint256,uint256) (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#144-223) performs a multiplication on the result of a division:
        - denominator = denominator / twos (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#190)
        - inverse *= 2 - denominator * inverse (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#214)
Math.mulDiv(uint256,uint256,uint256) (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#144-223) performs a multiplication on the result of a division:
        - prod0 = prod0 / twos (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#193)
        - result = prod0 * inverse (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#220)
Math.invMod(uint256,uint256) (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#243-289) performs a multiplication on the result of a division:
        - quotient = gcd / remainder (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#265)
        - (gcd,remainder) = (remainder,gcd - remainder * quotient) (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#267-274)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#divide-before-multiply


INFO:Detectors:
SpookySwap.trickOrTreat(string) (src/TrickOrTreat.sol#48-106) uses a dangerous strict equality:
        - random == 1 (src/TrickOrTreat.sol#59)
SpookySwap.trickOrTreat(string) (src/TrickOrTreat.sol#48-106) uses a dangerous strict equality:
        - random == 2 (src/TrickOrTreat.sol#63)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#dangerous-strict-equalities


INFO:Detectors:
SpookySwap.addTreat(string,uint256,string)._name (src/TrickOrTreat.sol#37) shadows:
        - ERC721._name (lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol#23) (state variable)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#local-variable-shadowing


INFO:Detectors:
SpookySwap.trickOrTreat(string) (src/TrickOrTreat.sol#48-106) uses timestamp for comparisons
        Dangerous comparisons:
        - random == 1 (src/TrickOrTreat.sol#59)
        - random == 2 (src/TrickOrTreat.sol#63)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#block-timestamp


INFO:Detectors:
ERC721Utils.checkOnERC721Received(address,address,address,uint256,bytes) (lib/openzeppelin-contracts/contracts/token/ERC721/utils/ERC721Utils.sol#25-49) uses assembly
        - INLINE ASM (lib/openzeppelin-contracts/contracts/token/ERC721/utils/ERC721Utils.sol#43-45)
Panic.panic(uint256) (lib/openzeppelin-contracts/contracts/utils/Panic.sol#50-56) uses assembly
        - INLINE ASM (lib/openzeppelin-contracts/contracts/utils/Panic.sol#51-55)
Strings.toString(uint256) (lib/openzeppelin-contracts/contracts/utils/Strings.sol#24-42) uses assembly
        - INLINE ASM (lib/openzeppelin-contracts/contracts/utils/Strings.sol#29-31)
        - INLINE ASM (lib/openzeppelin-contracts/contracts/utils/Strings.sol#34-36)
Strings.toChecksumHexString(address) (lib/openzeppelin-contracts/contracts/utils/Strings.sol#90-108) uses assembly
        - INLINE ASM (lib/openzeppelin-contracts/contracts/utils/Strings.sol#95-97)
Math.mulDiv(uint256,uint256,uint256) (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#144-223) uses assembly
        - INLINE ASM (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#151-154)
        - INLINE ASM (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#175-182)
        - INLINE ASM (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#188-197)
Math.tryModExp(uint256,uint256,uint256) (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#337-361) uses assembly
        - INLINE ASM (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#339-360)
Math.tryModExp(bytes,bytes,bytes) (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#377-399) uses assembly
        - INLINE ASM (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#389-398)
SafeCast.toUint(bool) (lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol#1157-1161) uses assembly
        - INLINE ASM (lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol#1158-1160)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#assembly-usage


INFO:Detectors:
2 different versions of Solidity are used:
        - Version constraint ^0.8.20 is used by:
                -^0.8.20 (lib/openzeppelin-contracts/contracts/access/Ownable.sol#4)
                -^0.8.20 (lib/openzeppelin-contracts/contracts/interfaces/IERC165.sol#4)
                -^0.8.20 (lib/openzeppelin-contracts/contracts/interfaces/IERC4906.sol#4)
                -^0.8.20 (lib/openzeppelin-contracts/contracts/interfaces/IERC721.sol#4)
                -^0.8.20 (lib/openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol#3)
                -^0.8.20 (lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol#4)
                -^0.8.20 (lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol#4)
                -^0.8.20 (lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol#4)
                -^0.8.20 (lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol#4)
                -^0.8.20 (lib/openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Metadata.sol#4)
                -^0.8.20 (lib/openzeppelin-contracts/contracts/token/ERC721/utils/ERC721Utils.sol#4)
                -^0.8.20 (lib/openzeppelin-contracts/contracts/utils/Context.sol#4)
                -^0.8.20 (lib/openzeppelin-contracts/contracts/utils/Panic.sol#4)
                -^0.8.20 (lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol#4)
                -^0.8.20 (lib/openzeppelin-contracts/contracts/utils/Strings.sol#4)
                -^0.8.20 (lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol#4)
                -^0.8.20 (lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol#4)
                -^0.8.20 (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#4)
                -^0.8.20 (lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol#5)
                -^0.8.20 (lib/openzeppelin-contracts/contracts/utils/math/SignedMath.sol#4)
        - Version constraint ^0.8.24 is used by:
                -^0.8.24 (src/TrickOrTreat.sol#2)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#different-pragma-directives-are-used


INFO:Detectors:
Version constraint ^0.8.20 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
        - VerbatimInvalidDeduplication
        - FullInlinerNonExpressionSplitArgumentEvaluationOrder
        - MissingSideEffectsOnSelectorAccess.
It is used by:
        - ^0.8.20 (lib/openzeppelin-contracts/contracts/access/Ownable.sol#4)
        - ^0.8.20 (lib/openzeppelin-contracts/contracts/interfaces/IERC165.sol#4)
        - ^0.8.20 (lib/openzeppelin-contracts/contracts/interfaces/IERC4906.sol#4)
        - ^0.8.20 (lib/openzeppelin-contracts/contracts/interfaces/IERC721.sol#4)
        - ^0.8.20 (lib/openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol#3)
        - ^0.8.20 (lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol#4)
        - ^0.8.20 (lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol#4)
        - ^0.8.20 (lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol#4)
        - ^0.8.20 (lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol#4)
        - ^0.8.20 (lib/openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Metadata.sol#4)
        - ^0.8.20 (lib/openzeppelin-contracts/contracts/token/ERC721/utils/ERC721Utils.sol#4)
        - ^0.8.20 (lib/openzeppelin-contracts/contracts/utils/Context.sol#4)
        - ^0.8.20 (lib/openzeppelin-contracts/contracts/utils/Panic.sol#4)
        - ^0.8.20 (lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol#4)
        - ^0.8.20 (lib/openzeppelin-contracts/contracts/utils/Strings.sol#4)
        - ^0.8.20 (lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol#4)
        - ^0.8.20 (lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol#4)
        - ^0.8.20 (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#4)
        - ^0.8.20 (lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol#5)
        - ^0.8.20 (lib/openzeppelin-contracts/contracts/utils/math/SignedMath.sol#4)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#incorrect-versions-of-solidity


INFO:Detectors:
Low level call in SpookySwap.trickOrTreat(string) (src/TrickOrTreat.sol#48-106):
        - (refundSuccess,None) = msg.sender.call{value: refund}() (src/TrickOrTreat.sol#103)
Low level call in SpookySwap.resolveTrick(uint256) (src/TrickOrTreat.sol#119-145):
        - (refundSuccess,None) = msg.sender.call{value: refund}() (src/TrickOrTreat.sol#142)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#low-level-calls
INFO:Detectors:
Parameter SpookySwap.addTreat(string,uint256,string)._name (src/TrickOrTreat.sol#37) is not in mixedCase
Parameter SpookySwap.addTreat(string,uint256,string)._rate (src/TrickOrTreat.sol#37) is not in mixedCase
Parameter SpookySwap.addTreat(string,uint256,string)._metadataURI (src/TrickOrTreat.sol#37) is not in mixedCase
Parameter SpookySwap.setTreatCost(string,uint256)._treatName (src/TrickOrTreat.sol#43) is not in mixedCase
Parameter SpookySwap.setTreatCost(string,uint256)._cost (src/TrickOrTreat.sol#43) is not in mixedCase
Parameter SpookySwap.trickOrTreat(string)._treatName (src/TrickOrTreat.sol#48) is not in mixedCase
Parameter SpookySwap.changeOwner(address)._newOwner (src/TrickOrTreat.sol#157) is not in mixedCase
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#conformance-to-solidity-naming-conventions


INFO:Detectors:
Reentrancy in SpookySwap.withdrawFees() (src/TrickOrTreat.sol#147-151):
        External calls:
        - address(owner()).transfer(balance) (src/TrickOrTreat.sol#149)
        Event emitted after the call(s):
        - FeeWithdrawn(owner(),balance) (src/TrickOrTreat.sol#150)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-4
INFO:Slither:. analyzed (21 contracts with 93 detectors), 35 result(s) found
```