// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/utils/structs/BitMaps.sol";
import "openzeppelin/utils/structs/EnumerableSet.sol";
import "openzeppelin/access/Ownable.sol";

import { console2 } from "forge-std/console2.sol";


error Amino_Zero_Arguments();
error Amino_Invalid_Arguments();
error Amino_Not_Authorized();
error Amino_Rewards_Exceeds_Max_Allowed();
error Amino_Called_Within_Time_Interval();
error Amino_Promo_Only_To_New_Users();
error Amino_Not_Eligible_For_Referral();
error Amino_Shopping_Reward_Disabled();

struct UserData {
    bool hasClaimedPromoTokens;
    uint48 firstDay;
    uint40 totalDailyCheckIns;
    uint40 lastCalledDailyCheckIn;
    uint40 lastCalledStepCheckIn;
    uint40 lastCalledChallengeCheckIn;
    uint40 lastCalledLeaderboardCheckIn;
    uint40 lastCalledShoppingCheckIn;
    BitMaps.BitMap dailyCheckIns;
    BitMaps.BitMap stepCheckIns;
    BitMaps.BitMap challengeCheckIns;
    BitMaps.BitMap leaderboardCheckIns;
    BitMaps.BitMap shoppingCheckIns;
}

/// @title Amino is a blockchain fitness and shopping rewards company
/// @author Parth Patel & Sumit Vekariya
contract Amino is ERC20, Ownable {

    using EnumerableSet for EnumerableSet.AddressSet;
    using BitMaps for BitMaps.BitMap;

    uint256 public constant DAILY_CHECKIN_REWARD_MAX = 1000000000000000000000; //TODO to confirm this number with client
    uint256 public constant DAILY_STEP_REWARD_MAX = 1000000000000000000000;
    uint256 public constant DAILY_CHALLENGE_REWARD_MAX = 1000000000000000000000;
    uint256 public constant DAILY_LEADERBOARD_REWARD_MAX = 1000000000000000000000;
    uint256 public constant DAILY_SHOPPING_REWARD_MAX = 1000000000000000000000;
    uint256 public constant PROMO_COIN_REWARD_MAX = 1000000000000000000000;
    uint256 public constant SECONDS_IN_DAY = 24 * 60 * 60;
    uint256 public timeInterval = 24 hours;
    mapping(address => bool) isAuthorizedAddress;
    bool public isShoppingRewardEnabled;
    mapping(address user => UserData userData) internal userData;
    mapping(address user => bool rewardProcessed) public isReferralRewardProcessed;
    mapping(address user => EnumerableSet.AddressSet referres) internal referrals;

    event DailyCheckIn(address indexed user, uint256 amount);
    event DailyStepCheckIn(address indexed user, uint256 amount);
    event DailyChallengeCheckIn(address indexed user, uint256 amount);
    event DailyLeaderboardCheckIn(address indexed user, uint256 amount);
    event ShoppingReward(address indexed user, uint256 amount);
    event ReferralReward(address indexed user);
    event UpdateTimeInterval(uint256 interval);
    event Referred(address indexed referrer, address indexed referree);
    event PromoCoinsReward(address indexed user, uint256 amount);

    constructor(address _owner) ERC20("Amino", "AMN") {
        /// @notice The owner of the contract is the one who deploys the contract
        if (_owner == address(0)) {
            revert Amino_Zero_Arguments();
        }
        isAuthorizedAddress[_owner] = true;
        _transferOwnership(_owner);
    }

    /// @notice This modifier is used to authorize the address to call the functions
    modifier isAuthorized() {
        if (!isAuthorizedAddress[msg.sender]) {
            revert Amino_Not_Authorized();
        }
        _;
    }

    /// @param user address of the user checking in
    /// @param dailyCheckInAmount checking in reward amount
    function dailyCheckIn(address user, uint256 dailyCheckInAmount) external isAuthorized {
        if (dailyCheckInAmount > DAILY_CHECKIN_REWARD_MAX) {
            revert Amino_Rewards_Exceeds_Max_Allowed();
        }
        UserData storage _userData = userData[user];
        uint256 currentDay = block.timestamp / SECONDS_IN_DAY;
        if (block.timestamp - _userData.lastCalledDailyCheckIn <= timeInterval) {
            revert Amino_Called_Within_Time_Interval();
        }
        _userData.dailyCheckIns.set(currentDay);
        _userData.totalDailyCheckIns++;
        _userData.lastCalledDailyCheckIn = uint40(block.timestamp);
        _mint(user, dailyCheckInAmount);
        emit DailyCheckIn(user, dailyCheckInAmount);
    }

    /// @param user address of the user
    /// @param dailyStepRewardAmount  step reward amount for that day
    function dailyStepReward(address user, uint256 dailyStepRewardAmount) external isAuthorized {
        if (dailyStepRewardAmount > DAILY_STEP_REWARD_MAX) {
            revert Amino_Rewards_Exceeds_Max_Allowed();
        }
        UserData storage _userData = userData[user];
        uint256 currentDay = block.timestamp / SECONDS_IN_DAY;
        if (block.timestamp - _userData.lastCalledStepCheckIn <= timeInterval) {
            revert Amino_Called_Within_Time_Interval();
        }
        _userData.stepCheckIns.set(currentDay);
        _userData.lastCalledStepCheckIn = uint40(block.timestamp);
        _mint(user, dailyStepRewardAmount);
        emit DailyStepCheckIn(user, dailyStepRewardAmount);
    }

    /// @param user address of the user
    /// @param dailyChallengeRewardAmount reward amount for challenge of that day 
    function dailyChallengeReward(address user, uint256 dailyChallengeRewardAmount) external isAuthorized {
        if (dailyChallengeRewardAmount > DAILY_CHALLENGE_REWARD_MAX) {
            revert Amino_Rewards_Exceeds_Max_Allowed();
        }
        UserData storage _userData = userData[user];
        uint256 currentDay = block.timestamp / SECONDS_IN_DAY;
        if (block.timestamp - _userData.lastCalledChallengeCheckIn <= timeInterval) {
            revert Amino_Called_Within_Time_Interval();
        }
        _userData.challengeCheckIns.set(currentDay);
        _userData.lastCalledChallengeCheckIn = uint40(block.timestamp);
        _mint(user, dailyChallengeRewardAmount);
        emit DailyChallengeCheckIn(user, dailyChallengeRewardAmount);
    }

    /// @param user address of the user
    /// @param dailyLeaderboardRewardAmount reward amount for leaderboard of that day
    function dailyLeaderboardReward(address user, uint256 dailyLeaderboardRewardAmount) external isAuthorized{
        if (dailyLeaderboardRewardAmount > DAILY_LEADERBOARD_REWARD_MAX) {
            revert Amino_Rewards_Exceeds_Max_Allowed();
        }
        UserData storage _userData = userData[user];
        uint256 currentDay = block.timestamp / SECONDS_IN_DAY;
        if (block.timestamp - _userData.lastCalledLeaderboardCheckIn <= timeInterval) {
            revert Amino_Called_Within_Time_Interval();
        }
        _userData.leaderboardCheckIns.set(currentDay);
        _userData.lastCalledLeaderboardCheckIn = uint40(block.timestamp);
        _mint(user, dailyLeaderboardRewardAmount);
        emit DailyLeaderboardCheckIn(user, dailyLeaderboardRewardAmount);
    }

    /// @notice This function is used to reward the user for shopping
    /// @param user address of the user
    /// @param dailyShoppingRewardAmount reward amount for shopping of that day
    /// @param priceInUSD price of the token in USD
    function shoppingRewards(address user, uint256 dailyShoppingRewardAmount, uint256 priceInUSD) external isAuthorized returns(uint256 rewardAmountInUSD) {
        if (!isShoppingRewardEnabled) {
            revert Amino_Shopping_Reward_Disabled();
        }
        if (dailyShoppingRewardAmount > DAILY_SHOPPING_REWARD_MAX) {
            revert Amino_Rewards_Exceeds_Max_Allowed();
        }
        UserData storage _userData = userData[user];
        uint256 currentDay = block.timestamp / SECONDS_IN_DAY;
        if (block.timestamp - _userData.lastCalledShoppingCheckIn <= timeInterval) {
            revert Amino_Called_Within_Time_Interval();
        }
        _userData.leaderboardCheckIns.set(currentDay);
        _userData.lastCalledShoppingCheckIn = uint40(block.timestamp);
        rewardAmountInUSD = dailyShoppingRewardAmount * priceInUSD;
        _mint(user, dailyShoppingRewardAmount);
        emit ShoppingReward(user, dailyShoppingRewardAmount);
    }

    function dailyCheckInWheel() external {
        
    }

    /// @param user address of the user
    /// @param referres address of the referres
    function referralReward(address user, address[] memory referres) external isAuthorized {
        if (referres.length != 3) {
            revert Amino_Invalid_Arguments();
        }
        for(uint256 i = 0; i < referres.length; i++) {
            UserData storage _referreData = userData[referres[i]];
            if (_referreData.totalDailyCheckIns < 3) {
                revert Amino_Not_Eligible_For_Referral();
            }
            if (isReferralRewardProcessed[referres[i]]) {
                revert Amino_Not_Eligible_For_Referral();
            }
            isReferralRewardProcessed[referres[i]] = true;
        }
        _mint(user, 100 * 10 ** decimals());
        emit ReferralReward(user);
    }

    /// @param user address of the user
    /// @param promoRewardAmount promotional reward amount
    function grantPromoCoins(address user, uint256 promoRewardAmount) external isAuthorized {
        if (promoRewardAmount > PROMO_COIN_REWARD_MAX) {
            revert Amino_Rewards_Exceeds_Max_Allowed();
        }
        UserData storage _userData = userData[user];
        if (_userData.firstDay != 0) {
            revert Amino_Promo_Only_To_New_Users();
        }
        uint256 currentDay = block.timestamp / SECONDS_IN_DAY;
        _userData.firstDay = uint48(currentDay);
        _mint(user, promoRewardAmount);
        emit PromoCoinsReward(user, promoRewardAmount);
    }

    /// @param user1 address of the user who referred
    /// @param user2 address of the user who is referred
    function referred(address user1, address user2) external onlyOwner() {
        if (user1 == address(0) || user2 == address(0)) {
            revert Amino_Zero_Arguments();
        }
        referrals[user1].add(user2);
        emit Referred(user1, user2);
    }

    /// @dev allows owner to disale shopping rewards
    function disableShoppingRewards() external onlyOwner() {
        isShoppingRewardEnabled = false;
    }

    /// @dev allows owner to update the time interval
    /// @param newTimeInterval new time interval
    function updateTimeInterval(uint256 newTimeInterval) external onlyOwner() {
        if (newTimeInterval == 0) {
            revert Amino_Zero_Arguments();
        }
        timeInterval = newTimeInterval;
        emit UpdateTimeInterval(newTimeInterval);
    }

    function getUserData(address user) external returns(bool, uint48, uint40, uint40, uint40, uint40, uint40, uint40) {
        UserData storage _userData = userData[user];
        return (
            _userData.hasClaimedPromoTokens, 
            _userData.firstDay, 
            _userData.totalDailyCheckIns,
            _userData.lastCalledDailyCheckIn,
            _userData.lastCalledStepCheckIn,
            _userData.lastCalledChallengeCheckIn,
            _userData.lastCalledLeaderboardCheckIn,
            _userData.lastCalledShoppingCheckIn
            );
    }
}
