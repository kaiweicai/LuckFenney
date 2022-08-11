// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract LuckFenney is OwnableUpgradeable {
    uint256 constant QuantityMin = 100;
    uint256 constant QuantityMax = 10000;
    uint256 public currentId=0;
    mapping(address=>uint) public producerLucks;
    mapping(uint=>Lucky) public runningLucks;
    struct Lucky {
        address producer; // the project
        uint256 id;
        Reward[] rewards;
        uint256 quantity; //参与人数
        uint256 duration; //持续时间
        uint startTime;
        LOTTERY_STATE state;
        ethAmount// 奖品eth的数量
    }

    struct Reward {
        address token;
        RewardType rewardType;
        uint256 amount;
    }

    enum RewardType {
        ERC20,
        ERC721,
        ERC1155
    }

    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }

    event LuckCreated(uint256 LuckID, address creator);

    mapping(address => bool) private isManager;

    modifier onlyManager() {
        require(isManager[_msgSender()], "Not manager");
        _;
    }

    function initialize() public initializer {
        __Ownable_init();
    }

    function createLuck(Lucky memory luck) public payable {
        require(luck.rewards.length > 0, "RLBTZ");
        require(
            luck.quantity > QuantityMin && luck.quantity <= QuantityMax,
            "LQBTMBLM"
        );
        uint256 ethAmount = msg.value;
        require(ethAmount == luck.ethAmount, "ethAmount engough");
        luck.startTime = block.number;
        // require(luck.deadline > block.number, "RLBTZ");
        // TODO 收钱，并且确认收钱的数量。注意weth9的收取。
        // TODO 收取eth

        for (uint256 i = 0; i < luck.rewards.length; i++) {
            Reward memory reward = luck.rewards[i];
        }
        currentId += 1;
        luck.id = currentId;
        addRunningLucks(luck);
        producerLucks[msg.sender] = currentId;
    }

    function addRunningLucks(Lucky memory luck)internal {
        luck.state = LOTTERY_STATE.OPEN;
        runningLucks[luck.id] = luck;
    }


}
