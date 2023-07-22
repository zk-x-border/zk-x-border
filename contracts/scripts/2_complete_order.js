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

// TODO Get inputs from Richard by parsing a JSON file.
const PROOF = "";
const PUBLIC_INPUTS = "";
const X_BORDER_RECEIVER_ADDRESS = "";


async function main() {
    console.log("USDPool.completeOrder of order ID 1");

    // Grab Pool

    const usdcPoolContract = await ethers.getContractAt(USDCABI, USDCPool);

    const receipt = await usdcPoolContract.completeCrossChainOrder(
        PROOF, 
        PUBLIC_INPUTS,
        X_BORDER_RECEIVER_ADDRESS,
        { gasLimit: 500000 }
    );

    console.log(receipt);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
