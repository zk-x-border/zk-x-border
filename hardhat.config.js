require("dotenv").config();

const { INFURA_PROJECT_ID, PRIVATE_KEY, ETHERSCAN_GOERLI_API_KEY, POLYGONSCAN_API_KEY } = process.env;

require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");

module.exports = {
    defaultNetwork: "matic",
    networks: {
        matic: {
            url: `https://polygon-mainnet.infura.io/v3/${INFURA_PROJECT_ID}`,
            accounts: [`0x${PRIVATE_KEY}`],
            gas: 1200000,
            blockGasLimit: 12000000
        },
        hardhat: {
            forking: {
                url: `https://mainnet.infura.io/v3/${INFURA_PROJECT_ID}`,
            },
            gas: 120000000,
            blockGasLimit: 120000000
        },
        goerli: {
            url: `https://goerli.infura.io/v3/${INFURA_PROJECT_ID}`,
            accounts: [`0x${PRIVATE_KEY}`]
        },
        localhost: {
            url: "http://127.0.0.1:8545",
            timeout: 2000000,
            gas: 120000000,
            blockGasLimit: 120000000
        },
        polygon: {
            url: "https://rpc-mainnet.maticvigil.com",
            accounts: [`0x${PRIVATE_KEY}`]
        }
    },
    // Etherscan verification doesn't work, was able to do it manually
    etherscan: {
        apiKey: {
            goerli: ETHERSCAN_GOERLI_API_KEY,
            polygon: POLYGONSCAN_API_KEY
        }
    },
    paths: {
        artifacts: "./artifacts",
    },
    solidity: {
        version: "0.7.6",
        settings: {
            optimizer: {
                enabled: true,
                runs: 200
            }
        }
    }
};