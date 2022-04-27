// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol";
import "./token.sol";

contract TokenVesting is Ownable {

    IERC20 private token;

    struct vestingScheme {
        address _beneficiary;
        uint256 _startTime;
        uint256 _duration;
        uint256 _releaseSchedule;
        uint256 _amount;
        bool _isValid;
    }

    uint256 private schemeId;
    vestingScheme[10] private schemes;

    event VestingShemeCreation (TokenVesting.vestingScheme);

    modifier notZeroAddress(address _token) {
        require (_token != address(0));
        _;
    }

    constructor (address _token) notZeroAddress (_token) {
        token = IERC20 (_token);
    }

    receive () external payable {}
    fallback () external payable {}

    function createVestingScheme (
        address beneficiary_,
        uint256 startTime_,
        uint256 duration_,
        uint256 releaseSchedule_,
        uint256 amount_,
        bool isValid_
    ) external {

        vestingScheme memory scheme = vestingScheme 
        (beneficiary_,
         startTime_,
         duration_,
         releaseSchedule_,
         amount_,
         isValid_);

         schemeId++;
         emit VestingShemeCreation (scheme);

        
        
    }
}