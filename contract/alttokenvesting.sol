// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";
import "./token.sol";

contract AltTokenVesting is Ownable {

    using SafeMath for uint256;
    IERC20 token;

    uint256 public beneficiaryCountLimit;

    uint256 startTimeUnix;
    uint256 durationInDays;
    uint256 releaseScheduleInMinutes;

    address[] public beneficiaryList;
    mapping (address => bool) isValidBeneficiary;
    mapping (address => uint256) amount;
    mapping (address => uint256) amountReleased;

    event NewVestingScheme (uint256 startTimeUnix, uint256 durationInDays, uint256 releaseScheduleInMinutes);
    event BeneficiaryAdded (address beneficiary, uint256 amount);
    event Release (address beneficiary, uint256 releasedAmount);

    modifier isBeneficiaryValid (address _beneficiary) {
        require (isValidBeneficiary[_beneficiary], "TokenVesting: Invalid beneficiary address detected");
        _;
    }

    constructor (address _token) {
        token = IERC20(_token);
        beneficiaryCountLimit = 10;
    }

    function getBeneficiaryCount () public view returns (uint256) {
        return beneficiaryList.length;
    }

    function getVestingScheme () external view returns (uint256, uint256, uint256) {
        return (startTimeUnix, durationInDays, releaseScheduleInMinutes);
    }

    function setBeneficiaryCountLimit (uint _beneficiaryCountLimit) public onlyOwner {
        require (_beneficiaryCountLimit > 0, "TokenVesting: Beneficiary count limit should be greater than zero");
        beneficiaryCountLimit = _beneficiaryCountLimit;
    }

    function setVestingScheme (uint256 _startTimeUnix, uint256 _durationInDays, uint256 _releaseScheduleInMinutes) public onlyOwner {
        require (_startTimeUnix != 0 && _startTimeUnix >= _getCurrentTime(), "TokenVesting: Invalid start time. Start time can't be before current time.");
        require (_durationInDays >= 7, "TokenVesting: Minimum vesting duration is 7 days");
        require (_releaseScheduleInMinutes >= 1, "TokenVesting: Release schedule cannot be lesser than 1 minute.");

        startTimeUnix = _startTimeUnix;
        durationInDays = _durationInDays;
        releaseScheduleInMinutes = _releaseScheduleInMinutes;

        emit NewVestingScheme (startTimeUnix, durationInDays, releaseScheduleInMinutes);
    }

    function setBeneficiaryAddressAndAmount (address _beneficiary, uint256 _amount) public onlyOwner {
        require (_beneficiary != address(0), "TokenVesting: Zero address cannot be set as a beneficiary");
        require (_amount > 0, "TokenVesting: Vesting amount must be greater than zero");
        require (getBeneficiaryCount() <= beneficiaryCountLimit, "TokenVesting: Beneficiary count has reached limit");
        require (!isValidBeneficiary[_beneficiary], "TokenVesting: Beneficiary already added");
        beneficiaryList.push(_beneficiary);
        amount[_beneficiary] = _amount;
        isValidBeneficiary[_beneficiary] = true;
        emit BeneficiaryAdded (_beneficiary, amount[_beneficiary]);
    }

    function release (address _beneficiary, uint256 _releaseAmount) public isBeneficiaryValid(_beneficiary) {
        require (_msgSender() == owner() || isValidBeneficiary[_msgSender()], "TokenVesting: Only owner or a valid beneficiary can be caller.");
        require (_releaseAmount <= amount[_beneficiary], "TokenVesting: Release amount cannot be more than total vesting amount");
        uint256 releasableAmount = _getReleaseableAmount (_beneficiary);
        require (_releaseAmount <= releasableAmount, "TokenVesting: Entered release amount is greater than cuurent releasable amount");
        amountReleased[_beneficiary] = amountReleased[_beneficiary].add(_releaseAmount);
        emit Release (_beneficiary, _releaseAmount);
        token.transfer(_beneficiary, _releaseAmount);
    }


    function _getReleaseableAmount (address _beneficiary) internal view returns (uint256) {
        uint256 nowInMinutes = _getCurrentTime().div(1 minutes);
        uint256 startTimeInMinutes = startTimeUnix.div(1 minutes);
        uint256 durationInMinutes = (durationInDays.mul(1 days)).div(1 minutes);
        if (nowInMinutes < startTimeInMinutes.add(durationInMinutes)) {
            uint256 timeElapsedWrtReleaseSchedule = (nowInMinutes.sub(startTimeInMinutes)).div(releaseScheduleInMinutes);
            uint256 durationWrtReleaseSchedule = durationInMinutes.div(releaseScheduleInMinutes);
            uint256 releasableAmount = (amount[_beneficiary].mul(timeElapsedWrtReleaseSchedule).div(durationWrtReleaseSchedule)).sub(amountReleased[_beneficiary]);
            return releasableAmount;
        }
        else{
            return amount[_beneficiary].sub(amountReleased[_beneficiary]);
        }
    }

    function _getCurrentTime () internal view returns (uint256) {
        return block.timestamp;
    }


}