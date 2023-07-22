// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

// Lay out the const contrat instances
const USDC = "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174";


async function main() {
    console.log("Hello world");

    // Get accounts
    const [owner, otherAccount] = await ethers.getSigners();

    console.log(owner);

    // WHat are fixtures?

    // Get USDC balance of this account

    // Do a raw get state

    
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
