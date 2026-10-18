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

contract BridgeHandler is Test {
    MockUSDC internal usdc;
    TBillToken internal tBill;
    TBillVault internal vault;
    RedemptionQueue internal queue;
    address[3] public users;
    uint256 public ghost_enqueues;
    uint256 public ghost_settles;
    uint256 public ghost_claims;
    uint256 public ghost_enqueuedShares;
    uint256 public ghost_settledTickets;
    uint256 public ghost_burnedShares;
    uint256 public ghost_settledAssets;
    uint256 public ghost_claimedAssets;
    uint256 public ghost_fundedAssets;

    constructor(MockUSDC u, TBillToken t, TBillVault v, RedemptionQueue q) {
        usdc = u;
        tBill = t;
        vault = v;
        queue = q;
        users[0] = makeAddr("user0");
        users[1] = makeAddr("user1");
        users[2] = makeAddr("user2");
        for (uint256 i; i < users.length; ++i) {
            usdc.faucet(users[i], 100_000e6);
        }
        // Mock the SPV's T+1 proceeds so fundVault exercises a real cash transfer.
        usdc.faucet(address(this), 300_000e6);
    }

    function subscribe(uint256 userSeed, uint256 amount) external {
        address user = users[bound(userSeed, 0, users.length - 1)];
        uint256 balance = usdc.balanceOf(user);
        if (balance == 0) return;
        amount = bound(amount, 1, balance);
        vm.startPrank(user);
        usdc.approve(address(vault), amount);
        vault.subscribe(amount);
        vm.stopPrank();
    }

    function attest(uint256 navSeed) external {
        vault.attest(int256(bound(navSeed, 50_000_000, 200_000_000)));
    }

    function fundVault(uint256 amount) external {
        uint256 balance = usdc.balanceOf(address(this));
        if (balance == 0) return;
        amount = bound(amount, 1, balance);
        usdc.approve(address(vault), amount);
        vault.depositReserves(amount);
        ghost_fundedAssets += amount;
    }

    function enqueue(uint256 userSeed, uint256 sharesSeed) external {
        address user = users[bound(userSeed, 0, users.length - 1)];
        uint256 balance = tBill.balanceOf(user);
        if (balance == 0) return;
        uint256 shares = bound(sharesSeed, 1, balance);
        vm.startPrank(user);
        tBill.approve(address(queue), shares);
        queue.enqueue(shares);
        vm.stopPrank();
        ++ghost_enqueues;
        ghost_enqueuedShares += shares;
    }

    function settle(uint256 assetsSeed) external {
        uint256 headBefore = queue.head();
        uint256 sharesBefore = queue.pendingShares();
        uint256 balance = vault.reserveBalance();
        uint256 assets = bound(assetsSeed, 0, balance);
        uint256 filled = queue.settle(assets);
        uint256 settledTickets = queue.head() - headBefore;
        // A successful external call may fill nothing: count actual FIFO progress.
        if (settledTickets == 0) return;
        ++ghost_settles;
        ghost_settledTickets += settledTickets;
        ghost_burnedShares += sharesBefore - queue.pendingShares();
        ghost_settledAssets += filled;
    }

    function claim(uint256 userSeed) external {
        address user = users[bound(userSeed, 0, users.length - 1)];
        if (queue.claimable(user) == 0) return;
        vm.prank(user);
        uint256 paid = queue.claim();
        ++ghost_claims;
        ghost_claimedAssets += paid;
    }
}

