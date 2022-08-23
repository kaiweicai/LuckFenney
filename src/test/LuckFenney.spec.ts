import { MockProvider } from "ethereum-waffle";
import { Wallet } from "ethers";

import { ethers, waffle } from "hardhat";
import { expect } from "chai";
import { BigNumber } from "ethers";
const { ADDRESS_ZERO, expandTo18Decimals,time } = require("./shared");
import { LuckFenney } from "../types/LuckFenney";



describe("luckFenney test", async function () {
    const loadFixture = waffle.createFixtureLoader(
        waffle.provider.getWallets(),
        waffle.provider
    );

    async function v2Fixture([owner, user, alice, bob]: Wallet[], provider: MockProvider) {
        let LuckFenneyFactory = await ethers.getContractFactory("LuckFenney");
        let luckFenney = await LuckFenneyFactory.deploy();
        await luckFenney.initialize();
        return {
            owner, user, alice, bob, luckFenney
        }
    }


    it("initialize test", async function () {
        let { owner,luckFenney } = await loadFixture(v2Fixture);
        let fenneyOwner = await luckFenney.owner();
        expect(fenneyOwner).to.be.equals(owner.address);
    });

    it("create Fenney without rewards", async function () {
        let { owner,luckFenney } = await loadFixture(v2Fixture);
        await expect(luckFenney.createLuck(10,[],10)).to.be.revertedWith("LQBTMBLM");
        await expect(luckFenney.createLuck(100,[],0)).to.be.revertedWith("duration lt 0");
        await luckFenney.createLuck(100,[],100);
        let lucky = await luckFenney.getProducerLucks(owner.address);
        console.log("lucky is:",lucky);
    });

});
