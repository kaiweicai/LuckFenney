// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./libraries/TransferHelper.sol";
import "./libraries/RandomNumber.sol";
import "hardhat/console.sol";

contract LuckFenney is
    ERC721Holder,
    ERC1155Holder,
    OwnableUpgradeable,
    RandomNumber
{
    // using TransferHelper for address;
    uint256 constant QuantityMin = 10;
    uint256 constant QuantityMax = 10000;
    uint256 public currentId = 0;
    uint256 public feeRatio;
    uint256 public feePledgeRatio;
    uint256 public constant base = 10000;
    address public pledgeAddress;
    address public platformAddress;
    mapping(address => uint256[]) public producerLucks;
    mapping(uint256 => Lucky) public lucksMap;
    mapping(uint256 => Reward[]) public luckyRewards;
    uint256[] public runningLucks;
    IERC20 public paltformToken;
    uint256 public attendRewardAmount; // 用户参与奖励平台token的数量。
    uint256 public holderRewardAmount; // 用户参与奖励平台token的数量。
    mapping(uint256 => mapping(uint256 => address)) public luckAttenduser; // 用户参与的 luckId=>attendId=>address
    mapping(address => mapping(uint256 => uint256[])) public userAttendsLuck; // 用户参与的 address=>luckId=>attendId
    mapping(address => bool) public isManager;
    event SetManager(address manager, bool flag);

    modifier onlyManager() {
        require(isManager[_msgSender()], "Not manager");
        _;
    }

    struct Lucky {
        address producer; // the project
        uint256 id;
        uint256 quantity; //计划该luck参与人数
        uint256 endBlock; //持续时间
        uint256 startBlock;
        LuckyState state;
        uint256 ethAmount; // 奖品eth的数量
        uint256[] erc721TokenIds;
        uint256 participation_cost; // 参与的花费。
        uint256 currentQuantity; //已经参加的用户的个数。
        uint256 winnerId;
        address winnerAddress;
    }

    struct Reward {
        address token;
        RewardType rewardType;
        uint256 amount;
        uint256 tokenId;
    }

    enum RewardType {
        ERC20,
        ERC721,
        ERC1155
    }

    enum LuckyState {
        CREATE,
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }

    event LuckCreated(uint256 LuckID, address creator);

    function initialize(
        IERC20 paltformToken_,
        uint256 userReward_,
        uint256 holderReward_,
        address pledgeAddress_,
        address platformAddress_
    ) public initializer {
        __Ownable_init();
        paltformToken = paltformToken_;
        isManager[_msgSender()] = true;
        attendRewardAmount = userReward_;
        holderRewardAmount = holderReward_;
        feeRatio = 500;
        feePledgeRatio = 8000;
        pledgeAddress = pledgeAddress_;
        platformAddress = platformAddress_;
    }

    /// parameters
    /// quantity - max quantity of attend users
    function createLuck(
        uint256 quantity,
        Reward[] memory rewards,
        uint256 duration,
        uint256 participationCost_
    ) public payable returns (Lucky memory luck) {
        currentId += 1;
        // require(rewards.length > 0, "RLBTZ");
        require(quantity >= QuantityMin && quantity <= QuantityMax, "LQBTMBLM");
        require(duration > 0, "duration lt 0");
        luck.quantity = quantity;
        // 设置创建人
        luck.producer = msg.sender;
        uint256 ethAmount = msg.value;
        require(ethAmount > 0, "ethAmount engough");
        luck.ethAmount = ethAmount;

        luck.startBlock = block.number;
        luck.endBlock = luck.startBlock + duration;
        luck.participation_cost = participationCost_;
        // require(luck.deadline > block.number, "RLBTZ");
        // TODO 收钱，并且确认收钱的数量。注意weth9的收取。
        // TODO 收取eth
        for (uint256 i = 0; i < rewards.length; i++) {
            luckyRewards[currentId].push(rewards[i]);
            Reward memory reward = rewards[i];
            if (reward.rewardType == RewardType.ERC20) {
                IERC20(reward.token).transferFrom(
                    msg.sender,
                    address(this),
                    reward.amount
                );
            } else if (reward.rewardType == RewardType.ERC721) {
                // address from, address to,uint256 tokenId,bytes calldata data
                IERC721(reward.token).safeTransferFrom(
                    msg.sender,
                    address(this),
                    reward.tokenId,
                    new bytes(0)
                );
            } else if (reward.rewardType == RewardType.ERC1155) {
                // address from,address to,uint256 id,uint256 amount,bytes calldata data
                IERC1155(reward.token).safeTransferFrom(
                    msg.sender,
                    address(this),
                    reward.tokenId,
                    reward.amount,
                    new bytes(0)
                );
            }
        }

        luck.id = currentId;
        //添加正在运行抽奖，并且修改状态。
        addRunningLucks(luck);
        console.log("currentId1 is:", currentId);
        producerLucks[msg.sender].push(currentId);
        lucksMap[luck.id] = luck;
    }

    function addRunningLucks(Lucky memory luck) internal {
        luck.state = LuckyState.OPEN;
        console.log("luck.id is:", luck.id);
        runningLucks.push(luck.id);
    }

    // 用户参与luck
    function enter(uint256 luckId) public payable {
        Lucky storage luckFenney = lucksMap[luckId];
        require(luckFenney.state == LuckyState.OPEN, "not open");
        require(block.number < luckFenney.endBlock, "over endBlock");
        uint256 value = msg.value;
        require(
            value > 0 && value / luckFenney.participation_cost > 0,
            "value error"
        );
        console.log("-------------1");
        // 分配用户号给用户。
        uint256 attendAmount = value / luckFenney.participation_cost;
        // 检查是否用户已经满员了。
        require(
            luckFenney.currentQuantity + attendAmount <= luckFenney.quantity,
            "too attends"
        );
        console.log("-------------2");
        for (uint256 i = 0; i < attendAmount; i++) {
            luckFenney.currentQuantity += 1;
            address useAddress = msg.sender;
            luckAttenduser[luckId][luckFenney.currentQuantity] = msg.sender;
            userAttendsLuck[useAddress][luckId].push(
                luckFenney.currentQuantity
            );
        }
        console.log(
            "-------------3 attendAmount,holderRewardAmount is:",
            attendAmount,
            holderRewardAmount
        );
        // 奖励用户平台token
        paltformToken.mint(msg.sender, attendAmount * attendRewardAmount);
        //发起者发放代币
        paltformToken.mint(
            luckFenney.producer,
            attendAmount * holderRewardAmount
        );

        // 退还用户的多余的资金。
        uint256 leftEth = value % luckFenney.participation_cost;
        console.log("lefEth is: ", leftEth);
        TransferHelper.safeTransferETH(msg.sender, leftEth);
    }

    function getUserAttendsLuck(address user, uint256 luckId)
        public
        view
        returns (uint256[] memory)
    {
        return userAttendsLuck[user][luckId];
    }

    // //Random number generation from block timestamp
    // function getRandomNumber(uint256 luckId) public view returns (uint){
    //     uint blockTime = block.timestamp;
    //     return uint(keccak256(abi.encodePacked(blockTime)));
    // }

    // pick_winner
    function pickWinner(uint256 luckId)
        public
        returns (uint256 winnerId, address winnerAddress)
    {
        //not check the msg sender is holder ,let any one can end the this game.
        Lucky storage luckFenney = lucksMap[luckId];
        require(luckFenney.state == LuckyState.OPEN, "close but not open");
        luckFenney.state = LuckyState.CLOSED;
        require(luckFenney.endBlock <= block.number, "not end");
        //check currentQuantity >0
        uint256 attendQuantity = luckFenney.currentQuantity;
        require(attendQuantity > 0, "not attend amount");
        // start pickwinner;
        uint256 randomNumber = randomNumber(luckId);
        winnerId = (randomNumber % luckFenney.quantity) + 1;
        luckFenney.winnerId = winnerId;
        winnerAddress = luckAttenduser[luckId][winnerId];
        if (winnerAddress == address(0)) {
            winnerAddress = luckFenney.producer;
        }
        luckFenney.winnerAddress = winnerAddress;

        console.log("luckFenney.ethAmount is:",luckFenney.ethAmount);
        TransferHelper.safeTransferETH(winnerAddress, luckFenney.ethAmount);

        //delivery the erc20,erc721,erc1155 reward tokens
        deliveryTokenReward(winnerAddress, luckId);
        console.log("++++++++++7");

        uint256 receiveEth = luckFenney.currentQuantity *
            luckFenney.participation_cost;
        uint256 leftAmount = handleFee(receiveEth);
        console.log(
            "++++++++++8 receiveEth,leftAmount is:",
            receiveEth,
            leftAmount
        );
        TransferHelper.safeTransferETH(luckFenney.producer, leftAmount);
        console.log("++++++++++9");
    }

    function deliveryTokenReward(address winnner, uint256 luckId) private {
        Reward[] memory rewards = getLuckyRewards(luckId);
        console.log("++++++++++1");
        for (uint256 i = 0; i < rewards.length; i++) {
            Reward memory reward = rewards[i];
            console.log("++++++++++2");
            if (reward.rewardType == RewardType.ERC20) {
                console.log("++++++++++3");
                IERC20(reward.token).transfer(winnner, reward.amount);
                console.log("++++++++++4");
            } else if (reward.rewardType == RewardType.ERC721) {
                // address from, address to,uint256 tokenId,bytes calldata data
                IERC721(reward.token).safeTransferFrom(
                    address(this),
                    winnner,
                    reward.tokenId,
                    new bytes(0)
                );
                console.log("++++++++++5");
            } else if (reward.rewardType == RewardType.ERC1155) {
                // address from,address to,uint256 id,uint256 amount,bytes calldata data
                IERC1155(reward.token).safeTransferFrom(
                    address(this),
                    winnner,
                    reward.tokenId,
                    reward.amount,
                    new bytes(0)
                );
                console.log("++++++++++6");
            }
        }
    }

    function handleFee(uint256 amount) private returns (uint256 leftAmount) {
        uint256 fee = (amount * feeRatio) / base;
        leftAmount = amount - fee;
        
        uint256 feePledge = (fee * feePledgeRatio) / base;
        uint256 feePlatform = fee - feePledge;
        console.log("feePledge,feePlatform,pledgeAddress is-------:",feePledge,feePlatform,pledgeAddress);
        uint ethBalance = address(this).balance;
        console.log("ethBalance is-------:",ethBalance);
        TransferHelper.safeTransferETH(pledgeAddress, feePledge);
        TransferHelper.safeTransferETH(platformAddress, feePlatform);
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes memory _data
    ) public override returns (bytes4) {
        // store teh erc721 token
        // check the transfer 721 token is
        //story the tokenId.
        return super.onERC721Received(_operator, _from, _tokenId, _data);
    }

    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes memory _data
    ) public override returns (bytes4) {
        return super.onERC1155Received(_operator, _from, _id, _value, _data);
    }

    function getProducerLucks(address operater)
        public
        view
        returns (uint256[] memory)
    {
        return producerLucks[operater];
    }

    function getLuckyRewards(uint256 currenctId)
        public
        view
        returns (Reward[] memory rewards)
    {
        return luckyRewards[currenctId];
    }
}
