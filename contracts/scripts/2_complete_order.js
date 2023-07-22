// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
const { BigNumber } = hre.ethers;

// Lay out the const contrat instances
const USDC = "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174";
const USDCABI = require("../abi/USDC.json");

const USDCPool = "0x0000000000000000000000000000000000000000"; // To fill in
const USDCPoolABI = require("../abi/USDCPool.json");

const ORDER_ID = 1;
const EMAIL_HASH = "0";

// These inputs are hard-coded and pulled in from the Relayer's Proof
const a = ["0x09f880318914368db9f055fdf61cacd81dca2c47b96c2ff8cd3609dfadcb353b", "0x07c494bb55a683c1013309303b061aca366f86073b0304d22b97dc5c602ebb4f"];
const b = [
    ["0x1562b771233d15ca0e4fd6c43f7f783a32e1c4c060179b130a8e0d606206a5e7", "0x0ce9476295b8b42ae6be8b95ee9ae00675be05438199f66c5ddfaa22d659a33e"],
    ["0x1a2c8e4432e43f8d71db8624219064916e5a51e3d9b924470d2a8f56b7eab279", "0x2500443dc24546b62b317f1dd1d068953e0db1aca91ffb3d4be48eb2ab1e0ce4"]
];
const c = ["0x070d784e2edf7185c5d4950c0fd83f44f6d41f566cb3707000dd8b6a378c797d", "0x0fd22f41f5c0c7cf9506caa0f0fc20d23426c9b93cd8f6e424bfb2547a741be6"];

const PROOF = [a, b, c];
const SIGNALS = [
    "0x00000000000000000000000000000000000000000000000000000030302e3033",
    "0x0000000000000000000000000000000000000000000000000000000000000000",
    "0x0000000000000000000000000000000000000000000000000000000000000000",
    "0x0000000000000000000000000000000000000000000000000000000000000000",
    "0x0000000000000000000000000000000000000000000000000000000000000000",
    "0x0000000000000000000000000000000000000000000000000037303232383532",
    "0x0000000000000000000000000000000000000000000000000038353231343535",
    "0x00000000000000000000000000000000000000000000000000363934320a0d3d",
    "0x0000000000000000000000000000000000000000000000000000000000000037",
    "0x0000000000000000000000000000000000000000000000000000000000000000",
    "0x0000000000000000000000000000000000370bd327681a47a6b8d55b315582d0",
    "0x00000000000000000000000000000000003bcfba8b3a460d3f68822acdfbcd53",
    "0x0000000000000000000000000000000000000000000000000000000000002b21",
    "0x000000000000000000000000000000000083a043f3f512cb0e9efb506011e359",
    "0x0000000000000000000000000000000000c2e52cefcd800a155366e0207f2563",
    "0x0000000000000000000000000000000000f3576e6387ca2c770760edd72b0fae",
    "0x00000000000000000000000000000000019143a1fc85a71614784b98ff4b16c0",
    "0x00000000000000000000000000000000007bbd0dfb9ef73cf08f4036e24a6b72",
    "0x000000000000000000000000000000000119d3bd704f04dc4f74482cdc239dc7",
    "0x0000000000000000000000000000000001d083a581190a93434412d791fa7fd1",
    "0x000000000000000000000000000000000064350c632569b077ed7b300d3a4051",
    "0x00000000000000000000000000000000000000000000000000a879c82b6c5e0a",
    "0x0000000000000000000000000000000000000000000000000000000000000000",
    "0x0000000000000000000000000000000000000000000000000000000000000000",
    "0x0000000000000000000000000000000000000000000000000000000000000000",
    "0x0000000000000000000000000000000000000000000000000000000000000000",
    "0x0000000000000000000000000000000000000000000000000000000000000000",
    "0x0000000000000000000000000000000000000000000000000000000000000000",
    "0x0000000000000000000000000000000000000000000000000000000000000000",
    "0x0000000000000000000000000000000000000000000000000000000000000000",
    "0x0000000000000000000000000000000000000000000000000000000000000001"
];

const X_BORDER_RECEIVER_ADDRESS = "@revolutionaryRichard";


async function main() {
    console.log("USDPool.completeCrossChainOrder of order ID 1");
    console.log(`X_BORDER_RECEIVER_ADDRESS: ${X_BORDER_RECEIVER_ADDRESS}`);

    const usdcPoolContract = await ethers.getContractAt(USDCABI, USDCPool);

    const receipt = await usdcPoolContract.completeCrossChainOrder(
        PROOF, 
        SIGNALS,
        X_BORDER_RECEIVER_ADDRESS,
        { gasLimit: 500000 }
    );

    console.log(`Submitted USDCPool completeCrossChainOrder: ${receipt.transactionHash}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
