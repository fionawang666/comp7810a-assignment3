// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {MockUSDC} from "../../src/MockUSDC.sol";
import {ComplianceRegistry} from "../../src/ComplianceRegistry.sol";
import {TBillToken} from "../../src/TBillToken.sol";
import {TBillVault} from "../../src/TBillVault.sol";
import {MockPriceFeed} from "../../src/exercises/MockPriceFeed.sol";
import {MockTBillCustodian} from "../../src/exercises/MockTBillCustodian.sol";

contract BridgeTasksTest is Test {
    MockUSDC internal usdc;
    ComplianceRegistry internal compliance;
    MockPriceFeed internal feed;
    TBillToken internal tBill;
    MockTBillCustodian internal custodian;
    TBillVault internal vault;
    address internal admin = address(this);
    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");
    address internal attacker = makeAddr("attacker");
    uint256 internal constant PAR = 1e8;
    uint256 internal constant NAV_1_25 = 125_000_000;

    function setUp() public {
        usdc = new MockUSDC();
        compliance = new ComplianceRegistry(admin);
        feed = new MockPriceFeed(int256(PAR));
        tBill = new TBillToken(admin, compliance);
        custodian = new MockTBillCustodian(admin);
        vault = new TBillVault(usdc, tBill, feed, custodian, admin);
        tBill.grantRole(tBill.MINTER_ROLE(), address(vault));
        custodian.grantRole(custodian.CUSTODIAN_ROLE(), address(vault));
        compliance.setWhitelisted(admin, true);
        compliance.setWhitelisted(alice, true);
        compliance.setWhitelisted(bob, true);
    }

    function _subscribe(address user, uint256 assets) internal {
        usdc.faucet(user, assets);
        vm.startPrank(user);
        usdc.approve(address(vault), assets);
        vault.subscribe(assets);
        vm.stopPrank();
    }

    function test_Ex2_SharesExistWhileTheCustodianHoldsNothing() public {
        _subscribe(alice, 1_000e6);
        assertEq(tBill.balanceOf(alice), 1_000e18);
        assertEq(custodian.realHoldings(), 0);
        assertEq(usdc.balanceOf(address(vault)), 1_000e6);
    }

    function test_Ex2_RealHoldingsIsJustANumber() public {
        uint256 cashBefore = usdc.balanceOf(address(custodian));
        custodian.recordPurchase(1_000_000e6);
        assertEq(custodian.realHoldings(), 1_000_000e6);
        assertEq(usdc.balanceOf(address(custodian)), cashBefore);
        assertEq(cashBefore, 0);
    }

    function test_Ex3_TheClaimFloats_TheShareCountDoesNot() public {
        _subscribe(alice, 1_000e6);
        uint256 shares = tBill.balanceOf(alice);
        assertEq(vault.totalClaimValue(), 1_000e6);
        vault.attest(int256(NAV_1_25));
        assertEq(tBill.balanceOf(alice), shares);
        assertEq(shares, 1_000e18);
        assertEq(vault.totalClaimValue(), 1_250e6);
    }

    function test_Ex3_OneCallMovesTheWholeBook() public {
        _subscribe(alice, 1_000e6);
        _subscribe(bob, 400e6);
        uint256 aliceShares = tBill.balanceOf(alice);
        uint256 bobShares = tBill.balanceOf(bob);
        assertEq(vault.assetsForShares(aliceShares), 1_000e6);
        assertEq(vault.assetsForShares(bobShares), 400e6);
        vault.attest(2e8);
        assertEq(vault.assetsForShares(aliceShares), 2_000e6);
        assertEq(vault.assetsForShares(bobShares), 800e6);
        assertEq(tBill.balanceOf(alice), aliceShares);
        assertEq(tBill.balanceOf(bob), bobShares);
    }

    function test_Ex4_NoKyc_NoShares_EvenIfYouPay() public {
        usdc.faucet(attacker, 100e6);
        vm.startPrank(attacker);
        usdc.approve(address(vault), 100e6);
        vm.expectRevert(abi.encodeWithSelector(TBillToken.NotWhitelisted.selector, attacker));
        vault.subscribe(100e6);
        vm.stopPrank();
        assertEq(tBill.balanceOf(attacker), 0);
    }

    function test_Ex4_TransferChecksBothEndpoints() public {
        _subscribe(alice, 1_000e6);
        vm.expectRevert(abi.encodeWithSelector(TBillToken.NotWhitelisted.selector, attacker));
        vm.prank(alice);
        tBill.transfer(attacker, 1e18);
        assertEq(tBill.balanceOf(attacker), 0);
    }

    function test_Ex4_FreezeBeatsConfiscation() public {
        _subscribe(alice, 1_000e6);
        compliance.setWhitelisted(alice, false);
        vm.expectRevert(abi.encodeWithSelector(TBillToken.NotWhitelisted.selector, alice));
        vm.prank(alice);
        tBill.transfer(bob, 1e18);
        vm.expectRevert(abi.encodeWithSelector(TBillToken.NotWhitelisted.selector, alice));
        tBill.burn(alice, 1_000e18);
        assertEq(tBill.balanceOf(alice), 1_000e18);
    }
}
