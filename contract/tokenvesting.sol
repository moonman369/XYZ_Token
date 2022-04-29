//contract/tokenvesting.sol
// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";
import "./token.sol";

/**
 * @title TokenVesting
 */
contract TokenVesting is Ownable {

    using SafeMath for uint256;

    IERC20 token;
    //ERC20 token address
 
    uint256 startTimeUnix;
    // starting unix timestamp of vesting scheme
    uint256 durationInDays;
    // duration of vesting in days
    uint256 releaseScheduleInMinutes;    
    // release interval of vested tokens in minutes
    uint256 totalVestableAmount;
    // total amount vested in the contract

    address[] public beneficiaryList;
    // array of beneficiary addresses
    mapping (address => bool) public isValidBeneficiary;
    // maps beneficiary address to validity of beneficiary
    mapping (address => uint256) public amount;
    // maps beneficiary address to vested amount
    mapping (address => uint256) public amountReleased;
    // maps beneficiary address to released amount

    uint256 public beneficiaryCountLimit;
    // stores max limit of beneficiary count
    uint256 public minimumDurationInDays;
    // stores min limit of vesting duration in days
    address public tokenReserveAddress;
    // stores the address of reserve tokens

    event NewVestingScheme (uint256 startTimeUnix, uint256 durationInDays, uint256 releaseScheduleInMinutes);
    //event emits when new vesting scheme is generated
    event BeneficiaryAdded (address indexed beneficiary, uint256 amount);
    // event emits when new beneficiary is added
    event Release (address indexed beneficiary, uint256 releasedAmount);
    //event emits when token release is performed

    /**
    * @dev Reverts if passed identifier does not match any valid beneficiary address or is a zero address. 
    */
    modifier isBeneficiaryValid (address _beneficiary) {
        require (isValidBeneficiary[_beneficiary] && _beneficiary != address (0), "TokenVesting: Invalid beneficiary address detected");
        _;
    }

    /**
     * @dev Creates a token vesting contract.
     * @param _token address of the ERC20 token contract
     */
    constructor (address _token) {
        token = IERC20(_token);
        beneficiaryCountLimit = 10;
        minimumDurationInDays = 1;
    }

    /**
    * @dev Returns the number of beneficiary addresses added.
    * @return the number of beneficiary addresses
    */
    function getBeneficiaryCount () 
    public 
    view 
    returns (uint256) {
        return beneficiaryList.length;
    }

    /**
    * @dev Returns the details of the current vesting scheme.
    * @return start unix timestamp, vesting duration in days, release interval in minutes
    */
    function getVestingScheme () 
    external 
    view 
    returns (uint256, uint256, uint256) {
        return (startTimeUnix, durationInDays, releaseScheduleInMinutes);
    }

    /**
    * @dev Returns the maximum releaseable amount at a given time.
    * @return releaseable amount
    */
    function getReleasableAmount (address _beneficiary) 
    external 
    view 
    isBeneficiaryValid (_beneficiary) 
    returns (uint256) {
        uint256 _releasableAmount = _getReleaseableAmount (_beneficiary);
        return _releasableAmount;
    }

    /**
    * @dev Assigns the number token reserve address.
    * @param _tokenReserveAddress address of the account with the reserve tokens
    */
    function setTokenReserveAddress (address _tokenReserveAddress) 
    public 
    onlyOwner {
        tokenReserveAddress = _tokenReserveAddress;
    }

    /**
    * @dev Assigns the maximum number of beneficiaries that can be added (10 by default).
    * @param _beneficiaryCountLimit maximum beneficiaries
    */
    function setBeneficiaryCountLimit (uint _beneficiaryCountLimit) 
    public 
    onlyOwner {
        require (_beneficiaryCountLimit > 0, "TokenVesting: Beneficiary count limit should be greater than zero");
        beneficiaryCountLimit = _beneficiaryCountLimit;
    }
    
    /**
    * @dev Assigns the minimum vesting duration duration (1 by default).
    * @param _minimumDurationInDays maximum beneficiaries
    */
    function setMinimumDurationInDays (uint256 _minimumDurationInDays) 
    public 
    onlyOwner {
        require (_minimumDurationInDays >= 1, "TokenVesting: Minimum duration cannot be lesser than 1 day.");
        minimumDurationInDays = _minimumDurationInDays;
    }

    /**
    * @dev Assigns the values of vesting scheme details(1 by default).
    * @param _startTimeUnix starting unix timestamp
    * @param _durationInDays vesting duration in days
    * @param _releaseScheduleInMinutes release interval in minutes
    */
    function setVestingScheme (
            uint256 _startTimeUnix, 
            uint256 _durationInDays, 
            uint256 _releaseScheduleInMinutes
        ) public 
        onlyOwner {
        require (_startTimeUnix != 0 && _startTimeUnix >= _getCurrentTime(), "TokenVesting: Invalid start time. Start time can't be before current time.");
        require (_durationInDays >= 1, "TokenVesting: Minimum vesting duration is 1 day");
        require (_releaseScheduleInMinutes >= 1, "TokenVesting: Release schedule cannot be lesser than 1 minute.");

        startTimeUnix = _startTimeUnix;
        durationInDays = _durationInDays;
        releaseScheduleInMinutes = _releaseScheduleInMinutes;

        emit NewVestingScheme (startTimeUnix, durationInDays, releaseScheduleInMinutes);
    }

    /**
    * @dev Adds a beneficiary address and assigns a vesting amount.
    * @param _beneficiary address
    * @param _amount vesting amount
    */
    function setBeneficiaryAddressAndAmount (address _beneficiary, uint256 _amount) 
    public 
    onlyOwner {
        require (_beneficiary != address(0), "TokenVesting: Zero address cannot be set as a beneficiary");
        require (_amount > 0, "TokenVesting: Vesting amount must be greater than zero");
        require (getBeneficiaryCount() <= beneficiaryCountLimit, "TokenVesting: Beneficiary count has reached limit");
        require (!isValidBeneficiary[_beneficiary], "TokenVesting: Beneficiary already added");
        beneficiaryList.push(_beneficiary);
        amount[_beneficiary] = _amount;
        totalVestableAmount = totalVestableAmount.add(_amount);
        isValidBeneficiary[_beneficiary] = true;
        emit BeneficiaryAdded (_beneficiary, amount[_beneficiary]);
    }
     
    /**
    * @dev Release tokens to beneficiaries.
    * @param _beneficiary address
    * @param _releaseAmount amount of tokens to be released
    */
    function release (address _beneficiary, uint256 _releaseAmount) 
    public 
    isBeneficiaryValid (_beneficiary) {
        require (_msgSender() == owner() || isValidBeneficiary[_msgSender()], "TokenVesting: Only owner or a valid beneficiary can be caller.");
        require (_releaseAmount <= amount[_beneficiary], "TokenVesting: Release amount cannot be more than total vesting amount");
        uint256 releasableAmount = _getReleaseableAmount (_beneficiary);
        require (_releaseAmount <= releasableAmount, "TokenVesting: Entered release amount is greater than cuurent releasable amount");
        amountReleased[_beneficiary] = amountReleased[_beneficiary].add(_releaseAmount);
        emit Release (_beneficiary, _releaseAmount);
        token.transferFrom(tokenReserveAddress, _beneficiary, _releaseAmount);
    }

    /**
    * @dev Calculates release amount.
    * @param _beneficiary address
    * @return releasableAmount calculated amount of tokens to be released.
    */
    function _getReleaseableAmount (address _beneficiary) 
    internal 
    view 
    returns (uint256) {
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


    /**
    * @dev Returns current unix timestamp.
    * @return current unix timestamp
    */
    function _getCurrentTime () 
    internal 
    view 
    returns (uint256) {
        return block.timestamp;
    }


}
