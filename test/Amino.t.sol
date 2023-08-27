// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { PRBTest } from "@prb/test/PRBTest.sol";
import { console2 } from "forge-std/console2.sol";
import { StdCheats } from "forge-std/StdCheats.sol";

import { 
    Amino, 
    Amino_Zero_Arguments, 
    Amino_Invalid_Arguments, 
    Amino_Not_Authorized, 
    Amino_Rewards_Exceeds_Max_Allowed, 
    Amino_Called_Within_Time_Interval, 
    Amino_Promo_Only_To_New_Users, 
    Amino_Not_Eligible_For_Referral, 
    Amino_Shopping_Reward_Disabled ,
    UserData
} from "../src/Amino.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

/// @dev If this is your first time with Forge, read this tutorial in the Foundry Book:
/// https://book.getfoundry.sh/forge/writing-tests
contract AminoTest is PRBTest, StdCheats {
    Amino internal amino;
    address internal owner = makeAddr("owner");
    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");
    uint256 public constant SECONDS_IN_DAY = 24 * 60 * 60;



    /// @dev A function invoked before each test case is run.
    function setUp() public virtual {
        // Instantiate the contract-under-test.
        amino = new Amino(owner);
    }

    function test_owner() public {
        assertEq(amino.owner(), owner, "owner mismatched");
    }

    function test_grantPromoCoins_only_be_called_by_authorized_address() public {
        vm.startPrank(alice);
        vm.expectRevert(Amino_Not_Authorized.selector);
        amino.grantPromoCoins(alice, 1000);
        vm.stopPrank();
    }

    function test_grantPromoCoins_has_max_cap_on_mint() public {
       vm.startPrank(owner);
       vm.expectRevert(Amino_Rewards_Exceeds_Max_Allowed.selector);
       amino.grantPromoCoins(alice, 1000000000000000000001);
       vm.stopPrank();
    }

    function test_grantPromoCoins_can_only_be_called_on_first_day() public {
       vm.startPrank(owner);
       amino.grantPromoCoins(alice, 1000);
        vm.expectRevert(Amino_Promo_Only_To_New_Users.selector);
       amino.grantPromoCoins(alice, 1000);
       vm.stopPrank();
    }

    function test_grantPromoCoins_happy_path() public {
       uint256 aliceBalanceBefore = amino.balanceOf(alice);
       vm.startPrank(owner);
       amino.grantPromoCoins(alice, 1000);
       vm.stopPrank();
       uint256 aliceBalanceAfter = amino.balanceOf(alice);
       assertEq(aliceBalanceAfter - aliceBalanceBefore, 1000, "invalid balance");
       (bool hasClaimedPromoTokens, 
        uint48 firstDay, 
        uint40 totalDailyCheckIns,
        uint40 lastCalledDailyCheckIn,
        uint40 lastCalledStepCheckIn,
        uint40 lastCalledChallengeCheckIn,
        uint40 lastCalledLeaderboardCheckIn,
        uint40 lastCalledShoppingCheckIn
       ) = amino.getUserData(alice);

       assertEq(firstDay, block.timestamp / SECONDS_IN_DAY, "invalid first day");
    }

    function test_dailyCheckIn_only_be_called_by_authorized_address() public {
        vm.startPrank(alice);
        vm.expectRevert(Amino_Not_Authorized.selector);
        amino.dailyCheckIn(alice, 1000);
        vm.stopPrank();
    }

    function test_dailyCheckIn_has_max_cap_on_mint() public {
       vm.startPrank(owner);
       vm.expectRevert(Amino_Rewards_Exceeds_Max_Allowed.selector);
       amino.dailyCheckIn(alice, 1000000000000000000001);
       vm.stopPrank();
    }

    function test_dailyCheckIn_reverts_if_called_within_timeInterval() public {
       vm.startPrank(owner);
       amino.dailyCheckIn(alice, 1000);
       skip(30 seconds);
       vm.expectRevert(Amino_Called_Within_Time_Interval.selector);
       amino.dailyCheckIn(alice, 1000);
       vm.stopPrank();
    }

    function test_dailyCheckIn_happy_path() public {
       uint256 aliceBalanceBefore = amino.balanceOf(alice);
       vm.startPrank(owner);
       amino.dailyCheckIn(alice, 1000);
       skip(1 days + 1);
        amino.dailyCheckIn(alice, 1000);
       vm.stopPrank();
       uint256 aliceBalanceAfter = amino.balanceOf(alice);
       (bool hasClaimedPromoTokens, 
        uint48 firstDay, 
        uint40 totalDailyCheckIns,
        uint40 lastCalledDailyCheckIn,
        uint40 lastCalledStepCheckIn,
        uint40 lastCalledChallengeCheckIn,
        uint40 lastCalledLeaderboardCheckIn,
        uint40 lastCalledShoppingCheckIn
       ) = amino.getUserData(alice);
       assertEq(aliceBalanceAfter - aliceBalanceBefore, 2000, "invalid balance");
       assertEq(totalDailyCheckIns, 2, "invalid totalDailyCheckIns");
       assertEq(lastCalledDailyCheckIn, block.timestamp, "invalid lastCalledDailyCheckIn");
    }

    function test_dailyStepReward_only_be_called_by_authorized_address() public {
        vm.startPrank(alice);
        vm.expectRevert(Amino_Not_Authorized.selector);
        amino.dailyStepReward(alice, 1000);
        vm.stopPrank();
    }

    function test_dailyStepReward_has_max_cap_on_mint() public {
       vm.startPrank(owner);
       vm.expectRevert(Amino_Rewards_Exceeds_Max_Allowed.selector);
       amino.dailyStepReward(alice, 1000000000000000000001);
       vm.stopPrank();
    }

    function test_dailyStepReward_reverts_if_called_within_timeInterval() public {
       vm.startPrank(owner);
       amino.dailyStepReward(alice, 1000);
       skip(30 seconds);
       vm.expectRevert(Amino_Called_Within_Time_Interval.selector);
       amino.dailyStepReward(alice, 1000);
       vm.stopPrank();
    }

    function test_dailyStepReward_happy_path() public {
       uint256 aliceBalanceBefore = amino.balanceOf(alice);
       vm.startPrank(owner);
       amino.dailyStepReward(alice, 1000);
       skip(1 days + 1);
        amino.dailyStepReward(alice, 1000);
       vm.stopPrank();
       uint256 aliceBalanceAfter = amino.balanceOf(alice);
       (bool hasClaimedPromoTokens, 
        uint48 firstDay, 
        uint40 totalDailyCheckIns,
        uint40 lastCalledDailyCheckIn,
        uint40 lastCalledStepCheckIn,
        uint40 lastCalledChallengeCheckIn,
        uint40 lastCalledLeaderboardCheckIn,
        uint40 lastCalledShoppingCheckIn
       ) = amino.getUserData(alice);
       assertEq(aliceBalanceAfter - aliceBalanceBefore, 2000, "invalid balance");
       assertEq(lastCalledStepCheckIn, block.timestamp, "invalid lastCalledDailyCheckIn");
    }

    function test_dailyChallengeReward_only_be_called_by_authorized_address() public {
        vm.startPrank(alice);
        vm.expectRevert(Amino_Not_Authorized.selector);
        amino.dailyChallengeReward(alice, 1000);
        vm.stopPrank();
    }

    function test_dailyChallengeReward_has_max_cap_on_mint() public {
       vm.startPrank(owner);
       vm.expectRevert(Amino_Rewards_Exceeds_Max_Allowed.selector);
       amino.dailyChallengeReward(alice, 1000000000000000000001);
       vm.stopPrank();
    }

    function test_dailyChallengeReward_reverts_if_called_within_timeInterval() public {
       vm.startPrank(owner);
       amino.dailyChallengeReward(alice, 1000);
       skip(30 seconds);
       vm.expectRevert(Amino_Called_Within_Time_Interval.selector);
       amino.dailyChallengeReward(alice, 1000);
       vm.stopPrank();
    }

    function test_dailyChallengeReward_happy_path() public {
       uint256 aliceBalanceBefore = amino.balanceOf(alice);
       vm.startPrank(owner);
       amino.dailyChallengeReward(alice, 1000);
       skip(1 days + 1);
        amino.dailyChallengeReward(alice, 1000);
       vm.stopPrank();
       uint256 aliceBalanceAfter = amino.balanceOf(alice);
       (bool hasClaimedPromoTokens, 
        uint48 firstDay, 
        uint40 totalDailyCheckIns,
        uint40 lastCalledDailyCheckIn,
        uint40 lastCalledStepCheckIn,
        uint40 lastCalledChallengeCheckIn,
        uint40 lastCalledLeaderboardCheckIn,
        uint40 lastCalledShoppingCheckIn
       ) = amino.getUserData(alice);
       assertEq(aliceBalanceAfter - aliceBalanceBefore, 2000, "invalid balance");
       assertEq(lastCalledChallengeCheckIn, block.timestamp, "invalid lastCalledDailyCheckIn");
    }

    function test_dailyLeaderboardReward_only_be_called_by_authorized_address() public {
        vm.startPrank(alice);
        vm.expectRevert(Amino_Not_Authorized.selector);
        amino.dailyLeaderboardReward(alice, 1000);
        vm.stopPrank();
    }

    function test_dailyLeaderboardReward_has_max_cap_on_mint() public {
       vm.startPrank(owner);
       vm.expectRevert(Amino_Rewards_Exceeds_Max_Allowed.selector);
       amino.dailyLeaderboardReward(alice, 1000000000000000000001);
       vm.stopPrank();
    }

    function test_dailyLeaderboardReward_reverts_if_called_within_timeInterval() public {
       vm.startPrank(owner);
       amino.dailyLeaderboardReward(alice, 1000);
       skip(30 seconds);
       vm.expectRevert(Amino_Called_Within_Time_Interval.selector);
       amino.dailyLeaderboardReward(alice, 1000);
       vm.stopPrank();
    }

    function test_dailyLeaderboardReward_happy_path() public {
       uint256 aliceBalanceBefore = amino.balanceOf(alice);
       vm.startPrank(owner);
       amino.dailyLeaderboardReward(alice, 1000);
       skip(1 days + 1);
        amino.dailyLeaderboardReward(alice, 1000);
       vm.stopPrank();
       uint256 aliceBalanceAfter = amino.balanceOf(alice);
       (bool hasClaimedPromoTokens, 
        uint48 firstDay, 
        uint40 totalDailyCheckIns,
        uint40 lastCalledDailyCheckIn,
        uint40 lastCalledStepCheckIn,
        uint40 lastCalledChallengeCheckIn,
        uint40 lastCalledLeaderboardCheckIn,
        uint40 lastCalledShoppingCheckIn
       ) = amino.getUserData(alice);
       assertEq(aliceBalanceAfter - aliceBalanceBefore, 2000, "invalid balance");
       assertEq(lastCalledLeaderboardCheckIn, block.timestamp, "invalid lastCalledDailyCheckIn");
    }

}
