// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IERC721.sol";
import "../interfaces/ERC721TokenReceiver.sol";

contract LuckFenney is ERC721TokenReceiver, OwnableUpgradeable {
    uint256 constant QuantityMin = 100;
    uint256 constant QuantityMax = 10000;
    uint256 public currentId = 0;
    mapping(address => uint256) public producerLucks;
    mapping(uint256 => Lucky) public runningLucks;
    struct Lucky {
        address producer; // the project
        uint256 id;
        Reward[] rewards;
        uint256 quantity; //参与人数
        uint256 duration; //持续时间
        uint256 startTime;
        LOTTERY_STATE state;
        uint256 ethAmount; // 奖品eth的数量
        uint[] erc721TokenIds;
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
            if (reward.rewardType == RewardType.ERC20) {
                IERC20(reward.token).transferFrom(
                    msg.sender,
                    address(this),
                    reward.amount
                );
            } else if (reward.rewardType == RewardType.ERC721) {
                IERC721(reward.token).safeTransferFrom(
                    msg.sender,
                    address(this),
                    reward.amount
                );
            }
        }
        currentId += 1;
        luck.id = currentId;
        addRunningLucks(luck);
        producerLucks[msg.sender] = currentId;
    }

    function addRunningLucks(Lucky memory luck) internal {
        luck.state = LOTTERY_STATE.OPEN;
        runningLucks[luck.id] = luck;
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes memory _data
    ) external returns (bytes4) {
        // store teh erc721 token
        // check the transfer 721 token is 
        //story the tokenId.
        
    }
}
