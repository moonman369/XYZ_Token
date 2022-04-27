// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "./tokenvesting.sol";

contract TokenXYZ is  ERC20 {

    uint256 public _totalSupply = 100000000;

    constructor (string memory _name, string memory _symbol) 
    ERC20 (_name, _symbol) {
        _mint(msg.sender, _totalSupply);
    }
    
}