//contract/token.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "./tokenvesting.sol";

/**
 * @title TokenXYZ
 */
contract TokenXYZ is  ERC20 {

    uint256 _totalSupply = 100 * (10 ** 6);

    /**
     * @dev Creates a ERC20 token contract with the passed specifications
     */
    constructor () 
    ERC20 ("XYZ Token", "XYZ") {
        _mint(_msgSender(), _totalSupply);
    }
    
}