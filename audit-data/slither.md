```bash
INFO:Detectors:
SpookySwap.trickOrTreat(string) (src/TrickOrTreat.sol#48-106) uses a weak PRNG: "random = uint256(keccak256(bytes)(abi.encodePacked(block.timestamp,msg.sender,nextTokenId,block.prevrandao))) % 1000 + 1 (src/TrickOrTreat.sol#56-57)" 
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#weak-PRNG



INFO:Detectors:
SpookySwap.trickOrTreat(string) (src/TrickOrTreat.sol#48-106) uses a dangerous strict equality:
        - random == 1 (src/TrickOrTreat.sol#59)
SpookySwap.trickOrTreat(string) (src/TrickOrTreat.sol#48-106) uses a dangerous strict equality:
        - random == 2 (src/TrickOrTreat.sol#63)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#dangerous-strict-equalities



INFO:Detectors:
SpookySwap.trickOrTreat(string) (src/TrickOrTreat.sol#48-106) uses timestamp for comparisons
        Dangerous comparisons:
        - random == 1 (src/TrickOrTreat.sol#59)
        - random == 2 (src/TrickOrTreat.sol#63)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#block-timestamp



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