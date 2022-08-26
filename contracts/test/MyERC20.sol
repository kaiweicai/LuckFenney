// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract MyERC20 is ERC20Upgradeable, OwnableUpgradeable {

    function initialize(string memory name, string memory symbol) public initializer {
        __Ownable_init();
        __ERC20_init(name, symbol);
    }

    mapping(address => bool) public isManager;
    event SetManager(address manager, bool flag);


    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }
}
