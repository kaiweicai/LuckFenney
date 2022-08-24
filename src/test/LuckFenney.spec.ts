import { MockProvider } from "ethereum-waffle";
import { Wallet } from "ethers";

import { ethers, waffle } from "hardhat";
import { expect } from "chai";
import { BigNumber } from "ethers";
const { ADDRESS_ZERO, expandTo18Decimals,time } = require("./shared");



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
        let luckyIds = await luckFenney.getProducerLucks(owner.address);
        console.log("lucky is:",luckyIds);
        expect(luckyIds[0]).to.be.equals(0);
        let currentId = await luckFenney.currentId();
        expect(currentId).to.be.equals(1);
        let lucky = await luckFenney.lucksMap(currentId.sub(1));
        console.log("lucky object is:",lucky);
        expect(lucky.producer).to.be.equals(owner.address);
    });

    it("create Fenney with erc20 rewards", async function () {
        let { owner,luckFenney } = await loadFixture(v2Fixture);
        let MyToken = await ethers.getContractFactory("MyERC20");
        let myRewardToken = await MyToken.deploy("myToken","myToken");
        let token20Amount = 1000;
        await myRewardToken.approve(luckFenney.address,token20Amount)
        await luckFenney.createLuck(100,[{token:myRewardToken.address,rewardType:0,amount:token20Amount,tokenId:0}],100);
        let luckyIds = await luckFenney.getProducerLucks(owner.address);
        console.log("lucky is:",luckyIds);
        expect(luckyIds[0]).to.be.equals(0);
        let currentId = await (await luckFenney.currentId()).sub(1);
        expect(currentId).to.be.equals(0);
        let lucky = await luckFenney.lucksMap(currentId);
        console.log("lucky object is:",lucky);
        expect(lucky.producer).to.be.equals(owner.address);
        let luckyBalanceOfReward = await myRewardToken.balanceOf(luckFenney.address);
        console.log("luckyBalanceOfReward is:",luckyBalanceOfReward);
        expect(luckyBalanceOfReward).to.be.equals(token20Amount);
    });

    it("create Fenney with ERC721 rewards", async function () {
        let { owner,luckFenney } = await loadFixture(v2Fixture);
        let MrErc721Factory = await ethers.getContractFactory("MyErc721Token");
        let my721Token = await MrErc721Factory.deploy();
        let tokenId = 0;
        await my721Token.safeMint(owner.address);
        await my721Token.approve(luckFenney.address,tokenId);
        await luckFenney.createLuck(100,[{token:my721Token.address,rewardType:1,amount:0,tokenId:tokenId}],100);
        let luckyIds = await luckFenney.getProducerLucks(owner.address);
        console.log("lucky is:",luckyIds);
        expect(luckyIds[0]).to.be.equals(0);
        let currentId = await (await luckFenney.currentId()).sub(1);
        expect(currentId).to.be.equals(0);
        let lucky = await luckFenney.lucksMap(currentId);
        console.log("lucky object is:",lucky);
        expect(lucky.producer).to.be.equals(owner.address);
        let luckyBalanceOfReward = await my721Token.balanceOf(luckFenney.address);
        console.log("luckyBalanceOfReward is:",luckyBalanceOfReward);
        expect(luckyBalanceOfReward).to.be.equals(1);
    });

    it("create Fenney with ERC1155 rewards", async function () {
        let { owner,luckFenney } = await loadFixture(v2Fixture);
        let MrErc1155Factory = await ethers.getContractFactory("MyErc1155Token");
        let my1155Token = await MrErc1155Factory.deploy();
        let tokenId = 0;
        let amountOf1155 = 100;
        await my1155Token.mint(owner.address,amountOf1155);
        await my1155Token.setApprovalForAll(luckFenney.address,true);
        await luckFenney.createLuck(100,[{token:my1155Token.address,rewardType:2,amount:amountOf1155,tokenId:tokenId}],100);
        let luckyIds = await luckFenney.getProducerLucks(owner.address);
        console.log("lucky is:",luckyIds);
        expect(luckyIds[0]).to.be.equals(0);
        let currentId = await (await luckFenney.currentId()).sub(1);
        expect(currentId).to.be.equals(0);
        let lucky = await luckFenney.lucksMap(currentId);
        console.log("lucky object is:",lucky);
        expect(lucky.producer).to.be.equals(owner.address);
        let luckyBalanceOfReward = await my1155Token.balanceOf(luckFenney.address,tokenId);
        console.log("luckyBalanceOfReward is:",luckyBalanceOfReward);
        expect(luckyBalanceOfReward).to.be.equals(amountOf1155);
        let rewards = await luckFenney.getLuckyRewards(currentId);
        console.log("rewards is:",rewards);
    });

});
