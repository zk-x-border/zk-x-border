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

    describe("claimOrder", function () {
        let orderId = 1;

        beforeEach(async function () {
            let amount = BigNumber.from(10000000); // $10
            let offChainPaymentAddress = "MyParisianGirlfriend";

            await fakeUSDC.connect(offRamper).approve(ramp.address, amount);

            await ramp.connect(offRamper).createOrder(amount, offChainPaymentAddress);
        });

        it("should claim order", async function () {
            await ramp.connect(onRamper).claimOrder(orderId, "0x00");

            const openOrder = await ramp.getOrder(orderId);

            expect(openOrder.claimed).to.equal(true);
        });
    });


    describe("completeOnRampOrder", function () {

        let a = ["0x09f880318914368db9f055fdf61cacd81dca2c47b96c2ff8cd3609dfadcb353b", "0x07c494bb55a683c1013309303b061aca366f86073b0304d22b97dc5c602ebb4f"];
        let b = [
            ["0x1562b771233d15ca0e4fd6c43f7f783a32e1c4c060179b130a8e0d606206a5e7", "0x0ce9476295b8b42ae6be8b95ee9ae00675be05438199f66c5ddfaa22d659a33e"],
            ["0x1a2c8e4432e43f8d71db8624219064916e5a51e3d9b924470d2a8f56b7eab279", "0x2500443dc24546b62b317f1dd1d068953e0db1aca91ffb3d4be48eb2ab1e0ce4"]
        ];
        let c = ["0x070d784e2edf7185c5d4950c0fd83f44f6d41f566cb3707000dd8b6a378c797d", "0x0fd22f41f5c0c7cf9506caa0f0fc20d23426c9b93cd8f6e424bfb2547a741be6"];
        let signals = [
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

        beforeEach(async function () {
            let orderId = 1;
            let amount = BigNumber.from(10000000); // $10
            let offChainPaymentAddress = "2582207554125824967";

            await fakeUSDC.connect(offRamper).approve(ramp.address, amount);

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
