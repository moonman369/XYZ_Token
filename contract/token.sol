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

    /**
     * @dev Creates a ERC20 token contract.
     * @param _name name of the token
     * @param _symbol symbol of the token
     * @param _totalSupply total supply of the token
     */
    constructor (
        string memory _name, 
        string memory _symbol, 
        uint256 _totalSupply
    ) 
    ERC20 (_name, _symbol) {
        _mint(_msgSender(), _totalSupply);
    }
    
}