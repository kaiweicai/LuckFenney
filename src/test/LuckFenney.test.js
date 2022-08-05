const {ethers} = require("hardhat");
const { expect } = require("chai");
const { BigNumber } = ethers;
const {BN} = require('@openzeppelin/test-helpers');
const { time } = require("./shared")
const { ADDRESS_ZERO } = require("./shared");


let owner, user, alice;
let luckFenney;

const usdtAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
const usdt1Address = "0xce4Ec2a346b817C808C803A5696123eaA1FFBEBa";
const token1Address = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
const token2Address = "0x8dAEBADE922dF735c38C80C7eBD708Af50815fAa";
const token3Address = "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599";
const tokenBddress = "0xdAC17F958D2ee523a2206206994597C13D831ec7";
const tokenB1ddress = "0xc443F00DB55eB74fBEa235fd904103F929d821B2";

async function withDecimals(amount) {
    return new BN(amount).mul(new BN(10).pow(new BN(18))).toString();
}

describe("luckFenney test", async function() {
    before(async function() {
        this.signers = await ethers.getSigners();
        owner = this.signers[0];
        user = this.signers[1];
        alice = this.signers[2];
        this.LuckFenneyFactory = await ethers.getContractFactory("LuckFenney");
    });

    beforeEach(async function() {
        luckFenney = await this.LuckFenneyFactory.deploy();
        await luckFenney.initialize();
        
    });

    it("initialize", async function() {
       let feneyOwner = await luckFenney.owner();
       expect(feneyOwner).to.be.equals(owner.address);
    });

    it("create Fenney", async function() {
        
    });

});
