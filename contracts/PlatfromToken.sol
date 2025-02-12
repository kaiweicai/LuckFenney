// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PlatfromToken is ERC20 {
    
    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
    {}
}
