// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract LuckFenney is OwnableUpgradeable {

    uint256 public currentId;
    struct Lucky {
        address producer;// the project 
        uint256 id;
        Reward[] rewards;
        uint256 quantity;
        uint256 deadline;
    }

    struct Reward{
        address token;
        RewardType rewardType;
        uint256 amount;
    }

    enum RewardType {ERC20, ERC721,ERC1155 }

    event LuckCreated(uint LuckID, address creator);

    mapping(address => bool) private isManager;

    modifier onlyManager() {
        require(isManager[_msgSender()], "Not manager");
        _;
    }

    function initialize() public initializer {
        __Ownable_init();
    }

    function createLuck()public payable {

    }
}