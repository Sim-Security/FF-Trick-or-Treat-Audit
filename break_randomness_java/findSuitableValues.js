const ethers = require("ethers");

function findSuitableValues() {
    const msgSender = "0x9dF0C6b0066D5317aA5b38B36850548DaCCa6B4e"; // attacker address
    const nextTokenId = 1;

    for (let timestamp = 1700000000; timestamp < 1800000000; timestamp++) { // Example timestamp range
        for (let prevrandao = 1; prevrandao < 1000000; prevrandao++) { // Example prevrandao range
            // Convert prevrandao to a hex string with "0x" prefix and pad it to 32 bytes
            // let prevrandaoHex;
            // try {
            //     prevrandaoHex = ethers.utils.hexZeroPad("0x" + prevrandao.toString(16), 32);
            // } catch (error) {
            //     console.error(`Failed to pad prevrandao: ${prevrandao}`);
            //     console.error(error);
            //     continue; // Skip this iteration
            // }

            // Encode the parameters
            let packed;
            try {
                packed = ethers.utils.defaultAbiCoder.encode(
                    ["uint256", "address", "uint256", "uint256"],
                    [
                        timestamp,
                        msgSender,
                        nextTokenId,
                        prevrandao
                    ]
                );
            } catch (error) {
                console.error(`Failed to encode parameters for timestamp: ${timestamp}, prevrandao: ${prevrandao}`);
                console.error(error);
                continue; // Skip this iteration
            }

            // Compute the hash
            let hash;
            try {
                hash = ethers.utils.keccak256(packed);
            } catch (error) {
                console.error(`Failed to compute hash for timestamp: ${timestamp}, prevrandao: ${prevrandao}`);
                console.error(error);
                continue; // Skip this iteration
            }

            // Compute hashNumber = hash % 1000
            let hashNumber;
            try {
                console.log(`hash: ${hash}`);
                console.log(`hash: ${hash.toString()}`);
                hashNumber = ethers.BigNumber.from(hash).mod(1000).toNumber();
                console.log(`hashNumber: ${hashNumber}`);
            } catch (error) {
                console.error(`Failed to compute hashNumber for hash: ${hash}`);
                console.error(error);
                continue; // Skip this iteration
            }

            // Check if hashNumber equals 1
            if (hashNumber == 1) {
                console.log(`Found suitable values: ${hashNumber}
block.timestamp: ${timestamp}
block.prevrandao: ${prevrandao}
`);
                return;
            }

            // Optional: Log progress every 100,000 iterations to monitor progress
            if (prevrandao % 100000 === 0) {
                console.log(`Checked timestamp: ${timestamp}, prevrandao: ${prevrandao}`);
            }
        }
    }
    console.log("Suitable values not found within the range.");
}

findSuitableValues();