contract InvariantTasksTest is Test {
    MockUSDC internal usdc;
    ComplianceRegistry internal compliance;
    TBillToken internal tBill;
    MockTBillCustodian internal custodian;
    TBillVault internal vault;
    RedemptionQueue internal queue;
    BridgeHandler internal handler;
    address internal admin = address(this);

    function setUp() public {
        usdc = new MockUSDC();
        compliance = new ComplianceRegistry(admin);
        MockPriceFeed feed = new MockPriceFeed(1e8);
        tBill = new TBillToken(admin, compliance);
        custodian = new MockTBillCustodian(admin);
        vault = new TBillVault(usdc, tBill, feed, custodian, admin);
        queue = new RedemptionQueue(vault, tBill, usdc, admin);
        tBill.grantRole(tBill.MINTER_ROLE(), address(vault));
        tBill.grantRole(tBill.MINTER_ROLE(), address(queue));
        custodian.grantRole(custodian.CUSTODIAN_ROLE(), address(vault));
        vault.setQueue(address(queue));
        compliance.setWhitelisted(address(queue), true);
        handler = new BridgeHandler(usdc, tBill, vault, queue);
        for (uint256 i; i < 3; ++i) {
            compliance.setWhitelisted(handler.users(i), true);
        }
        compliance.setWhitelisted(address(handler), true);
        vault.grantRole(vault.REPORTER_ROLE(), address(handler));
        vault.grantRole(vault.OPERATOR_ROLE(), address(handler));
        queue.grantRole(queue.SETTLER_ROLE(), address(handler));
        bytes4[] memory selectors = new bytes4[](6);
        selectors[0] = BridgeHandler.subscribe.selector;
        selectors[1] = BridgeHandler.attest.selector;
        selectors[2] = BridgeHandler.fundVault.selector;
        selectors[3] = BridgeHandler.enqueue.selector;
        selectors[4] = BridgeHandler.settle.selector;
        selectors[5] = BridgeHandler.claim.selector;
        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
        targetContract(address(handler));
    }

    function invariant_EscrowConservation() public view {
        assertEq(
            tBill.balanceOf(address(queue)),
            queue.pendingShares(),
            "all outstanding shares escrowed"
        );
        assertEq(
            queue.pendingShares(),
            handler.ghost_enqueuedShares() - handler.ghost_burnedShares(),
            "escrow equals all enqueued shares less all burned shares"
        );
        assertEq(
            queue.head(), handler.ghost_settledTickets(), "head advances only for settled tickets"
        );
    }

    function invariant_SettlementSolvency() public view {
        assertGe(
            usdc.balanceOf(address(queue)), queue.totalClaimable(), "cash covers settled tickets"
        );
        uint256 totalUsersClaimable;
        for (uint256 i; i < 3; ++i) {
            totalUsersClaimable += queue.claimable(handler.users(i));
        }
        assertEq(queue.totalClaimable(), totalUsersClaimable, "no phantom cash liabilities");
        assertEq(
            queue.totalClaimable(),
            handler.ghost_settledAssets() - handler.ghost_claimedAssets(),
            "settled cash less paid claims equals remaining liability"
        );
    }

    function test_Ex6_HandlerMakesProgressThroughTPlusOne() public {
        handler.subscribe(0, 1_000e6);
        handler.enqueue(0, 1_000e18);
        assertEq(handler.ghost_enqueues(), 1);

        // Calling settle with too little budget is successful but fills no ticket.
        handler.settle(500e6);
        assertEq(handler.ghost_settles(), 0);
        assertEq(handler.ghost_settledTickets(), 0);

        vault.invest(1_000e6);
        handler.settle(1_000e6);
        assertEq(queue.head(), 0, "invested cash cannot settle a ticket");
        assertEq(handler.ghost_settles(), 0);

        handler.fundVault(1_000e6);
        assertEq(handler.ghost_fundedAssets(), 1_000e6);
        handler.settle(1_000e6);
        assertEq(handler.ghost_settles(), 1);
        assertEq(handler.ghost_settledTickets(), 1);
        assertEq(handler.ghost_burnedShares(), 1_000e18);
        assertEq(handler.ghost_settledAssets(), 1_000e6);
        invariant_EscrowConservation();
        invariant_SettlementSolvency();

        handler.claim(0);
        assertEq(handler.ghost_claims(), 1);
        assertEq(handler.ghost_claimedAssets(), 1_000e6);
        assertEq(usdc.balanceOf(handler.users(0)), 100_000e6);
        assertEq(queue.totalClaimable(), 0);
        invariant_EscrowConservation();
        invariant_SettlementSolvency();
    }
}
