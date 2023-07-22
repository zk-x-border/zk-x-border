const hre = require("hardhat");
const chai = require("chai");
const { solidity } = require("ethereum-waffle");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

chai.use(solidity);

const { expect } = chai;
const { BigNumber } = hre.ethers;

const venmoRsaKey = [
    "683441457792668103047675496834917209",
    "1011953822609495209329257792734700899",
    "1263501452160533074361275552572837806",
    "2083482795601873989011209904125056704",
    "642486996853901942772546774764252018",
    "1463330014555221455251438998802111943",
    "2411895850618892594706497264082911185",
    "520305634984671803945830034917965905",
    "47421696716332554",
    "0",
    "0",
    "0",
    "0",
    "0",
    "0",
    "0",
    "0"
];

const ZERO = BigNumber.from(0);

describe("USDC Pool", function () {
    let ramp;
    let fakeUSDC;
    let maxAmount;

    let deployer;
    let onRamper;
    let offRamper;
    let relayer;

    beforeEach(async function () {
        [deployer, onRamper, relayer, offRamper] = await hre.ethers.getSigners();

        console.log('Deploying fake USDC...')

        const FakeUSDC = await hre.ethers.getContractFactory("FakeUSDC");
        fakeUSDC = await FakeUSDC.deploy("Fake USDC", "fUSDC", 10000000000000);

        await fakeUSDC.connect(deployer).transfer(offRamper.address, 1000000000); // $1000

        console.log(fakeUSDC.address);
        console.log('Deploying USDC Pool...')


        // init a bunch of fake addresses
        let euroPool = "0xE0B52e49357Fd4DAf2c15e02058DCE6BC0057db4";
        let verifier = "0xE0B52e49357Fd4DAf2c15e02058DCE6BC0057db4";
        let swapRouter = "0xE0B52e49357Fd4DAf2c15e02058DCE6BC0057db4";
        let euro = "0xE0B52e49357Fd4DAf2c15e02058DCE6BC0057db4";
        let quoter = "0xE0B52e49357Fd4DAf2c15e02058DCE6BC0057db4";
        let usdcEuroPoolFee = "1000";

        const Ramp = await hre.ethers.getContractFactory("USDCPool");
        ramp = await Ramp.deploy(
            euroPool,
            verifier,
            fakeUSDC.address,
            swapRouter,
            quoter,
            usdcEuroPoolFee,
            euro,
        );
        console.log(ramp.address);
    });

    describe("createOrder", function () {
        let amount = BigNumber.from(10000000); // $10
        let offChainPaymentAddress = "MyParisianGirlfriend";

        it("creates an order", async function () {

            await fakeUSDC.connect(offRamper).approve(ramp.address, amount);

            await ramp.connect(offRamper).createOrder(amount, offChainPaymentAddress);

            const openOrder = await ramp.getOrder(1);       // first order

            expect(openOrder.amount).to.equal(amount);
            expect(openOrder.offChainPaymentAddress).to.equal(offChainPaymentAddress);
            expect(openOrder.claimed).to.equal(false);
        });
    });
});