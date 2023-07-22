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

const EuroPool = "0x0000000000000000000000000000000000000000"; // To fill in
const EuroPoolABI = require("../abi/EuroPool.json");

const ORDER_ID = 1;
const EMAIL_HASH = "0";

async function main() {
    console.log(`USDPool.claim order ID ${ORDER_ID}`);

    const euroPoolContract = await ethers.getContractAt(EuroPoolABI, EuroPool);

    const receipt = await euroPoolContract.claimOrder(
        ORDER_ID,
        EMAIL_HASH,
        { gasLimit: 140000 }
    );

    const { transactionHash } = receipt;

    console.log(`Submitted USDCPool claim Order: ${transactionHash}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
