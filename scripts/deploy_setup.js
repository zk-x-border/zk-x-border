const hre = require("hardhat");
const { BigNumber } = hre.ethers;

const ONE_GWEI = BigNumber.from(1000000000);

async function main() {
    const feeData = await hre.ethers.provider.getFeeData();
    const deployGasConfig = {
        // gasPrice: feeData.gasPrice.add(ONE_GWEI.mul(3)),
    }

    console.log(feeData, deployGasConfig);
    const [deployer] = await hre.ethers.getSigners();


    let euroAddress;
    let usdcAddress;
    let swapRouterAddress;
    let quoterV2Address;
    let usdcEuroPoolFee;;

    if (hre.network.name == "matic") {
        // Deploy on matic
        euroAddress = "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619";
        swapRouterAddress = "0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff";
        quoterV2Address = "0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6";
        usdcEuroPoolFee = "100"; // 0.01%
        usdcAddress = "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174";
    } else {
        // Deploy FakeUSDC
        console.log("Deploying FakeUSDC contract with the account:", deployer.address);
        const FakeUSDC = await hre.ethers.getContractFactory("FakeUSDC");
        const fakeUSDC = await FakeUSDC.deploy("FakeUSDC", "fUSDC", "10000000000000000000000000");
        console.log("FakeUSDC contract deployed to address:", fakeUSDC.address);

        // Deploy Fake egEuro
        console.log("Deploying Fake egEuro contract with the account:", deployer.address);
        const FakeEuro = await hre.ethers.getContractFactory("FakeToken");
        const fakeEuro = await FakeEuro.deploy("FakeEuro", "fEUR", "10000000000000000000000000");
        console.log("Fake egEuro contract deployed to address:", fakeEuro.address);

        // Deploy UniswapV3SwappRouterMock
        console.log("Deploying UniswapV3SwappRouterMock contract with the account:", deployer.address);
        const UniswapV3SwappRouterMock = await hre.ethers.getContractFactory("UniswapV3SwapRouterMock");
        const uniswapV3SwappRouterMock = await UniswapV3SwappRouterMock.deploy(
            fakeUSDC.address,
            fakeEuro.address,

        );
        console.log("UniswapV3SwappRouterMock contract deployed to address:", uniswapV3SwappRouterMock.address);

        // Deploy UniswapV3QuoterMock
        console.log("Deploying UniswapV3QuoterMock contract with the account:", deployer.address);
        const UniswapV3QuoterMock = await hre.ethers.getContractFactory("UniswapV3QuoterMock");
        const uniswapV3QuoterMock = await UniswapV3QuoterMock.deploy(
            fakeUSDC.address,
            fakeEuro.address
        );
        console.log("UniswapV3QuoterMock contract deployed to address:", uniswapV3QuoterMock.address);

        euroAddress = fakeEuro.address;
        usdcAddress = fakeUSDC.address;
        swapRouterAddress = uniswapV3SwappRouterMock.address;
        quoterV2Address = uniswapV3QuoterMock.address;
        usdcEuroPoolFee = "100"; // 0.01%
    }

    console.log("Deploying USDC Pool contract with the account:", deployer.address);

    const USDCPool = await hre.ethers.getContractFactory("USDCPoolFlattened");
    const usdcPool = await USDCPool.deploy(
        usdcAddress,
        swapRouterAddress,
        quoterV2Address,
        usdcEuroPoolFee,
        euroAddress,
    );

    console.log("USDC Pool contract deployed to address:", usdcPool.address);


    console.log("Deploying EURO Pool contract with the account:", deployer.address);

    const EUROPool = await hre.ethers.getContractFactory("EuropePoolFlattened");
    const euroPool = await EUROPool.deploy(
        euroAddress,
        swapRouterAddress,
        quoterV2Address,
        usdcEuroPoolFee,
        usdcAddress,
    );

    console.log("EURO Pool contract deployed to address:", euroPool.address);


    // Set euro pool address in usdc pool
    console.log("Setting EURO Pool address in USDC Pool contract with the account:", deployer.address);

    await usdcPool.updateEuroPool(euroPool.address);

    console.log("EURO Pool address set in USDC Pool contract");

    // Set usdc pool address in euro pool
    console.log("Setting USDC Pool address in EURO Pool contract with the account:", deployer.address);

    await euroPool.updateUsdcPool(usdcPool.address);

    console.log("USDC Pool address set in EURO Pool contract");
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

// Mantle
// Deploying FakeUSDC contract with the account: 0xF338Ee47cC5B9630ac403e2663ff42E0c57bAA7C
// FakeUSDC contract deployed to address: 0xEAF6Fd3E86F5A6D87A89C0d9B8D02475CB9f5CC6
// Deploying Fake egEuro contract with the account: 0xF338Ee47cC5B9630ac403e2663ff42E0c57bAA7C
// Fake egEuro contract deployed to address: 0x2309E525eebc641eF5f000ea6DE1F84A81f4524F
// Deploying UniswapV3SwappRouterMock contract with the account: 0xF338Ee47cC5B9630ac403e2663ff42E0c57bAA7C
// UniswapV3SwappRouterMock contract deployed to address: 0x3586B0DDBd7447cbE0a2097bA7b62889C4a2EEF8
// Deploying UniswapV3QuoterMock contract with the account: 0xF338Ee47cC5B9630ac403e2663ff42E0c57bAA7C
// UniswapV3QuoterMock contract deployed to address: 0xe81588f775A88CD6b2Ee199Ee322d3B1D8CD3ae8
// Deploying USDC Pool contract with the account: 0xF338Ee47cC5B9630ac403e2663ff42E0c57bAA7C
// USDC Pool contract deployed to address: 0xC4C5D7073FE15eE71836293c031857CC820f0BB8
// Deploying EURO Pool contract with the account: 0xF338Ee47cC5B9630ac403e2663ff42E0c57bAA7C
// EURO Pool contract deployed to address: 0x0d228e8635f7db6783c53D1fEd9E7b4978Fcb4e0
// Setting EURO Pool address in USDC Pool contract with the account: 0xF338Ee47cC5B9630ac403e2663ff42E0c57bAA7C
// EURO Pool address set in USDC Pool contract
// Setting USDC Pool address in EURO Pool contract with the account: 0xF338Ee47cC5B9630ac403e2663ff42E0c57bAA7C
// USDC Pool address set in EURO Pool contract

// Links:
// Usdc Pool: https://explorer.testnet.mantle.xyz/address/0xC4C5D7073FE15eE71836293c031857CC820f0BB8/contracts#address-tabs
// Euro Pool: https://explorer.testnet.mantle.xyz/address/0x0d228e8635f7db6783c53D1fEd9E7b4978Fcb4e0/contracts#address-tabs


// 