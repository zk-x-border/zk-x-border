const hre = require("hardhat");
const chai = require("chai");
const { solidity } = require("ethereum-waffle");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

chai.use(solidity);

const { expect } = chai;
const { BigNumber } = hre.ethers;


const ZERO = BigNumber.from(0);

describe("EURO Pool", function () {
    let ramp;
    let verifier;
    let fakeEuro;
    let maxAmount;

    let deployer;
    let onRamper;
    let offRamper;
    let relayer;

    beforeEach(async function () {
        [deployer, onRamper, relayer, offRamper] = await hre.ethers.getSigners();

        console.log('Deploying fake USDC...')

        const FakeUSDC = await hre.ethers.getContractFactory("FakeUSDC");
        fakeEuro = await FakeUSDC.deploy("Fake USDC", "fUSDC", 10000000000000);

        await fakeEuro.connect(deployer).transfer(offRamper.address, 1000000000); // $1000

        console.log(fakeEuro.address);
        console.log('Deploying EURO Pool...')


        // init a bunch of fake addresses
        let usdPool = "0xE0B52e49357Fd4DAf2c15e02058DCE6BC0057db4";
        let swapRouter = "0xE0B52e49357Fd4DAf2c15e02058DCE6BC0057db4";
        let usdc = "0xE0B52e49357Fd4DAf2c15e02058DCE6BC0057db4";
        let quoter = "0xE0B52e49357Fd4DAf2c15e02058DCE6BC0057db4";
        let usdcEuroPoolFee = "1000";

        const RevolutSendVerifier = await hre.ethers.getContractFactory("RevolutSendVerifier");
        verifier = await RevolutSendVerifier.deploy();
        console.log(verifier.address);

        const Ramp = await hre.ethers.getContractFactory("EuropePool");
        ramp = await Ramp.deploy(
            usdPool,
            verifier.address,
            fakeEuro.address,
            swapRouter,
            quoter,
            usdcEuroPoolFee,
            usdc,
        );
        console.log(ramp.address);
    });

    describe("createOrder", function () {
        let amount = BigNumber.from(10000000); // $10
        let offChainPaymentAddress = "MyAmericanGirlfriend"; // Yes, I have two girlfriends

        it("creates an order", async function () {

            await fakeEuro.connect(offRamper).approve(ramp.address, amount);

            await ramp.connect(offRamper).createOrder(amount, offChainPaymentAddress);

            const openOrder = await ramp.getOrder(1);       // first order

            expect(openOrder.amount).to.equal(amount);
            expect(openOrder.offChainPaymentAddress).to.equal(offChainPaymentAddress);
            expect(openOrder.claimed).to.equal(false);
        });
    });

    describe("claimOrder", function () {
        let orderId = 1;

        beforeEach(async function () {
            let amount = BigNumber.from(10000000); // $10
            let offChainPaymentAddress = "MyParisianGirlfriend";

            await fakeEuro.connect(offRamper).approve(ramp.address, amount);

            await ramp.connect(offRamper).createOrder(amount, offChainPaymentAddress);
        });

        it("should claim order", async function () {
            await ramp.connect(onRamper).claimOrder(orderId, "0x00");

            const openOrder = await ramp.getOrder(orderId);

            expect(openOrder.claimed).to.equal(true);
        });
    });


    describe("completeOnRampOrder", function () {

        let a = ["0x2161c9033287a1a0770e664fb12bacfb5ea0360fdb2a0b52a7dc3e22b01e97ea", "0x2b69551363c03f2ed145ede80b3465f38ddc416f38954989076dc28e3df9767c"];
        let b = [
            ["0x30012c7fa027e5c31aba809264e48ef98d353f222ecc88fc7d4b979fc887901a", "0x2b2c94ce0990560207680836e464f0d0376bf85497f6c6ac273cab851588e202"],
            ["0x171c365446861a00f1d4fa98c041db44c05475b6563f2f03b39da4d1fdec27b2", "0x181a5061dae966acd2e4ff88c24ce043444bf5a5a1435b8d1dd470d3a210fb1c"]
        ];
        let c = ["0x13b482e67e8ed96fe8a2bd6f947580d2ef7f9b6cf97175ea99131371fb5c8e9f", "0x2baf66fa65f9253764aaa67560a350a17852002ae1f3d523465030fa1570a5bf"];
        let signals = [
            "0x0000000000000000000000000000000000000000000000000000003030302c32",
            "0x0000000000000000000000000000000000000000000000000000000000000000",
            "0x0000000000000000000000000000000000000000000000000000000000000000",
            "0x0000000000000000000000000000000000000000000000000000000000000000",
            "0x0000000000000000000000000000000000000000000000000000000000000000",
            "0x0000000000000000000000000000000000000000000000000034303030355450",
            "0x0000000000000000000000000000000000000000000000000058580a0d3d5835",
            "0x0000000000000000000000000000000000000000000000000058585858585858",
            "0x0000000000000000000000000000000000000000000000000033343231585858",
            "0x0000000000000000000000000000000000000000000000000000000000000000",
            "0x0000000000000000000000000000000001a39233215a1dac06b9c12b093d0c19",
            "0x000000000000000000000000000000000001eb0a67fb00ee04ac19e10bdd1780",
            "0x0000000000000000000000000000000000000000000000000000000000003c50",
            "0x0000000000000000000000000000000001058481b16c0c6bc68b612881d69109",
            "0x00000000000000000000000000000000017fd23efa54659bcfc805b3d06649d6",
            "0x000000000000000000000000000000000100aa2baa3c1b6ef87468ec5bc14f73",
            "0x0000000000000000000000000000000001c43bddf64aeafd7faffc39c2911ba5",
            "0x00000000000000000000000000000000016ad3c248dd353b192e38cccf34a01f",
            "0x0000000000000000000000000000000001d80b82a4f6cead025d04200087be3f",
            "0x0000000000000000000000000000000001b87939bd34a27fa069022ecf22cd31",
            "0x0000000000000000000000000000000001d73d3916dbbf584bc426b675efa1f4",
            "0x00000000000000000000000000000000000000000000000000ac4c64b591c821",
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



        beforeEach(async function () {
            let orderId = 1;
            let amount = BigNumber.from(10000000); // $10
            let offChainPaymentAddress = "5000451243";

            await fakeEuro.connect(offRamper).approve(ramp.address, amount);

            await ramp.connect(offRamper).createOrder(amount, offChainPaymentAddress);

            await ramp.connect(onRamper).claimOrder(orderId, "0x00");
        });


        it("should complete on ramp order", async function () {

            await ramp.connect(onRamper).completeOnRampOrder(
                [
                    a,
                    b,
                    c
                ],
                signals
            );


        });
    });

});
