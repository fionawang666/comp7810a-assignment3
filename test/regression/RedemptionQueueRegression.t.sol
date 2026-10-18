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

/// @notice Additional edge cases; the lecturer's queue acceptance tests remain unchanged.
contract RedemptionQueueRegressionTest is Test {
    MockUSDC internal usdc;
    TBillToken internal tBill;
    TBillVault internal vault;
    RedemptionQueue internal queue;
    address internal alice = makeAddr("regressionAlice");
    address internal bob = makeAddr("regressionBob");

    function setUp() public {
        usdc = new MockUSDC();
        ComplianceRegistry compliance = new ComplianceRegistry(address(this));
        MockPriceFeed feed = new MockPriceFeed(1e8);
        tBill = new TBillToken(address(this), compliance);
        MockTBillCustodian custodian = new MockTBillCustodian(address(this));
        vault = new TBillVault(usdc, tBill, feed, custodian, address(this));
        queue = new RedemptionQueue(vault, tBill, usdc, address(this));
        tBill.grantRole(tBill.MINTER_ROLE(), address(vault));
        tBill.grantRole(tBill.MINTER_ROLE(), address(queue));
        custodian.grantRole(custodian.CUSTODIAN_ROLE(), address(vault));
        vault.setQueue(address(queue));
        compliance.setWhitelisted(alice, true);
        compliance.setWhitelisted(bob, true);
        compliance.setWhitelisted(address(queue), true);
    }

    function _subscribeAndEnqueue(address user, uint256 assets) internal {
        usdc.faucet(user, assets);
        vm.startPrank(user);
        usdc.approve(address(vault), assets);
        vault.subscribe(assets);
        uint256 shares = tBill.balanceOf(user);
        tBill.approve(address(queue), shares);
        queue.enqueue(shares);
        vm.stopPrank();
    }

    function test_FifoDoesNotSkipAnUnaffordableHeadForASmallerTicket() public {
        _subscribeAndEnqueue(alice, 1_000e6);
        _subscribeAndEnqueue(bob, 400e6);

        assertEq(queue.settle(500e6), 0);
        assertEq(queue.head(), 0);
        assertEq(queue.claimable(alice), 0);
        assertEq(queue.claimable(bob), 0);
        assertFalse(queue.requestAt(0).settled);
        assertFalse(queue.requestAt(1).settled);
        assertEq(queue.pendingShares(), 1_400e18);
        assertEq(queue.pendingAssets(), 1_400e6);
    }

    function test_InsufficientReservesRollBackTheWholeBatch() public {
        _subscribeAndEnqueue(alice, 1_000e6);
        _subscribeAndEnqueue(bob, 1_000e6);
        vault.invest(500e6);
        // The first ticket fits; failure on the second must also undo the first.
        vm.expectRevert(TBillVault.InsufficientReserves.selector);
        queue.settle(2_000e6);

        assertEq(queue.head(), 0);
        assertEq(queue.pendingShares(), 2_000e18);
        assertEq(queue.pendingAssets(), 2_000e6);
        assertEq(queue.totalClaimable(), 0);
        assertEq(queue.claimable(alice), 0);
        assertEq(queue.claimable(bob), 0);
        assertFalse(queue.requestAt(0).settled);
        assertFalse(queue.requestAt(1).settled);
        assertEq(tBill.totalSupply(), 2_000e18);
        assertEq(tBill.balanceOf(address(queue)), 2_000e18);
        assertEq(vault.reserveBalance(), 1_500e6);
        assertEq(usdc.balanceOf(address(queue)), 0);
    }

    function test_FailedEscrowTransferCreatesNoTicketOrLiability() public {
        usdc.faucet(alice, 1_000e6);
        vm.startPrank(alice);
        usdc.approve(address(vault), 1_000e6);
        vault.subscribe(1_000e6);
        // There is no share allowance for the queue.
        vm.expectRevert(
            abi.encodeWithSelector(
                bytes4(keccak256("ERC20InsufficientAllowance(address,uint256,uint256)")),
                address(queue),
                0,
                1_000e18
            )
        );
        queue.enqueue(1_000e18);
        vm.stopPrank();

        assertEq(queue.queueLength(), 0);
        assertEq(queue.pendingShares(), 0);
        assertEq(queue.pendingAssets(), 0);
        assertEq(tBill.balanceOf(alice), 1_000e18);
        assertEq(tBill.balanceOf(address(queue)), 0);
    }
}
