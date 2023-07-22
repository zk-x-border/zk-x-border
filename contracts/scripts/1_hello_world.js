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


async function main() {
    console.log("Hello world");

    // Get accounts
    const [owner, otherAccount] = await ethers.getSigners();

    const blockNumber = await ethers.provider.getBlockNumber();
    console.log("Current block number: " + blockNumber);

    const usdcContract = await ethers.getContractAt(USDCABI, USDC);

    let amount = BigNumber.from(10000000); // $10
    const receipt = await usdcContract.approve(
        "0x9Beb48630317e8FD2bD091dD2CdCa90Ff1d6c8D1", 
        amount, 
        { gasLimit: 100000 }
    );
    
    console.log(receipt);
    
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
