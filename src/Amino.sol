// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/utils/structs/BitMaps.sol";
import "openzeppelin/utils/structs/EnumerableSet.sol";
import "openzeppelin/access/Ownable.sol";

error Amino_Zero_Arguments();
error Amino_Invalid_Arguments();
error Amino_Not_Authorized();
error Amino_Rewards_Exceeds_Max_Allowed();
error Amino_Called_Within_Time_Interval();
error Amino_Promo_Only_To_New_Users();
error Amino_Not_Eligible_For_Referral();
error Amino_Shopping_Reward_Disabled();

struct UserData { //TODO pack the struct for better gas savings
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


    constructor(address _owner) ERC20("Amino", "AMN") {
        if (_owner == address(0)) {
            revert Amino_Zero_Arguments();
        }
        isAuthorizedAddress[_owner] = true;
        _transferOwnership(_owner);
    }

    modifier isAuthorized() {
        if (!isAuthorizedAddress[msg.sender]) {
            revert Amino_Not_Authorized();
        }
        _;
    }

    function dailyCheckIn(address user, uint256 dailyCheckInAmount) external isAuthorized {
        if (dailyCheckInAmount > DAILY_CHECKIN_REWARD_MAX) {
            revert Amino_Rewards_Exceeds_Max_Allowed();
        }
        UserData storage _userData = userData[user];
        uint256 currentDay = block.timestamp % SECONDS_IN_DAY;
        if (block.timestamp - _userData.lastCalledDailyCheckIn <= timeInterval) {
            revert Amino_Called_Within_Time_Interval();
        }
        _userData.dailyCheckIns.set(currentDay);
        _userData.totalDailyCheckIns++;
        _userData.lastCalledDailyCheckIn = uint40(block.timestamp);
        _mint(user, dailyCheckInAmount);
    }

    function dailyStepReward(address user, uint256 dailyStepRewardAmount) external isAuthorized {
        if (dailyStepRewardAmount > DAILY_STEP_REWARD_MAX) {
            revert Amino_Rewards_Exceeds_Max_Allowed();
        }
        UserData storage _userData = userData[user];
        uint256 currentDay = block.timestamp % SECONDS_IN_DAY;
        if (block.timestamp - _userData.lastCalledStepCheckIn <= timeInterval) {
            revert Amino_Called_Within_Time_Interval();
        }
        _userData.stepCheckIns.set(currentDay);
        _userData.lastCalledStepCheckIn = uint40(block.timestamp);
        _mint(user, dailyStepRewardAmount);
    }

    function dailyChallengeReward(address user, uint256 dailyChallengeRewardAmount) external isAuthorized {
        if (dailyChallengeRewardAmount > DAILY_CHALLENGE_REWARD_MAX) {
            revert Amino_Rewards_Exceeds_Max_Allowed();
        }
        UserData storage _userData = userData[user];
        uint256 currentDay = block.timestamp % SECONDS_IN_DAY;
        if (block.timestamp - _userData.lastCalledChallengeCheckIn <= timeInterval) {
            revert Amino_Called_Within_Time_Interval();
        }
        _userData.challengeCheckIns.set(currentDay);
        _userData.lastCalledChallengeCheckIn = uint40(block.timestamp);
        _mint(user, dailyChallengeRewardAmount);
    }

    function dailyLeaderboardReward(address user, uint256 dailyLeaderboardRewardAmount) external isAuthorized{
        if (dailyLeaderboardRewardAmount > DAILY_LEADERBOARD_REWARD_MAX) {
            revert Amino_Rewards_Exceeds_Max_Allowed();
        }
        UserData storage _userData = userData[user];
        uint256 currentDay = block.timestamp % SECONDS_IN_DAY;
        if (block.timestamp - _userData.lastCalledLeaderboardCheckIn <= timeInterval) {
            revert Amino_Called_Within_Time_Interval();
        }
        _userData.leaderboardCheckIns.set(currentDay);
        _userData.lastCalledLeaderboardCheckIn = uint40(block.timestamp);
        _mint(user, dailyLeaderboardRewardAmount);
    }

    function shoppingRewards(address user, uint256 dailyShoppingRewardAmount, uint256 priceInUSD) external isAuthorized returns(uint256 rewardAmountInUSD) {
        if (!isShoppingRewardEnabled) {
            revert Amino_Shopping_Reward_Disabled();
        }
        if (dailyShoppingRewardAmount > DAILY_SHOPPING_REWARD_MAX) {
            revert Amino_Rewards_Exceeds_Max_Allowed();
        }
        UserData storage _userData = userData[user];
        uint256 currentDay = block.timestamp % SECONDS_IN_DAY;
        if (block.timestamp - _userData.lastCalledShoppingCheckIn <= timeInterval) {
            revert Amino_Called_Within_Time_Interval();
        }
        _userData.leaderboardCheckIns.set(currentDay);
        _userData.lastCalledShoppingCheckIn = uint40(block.timestamp);
        rewardAmountInUSD = dailyShoppingRewardAmount * priceInUSD;
        _mint(user, dailyShoppingRewardAmount);
    }

    function dailyCheckInWheel() external {
        
    }

    function referralReward(address user, address[] memory referres, uint256 referralRewardAmount) external isAuthorized {
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

    }

    function grantPromoCoins(address user, uint256 promoRewardAmount) external isAuthorized {
        if (promoRewardAmount > PROMO_COIN_REWARD_MAX) {
            revert Amino_Rewards_Exceeds_Max_Allowed();
        }
        UserData storage _userData = userData[user];
        if (_userData.firstDay != 0) {
            revert Amino_Promo_Only_To_New_Users();
        }
        uint256 currentDay = block.timestamp % SECONDS_IN_DAY;
        _userData.firstDay = uint48(currentDay);
        _mint(user, promoRewardAmount);
    }

    function disableShoppingRewards() external onlyOwner() {
        isShoppingRewardEnabled = false;
    }

    function updateTimeInterval(uint256 newTimeInterval) external onlyOwner() {
        if (newTimeInterval == 0) {
            revert Amino_Zero_Arguments();
        }
        timeInterval = newTimeInterval;
    }
}
