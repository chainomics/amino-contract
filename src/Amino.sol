// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/utils/structs/BitMaps.sol";
import "openzeppelin/utils/structs/EnumerableSet.sol";

struct UserData { //TODO pack the struct for better gas savings
    uint40 firstDay;
    bool hasClaimedPromoTokens;
    BitMaps.BitMap dailyCheckIns;
    BitMaps.BitMap stepCheckIns;
    BitMaps.BitMap challengeCheckIns;
    BitMaps.BitMap leaderboardCheckIns;
    BitMaps.BitMap shoppingCheckIns;
}

contract Amino is ERC20 {

    using EnumerableSet for EnumerableSet.AddressSet;
    using BitMaps for BitMaps.BitMap;

    uint256 public constant DAILY_CHECKIN_REWARD_MAX = 1000000000000000000000; //TODO to confirm this number with client
    uint256 public constant DAILY_STEP_REWARD_MAX = 1000000000000000000000;
    uint256 public constant DAILY_CHALLENGE_REWARD_MAX = 1000000000000000000000;
    uint256 public constant DAILY_LEADERBOARD_REWARD_MAX = 1000000000000000000000;
    uint256 public constant PROMO_COIN_REWARD = 1000000000000000000000;
    address public minter;
    address public owner;
    bool public isShoppingRewardEnabled;
    mapping(address user => UserData userData) internal userData;
    mapping(address user => bool rewardProcessed) public isReferralRewardProcessed;
    mapping(address user => EnumerableSet.AddressSet referres) internal referrals;


    constructor() ERC20("name", "symbol") {}


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

    function dailyCheckInWheel() external {
        
    }

    function referralReward(address user, address[] memory referres) external onlyMinter {
        require(referres.length == 3);
    }

    function grantPromoCoins(address user) external hasNotClaimedPromoTokens() onlyMinter() {
        
    }

    function disableShoppingRewards() external onlyOwner() {

    }
}
