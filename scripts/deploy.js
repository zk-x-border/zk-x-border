const hre = require("hardhat");
const { BigNumber } = hre.ethers;

const ONE_GWEI = BigNumber.from(1000000000);

async function main() {
    const feeData = await hre.ethers.provider.getFeeData();
    const deployGasConfig = {
        gasPrice: feeData.gasPrice.add(ONE_GWEI.mul(3)),
    }

    console.log(feeData, deployGasConfig);
    const [deployer] = await hre.ethers.getSigners();

    // const VenmoSendVerifier = await hre.ethers.getContractFactory("VenmoSendVerifier");
    // const venmoSendVerifier = await VenmoSendVerifier.deploy(deployGasConfig);
    // console.log("Venmo send verifier contract deployed to address:", venmoSendVerifier.address);
    const venmoSendVerifierAddress = "0xE0B52e49357Fd4DAf2c15e02058DCE6BC0057db4"; // random address

    const agEuroAddress = "0xE0B52e49357Fd4DAf2c15e02058DCE6BC0057db4";
    const swapRouterAddress = "0xE592427A0AEce92De3Edee1F18E0157C05861564";
    const quoterV2Address = "0x61fFE014bA17989E743c5F6cB21bF9697530B21e";
    const usdcEuroPoolFee = "100"; // 0.01%
    const usdcAddress = "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174";

    console.log("Deploying USDC Pool contract with the account:", deployer.address);

    const USDCPool = await hre.ethers.getContractFactory("USDCPool");
    const usdcPool = await USDCPool.deploy(
        venmoSendVerifierAddress,
        usdcAddress,
        swapRouterAddress,
        quoterV2Address,
        usdcEuroPoolFee,
        deployGasConfig,
        agEuroAddress,
    );

    console.log("USDC Pool contract deployed to address:", usdcPool.address);

    // Verify the contract on PolygonScan
    console.log("Verifying contract on PolygonScan...");

    try {
        await hre.run("verify:verify", {
            address: usdcPool.address,
            constructorArguments: [
                venmoSendVerifierAddress,
                agEuroAddress,
                swapRouterAddress,
                quoterV2Address,
                usdcEuroPoolFee,
                usdcAddress
            ],
        });
        console.log(`Contract verified successfully.`);
    } catch (error) {
        console.error("Contract verification failed.", error);
    }
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
