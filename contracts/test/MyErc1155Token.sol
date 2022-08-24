// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

contract MyErc1155Token is ERC1155, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC1155("MYNFT1155") {
        
    }

    function mint(address to,uint amount) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        console.log("tokenId is: " , tokenId);
        _tokenIdCounter.increment();
        _mint(to, tokenId,amount,new bytes(0));
    }

    
}