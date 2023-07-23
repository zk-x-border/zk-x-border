require("dotenv").config();

const { INFURA_PROJECT_ID, PRIVATE_KEY, ETHERSCAN_GOERLI_API_KEY, POLYGONSCAN_API_KEY } = process.env;

require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");

module.exports = {
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
        },
        gnosis: {
            url: "https://rpc.gnosis.gateway.fm",
            accounts: [`0x${PRIVATE_KEY}`]
        },
        linea: {
            // Just deploy on Linea using Infura to qualify!
            name: "linea",
            // chainId: 59144,
            url: "https://linea-goerli.infura.io/v3/82c5f2012ef5481f855420f8c6c241fc",
            accounts: [`0x${PRIVATE_KEY}`],
            // https://docs.linea.build/use-mainnet/info-contracts#network-information
            // Network Name	Linea
            // RPC URL	https://linea-mainnet.infura.io/v3 or via Infura (recommended)
            // Chain ID	59144
            // Currency Symbol	ETH
            //  Block Explorer URL	https://lineascan.build/
        },
        mantle: {
            // (include a link to smart contract deployed on Mantle Explorer)
            name: "mantle",
            chainId: 5001,
            url: "https://rpc.testnet.mantle.xyz",
            accounts: [`0x${PRIVATE_KEY}`],
        },
        celo_testnet: {
            url: "https://alfajores-forno.celo-testnet.org",
            accounts: [`0x${PRIVATE_KEY}`]
        },
        neon_evm_devnet: {
            url: "https://devnet.neonevm.org",
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
                enabled: false,
                runs: 200
            }
        }
    }
};