import { MockProvider } from "ethereum-waffle";
import { Wallet } from "ethers";


import { ethers, waffle } from "hardhat";
import { expect } from "chai";
import { BigNumber } from "ethers";
import { ERC20 } from "../types";
const { ADDRESS_ZERO,time } = require("./shared");
import {
    expandTo18Decimals,
    getApprovalDigest,
    MINIMUM_LIQUIDITY,
    setNextBlockTime,
  } from "./shared/utilities";



describe("luckFenney test", async function () {
    const loadFixture = waffle.createFixtureLoader(
        waffle.provider.getWallets(),
        waffle.provider
    );

    async function v2Fixture([owner, user, alice, bob]: Wallet[], provider: MockProvider) {
        let LuckFenneyFactory = await ethers.getContractFactory("LuckFenney");
        let luckFenney = await LuckFenneyFactory.deploy();
        let ERC20Factory = await ethers.getContractFactory("MyERC20");
        let platformToken = await ERC20Factory.deploy();
        await platformToken.initialize("platformToken","platformToken");
        platformToken.transferOwnership(luckFenney.address);
        await luckFenney.initialize(platformToken.address,expandTo18Decimals(5),expandTo18Decimals(1));
        return {
            owner, user, alice, bob, luckFenney,platformToken
        }
    }


    it("initialize test", async function () {
        let { owner,luckFenney } = await loadFixture(v2Fixture);
        let fenneyOwner = await luckFenney.owner();
        expect(fenneyOwner).to.be.equals(owner.address);
    });

    it("create Fenney without rewards", async function () {
        let { owner,luckFenney } = await loadFixture(v2Fixture);
        let participation = 400;
        await expect(luckFenney.createLuck(10,[],10,participation)).to.be.revertedWith("LQBTMBLM");
        await expect(luckFenney.createLuck(100,[],0,participation)).to.be.revertedWith("duration lt 0");
        await luckFenney.createLuck(100,[],100,participation);
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
        let myRewardToken = await MyToken.deploy();
        await myRewardToken.initialize("myrewardToken","myRewardToken");
        await myRewardToken.mint(owner.address,expandTo18Decimals(1000));
        let token20Amount = 1000;
        await myRewardToken.approve(luckFenney.address,token20Amount)
        let participation = 400;
        await luckFenney.createLuck(100,[{token:myRewardToken.address,rewardType:0,amount:token20Amount,tokenId:0}],100,participation);
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
        let participation = 400;
        await luckFenney.createLuck(100,[{token:my721Token.address,rewardType:1,amount:0,tokenId:tokenId}],100,participation);
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
        let participation = 400;
        await luckFenney.createLuck(100,[{token:my1155Token.address,rewardType:2,amount:amountOf1155,tokenId:tokenId}],100,participation);
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

    it("create Fenney with ERC20,ERC721,ERC1155 rewards", async function () {
        let { owner,luckFenney } = await loadFixture(v2Fixture);
        let MrErc1155Factory = await ethers.getContractFactory("MyErc1155Token");
        let my1155Token = await MrErc1155Factory.deploy();
        let erc1155TokenId = 0;
        let amountOf1155 = 100;
        await my1155Token.mint(owner.address,amountOf1155);
        await my1155Token.setApprovalForAll(luckFenney.address,true);

        let MrErc721Factory = await ethers.getContractFactory("MyErc721Token");
        let my721Token = await MrErc721Factory.deploy();
        await my721Token.safeMint(owner.address);
        await my721Token.approve(luckFenney.address,erc1155TokenId);
        let ecr721TokenId = 0;
        let token721Reward = {token:my721Token.address,rewardType:1,amount:0,tokenId:ecr721TokenId};
        let token1155Reward = {token:my1155Token.address,rewardType:2,amount:amountOf1155,tokenId:erc1155TokenId};

        //add erc20 reward
        let MyToken = await ethers.getContractFactory("MyERC20");
        let myErc20Token = await MyToken.deploy();
        let token20Amount = 1000;
        await myErc20Token.initialize("myToken","myToken");
        await myErc20Token.mint(owner.address,expandTo18Decimals(1000));
        await myErc20Token.approve(luckFenney.address,token20Amount);
        let token20Reward = {token:myErc20Token.address,rewardType:0,amount:token20Amount,tokenId:0};
        let currentBlock = await time.latestBlock();
        console.log("currentTime is:",currentBlock);
        let duration = 100;
        let participation = 400;
        await luckFenney.createLuck(100,[token20Reward,token1155Reward,token721Reward],duration,participation);
        let luckyIds = await luckFenney.getProducerLucks(owner.address);
        console.log("lucky is:",luckyIds);
        expect(luckyIds[0]).to.be.equals(0);
        let currentId = await (await luckFenney.currentId()).sub(1);
        expect(currentId).to.be.equals(0);
        let lucky = await luckFenney.lucksMap(currentId);
        expect(currentBlock+1).to.be.equals(lucky.startBlock);
        let endBlock = lucky.endBlock;
        expect(endBlock).to.be.equals(currentBlock+1+duration);
        // console.log("lucky object is:",lucky);
        expect(lucky.producer).to.be.equals(owner.address);
        let luckyBalanceOf1155Reward = await my1155Token.balanceOf(luckFenney.address,erc1155TokenId);
        console.log("luckyBalanceOfReward is:",luckyBalanceOf1155Reward);
        expect(luckyBalanceOf1155Reward).to.be.equals(amountOf1155);
        let luckyBalanceOf721Reward = await my721Token.balanceOf(luckFenney.address);
        console.log("luckyBalanceOfReward is:",luckyBalanceOf721Reward);
        expect(luckyBalanceOf721Reward).to.be.equals(1);

        let luckyBalance20OfReward = await myErc20Token.balanceOf(luckFenney.address);
        console.log("luckyBalanceOfReward is:",luckyBalance20OfReward);
        expect(luckyBalance20OfReward).to.be.equals(token20Amount);
        let rewards = await luckFenney.getLuckyRewards(currentId);
        // console.log("rewards is:",rewards);
        let luckyState = lucky.state;
        expect(luckyState).to.be.equals(1);
        let participation_cost = lucky.participation_cost;
        console.log("participation_cost is:",participation_cost);
    });


    describe("luckFenney test enter", async function () {
        it("create Fenney with ERC20,ERC721,ERC1155 rewards for enter", async function () {
            let { owner,luckFenney,user,alice,platformToken } = await loadFixture(v2Fixture);
            let MrErc1155Factory = await ethers.getContractFactory("MyErc1155Token");
            let my1155Token = await MrErc1155Factory.deploy();
            let erc1155TokenId = 0;
            let amountOf1155 = 100;
            await my1155Token.mint(owner.address,amountOf1155);
            await my1155Token.setApprovalForAll(luckFenney.address,true);
    
            let MrErc721Factory = await ethers.getContractFactory("MyErc721Token");
            let my721Token = await MrErc721Factory.deploy();
            await my721Token.safeMint(owner.address);
            await my721Token.approve(luckFenney.address,erc1155TokenId);
            let ecr721TokenId = 0;
            let token721Reward = {token:my721Token.address,rewardType:1,amount:0,tokenId:ecr721TokenId};
            let token1155Reward = {token:my1155Token.address,rewardType:2,amount:amountOf1155,tokenId:erc1155TokenId};
    
            //add erc20 reward
            let MyToken = await ethers.getContractFactory("MyERC20");
            let myErc20Token = await MyToken.deploy();
            await myErc20Token.initialize("myToken","myToken");
            await myErc20Token.mint(owner.address,expandTo18Decimals(1000));
            let token20Amount = 1000;
            await myErc20Token.approve(luckFenney.address,token20Amount);
            let token20Reward = {token:myErc20Token.address,rewardType:0,amount:token20Amount,tokenId:0};
            let currentBlock = await time.latestBlock();
            let duration = 100;
            let participation = 400;
            let initializeQuantity = 100;
            await luckFenney.createLuck(initializeQuantity,[token20Reward,token1155Reward,token721Reward],duration,participation);
            let luckyIds = await luckFenney.getProducerLucks(owner.address);
            expect(luckyIds[0]).to.be.equals(0);
            let currentId = await (await luckFenney.currentId()).sub(1);
            expect(currentId).to.be.equals(0);
            let lucky = await luckFenney.lucksMap(currentId);
            expect(currentBlock+1).to.be.equals(lucky.startBlock);
            let endBlock = lucky.endBlock;
            expect(endBlock).to.be.equals(currentBlock+1+duration);
            expect(lucky.producer).to.be.equals(owner.address);
            let luckyBalanceOf1155Reward = await my1155Token.balanceOf(luckFenney.address,erc1155TokenId);
            expect(luckyBalanceOf1155Reward).to.be.equals(amountOf1155);
            let luckyBalanceOf721Reward = await my721Token.balanceOf(luckFenney.address);
            expect(luckyBalanceOf721Reward).to.be.equals(1);
            let luckyBalance20OfReward = await myErc20Token.balanceOf(luckFenney.address);
            expect(luckyBalance20OfReward).to.be.equals(token20Amount);
            let rewards = await luckFenney.getLuckyRewards(currentId);
            let luckyState = lucky.state;
            expect(luckyState).to.be.equals(1);
            

            //用户参与抽奖
            await expect(luckFenney.connect(user).enter(1,{from:user.address})).to.be.revertedWith("not open");
            await expect(luckFenney.connect(user).enter(0,{from:user.address})).to.be.revertedWith("value error");
            await expect(luckFenney.connect(user).enter(0,{from:user.address,value:10})).to.be.revertedWith("value error");
            let attendAmount = 3000;
            await luckFenney.connect(user).enter(0,{from:user.address,value:attendAmount});
            let luckyAfterEnter = await luckFenney.lucksMap(currentId);
            let balanceOfLucky = await ethers.provider.getBalance(luckFenney.address);
            console.log("balanceOfLucky is:",balanceOfLucky);
            expect(balanceOfLucky).to.be.equals(attendAmount - attendAmount%participation);
            console.log("lucky.currentQuantity is:",luckyAfterEnter.currentQuantity);
            let attend = BigNumber.from(attendAmount).div(participation);
            console.log("attend is:",attend);
            expect(luckyAfterEnter.currentQuantity).to.be.equals(attend);
            let quantity = luckyAfterEnter.quantity;
            expect(quantity).to.be.equals(initializeQuantity);
            let attendUserAddress = await luckFenney.userAttends(currentId ,luckyAfterEnter.currentQuantity);
            expect(attendUserAddress).to.be.equals(user.address);

            //再给用户购买100个超出总彩票异常
            await expect(luckFenney.connect(user).enter(0,{from:user.address,value:attendAmount*100})).to.be.revertedWith("too attends");

            await time.advanceBlockTo(200);
            await expect(luckFenney.connect(user).enter(0,{from:user.address,value:10})).to.be.revertedWith("over endBlock");
            let userBalanceOfPlatform = await platformToken.balanceOf(user.address);
            let ownerBalanceOfPlatform = await platformToken.balanceOf(owner.address);
            
            let userRewardAmount = attend.mul(expandTo18Decimals(5));
            let ownerRewardAmount = attend.mul(expandTo18Decimals(1));
            expect(userRewardAmount).to.be.equals(userBalanceOfPlatform);
            expect(ownerRewardAmount).to.be.equals(ownerBalanceOfPlatform);
        });

    });
});
