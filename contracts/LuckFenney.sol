// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract LuckFenney is ERC721Holder,ERC1155Holder, OwnableUpgradeable{
    uint256 constant QuantityMin = 100;
    uint256 constant QuantityMax = 10000;
    uint256 public currentId = 0;
    mapping(address => uint256) public producerLucks;
    mapping(uint256 => Lucky) public runningLucks;
    struct Lucky {
        address producer; // the project
        uint256 id;
        Reward[] rewards;
        uint256 quantity; //计划该luck参与人数
        uint256 endTime; //持续时间
        uint256 startTime;
        LuckyState state;
        uint256 ethAmount; // 奖品eth的数量
        uint256[] erc721TokenIds;
        uint256 participation_cost;// 参与的花费。
        uint256 currentQutity;//当前用户的编号
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

    function createLuck(uint quantity,Reward[] memory rewards,uint duration) public payable returns(Lucky memory luck){
        require(rewards.length > 0, "RLBTZ");
        require(
            quantity > QuantityMin && quantity <= QuantityMax,
            "LQBTMBLM"
        );
        require(duration > 0,"duration lt 0");
        luck.endTime = luck.startTime +duration;
        luck.rewards = rewards;
        luck.quantity = quantity;
        // 设置创建人
        luck.producer = msg.sender;
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
        currentId += 1;
        luck.id = currentId;
        //添加正在运行抽奖，并且修改状态。
        addRunningLucks(luck);
        producerLucks[msg.sender] = currentId;
    }

    function addRunningLucks(Lucky memory luck) internal {
        luck.state = LuckyState.OPEN;
        runningLucks[luck.id] = luck;
    }


    // 用户参与luck
    function enter(uint luckId) public payable{
        Lucky memory luckFenney = runningLucks[luckId];
        require(luckFenney.state == LuckyState.OPEN,"not open");
        uint value = msg.value;
        require(value > 0 && value%luckFenney.participation_cost==0,"value mul pari");
        // 分配用户号给用户。

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
        return super.onERC721Received(_operator,_from,_tokenId,_data);
    }

    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes memory _data
    ) public override returns (bytes4) {
        return super.onERC1155Received(_operator,_from,_id,_value,_data);
    }

}
