// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

struct UserData { //TODO pack the struct for better gas savings
    uint40 lastCheckInDay;
    uint40 lastStepRewardDay;
    uint40 lastChallengeRewardDay;
    uint40 lastLeaderboardRewardDay;
    uint40 lastShoppingRewardDay;
    uint40 firstDay;
    bool hasClaimedPromoTokens;
}

contract Amino is ERC20 {
    uint256 public constant DAILY_CHECKIN_REWARD_MAX = 1000000000000000000000; //TODO to confirm this number with client
    uint256 public constant DAILY_STEP_REWARD_MAX = 1000000000000000000000;
    uint256 public constant DAILY_CHALLENGE_REWARD_MAX = 1000000000000000000000;
    uint256 public constant DAILY_LEADERBOARD_REWARD_MAX = 1000000000000000000000;
    uint256 public constant PROMO_COIN_REWARD = 1000000000000000000000;
    address public minter;
    address public owner;
    bool public isShoppingRewardEnabled;


    //FOLLOWING MODIFIERS ARE FOR ILLUSTRATION PURPOSE FOR BETTER CODE READABILITY
    //THIS MAYBE REMOVED IF THEY ARE NOT USED AT MULTIPLE PLACES

    modifier hasNotClaimedCheckInRewardTheSameDay() {

        _;
    }

    modifier hasNotClaimedStepRewardTheSameDay() {

        _;
    }

    modifier hasNotClaimedChallengeRewardTheSameDay() {

        _;
    }

    modifier hasNotClaimedLeaderboardRewardTheSameDay() {

        _;
    }

    modifier hasNotClaimedShoppingRewardTheSameDay() {

        _;
    }

    modifier hasNotClaimedPromoTokens() {

        _;
    }

    modifier onlyMinter() {
        _;
    }

    modifier onlyOwner() {
        _;
    }

    function dailyCheckIn(uint256 dailyCheckInAmount) external hasNotClaimedCheckInRewardTheSameDay() onlyMinter() {

    }

    function dailyStepReward(uint256 dailyStepRewardAmount) external hasNotClaimedStepRewardTheSameDay() onlyMinter() {
        
    }

    function dailyChallengeReward(uint256 dailyChallengeRewardAmount) external hasNotClaimedChallengeRewardTheSameDay() onlyMinter() {
        
    }

    function dailyLeaderboardReward(uint256 dailyLeaderboardRewardAmount) external hasNotClaimedLeaderboardRewardTheSameDay() onlyMinter() {
        
    }

    function shoppingRewards(uint256 dailyShoppingRewardAmount, uint256 priceInUSD) external hasNotClaimedShoppingRewardTheSameDay() onlyMinter() returns(uint256 rewardAmountInUSD) {
        require(isShoppingRewardEnabled); // TODO don't use require. change it to if-revert
        rewardAmountInUSD = dailyShoppingRewardAmount * priceInUSD;
    }

    function dailyCheckInWheel()  returns () {
        
    }

    function referralReward()  returns () {
        
    }

    function grantPromoCoins(address user) external hasNotClaimedPromoTokens() onlyMinter() {
        
    }

    function disableShoppingRewards() external onlyOwner() {

    }
}
