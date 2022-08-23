// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract PledgeToken is ERC20Upgradeable, OwnableUpgradeable{
    IERC20 public platformToken; //平台币
    

    // 实现收益通过代币分享的合约，合约本身是 ERC20的标准，可以支持无限量的铸造，在提取ETH的时候，也同步支持销毁。
    // 铸造的时候，需要转入ETH 和平台代币，转入的比例，与当前发行的质押合约总量有关，初始为 1 : 0.001。即：
    // 初始状态
    // 特征：质押合约尚未发行任何代币时候；
    // 规则：转入 1 个平台币，需要同时存入 0.001 个 ETH ，才能够获得 1 个质押代币；
    // 已发行状态
    // 特征：已经发行过至少1个质押代币；
    // 规则：转入1个平台币，需要存入的ETH数量 = 合约的ETH余额 / 总发行质押代币数量；
    // 用户可以调用 withdraw 接口，提取ETH，每1个质押代币可以提取ETH数量 = 合约的ETH余额 / 总发行质押代币数量。提取后，相应的质押代币销毁。
    constructor(string memory name_, string memory symbol_){
        __ERC20_init(name_,symbol_);
    }
}
