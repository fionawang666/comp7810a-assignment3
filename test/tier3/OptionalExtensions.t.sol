// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {IPriceFeed} from "../../src/exercises/IPriceFeed.sol";
import {NavSafetyReader} from "../../src/tier3/NavSafetyReader.sol";
import {ChainlinkNavAdapter, IAggregatorV3} from "../../src/tier3/ChainlinkNavAdapter.sol";
import {RegulatedTransferPolicy} from "../../src/tier3/RegulatedTransferPolicy.sol";
import {RegulatedTBillToken} from "../../src/tier3/RegulatedTBillToken.sol";
import {GuardedSubscriptionVault} from "../../src/tier3/GuardedSubscriptionVault.sol";
import {MockUSDC} from "../../src/MockUSDC.sol";
import {ComplianceRegistry} from "../../src/ComplianceRegistry.sol";
import {TBillToken} from "../../src/TBillToken.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

contract AdjustableFeed is IPriceFeed {
    uint8 public override decimals;
    uint80 public roundId = 1;
    uint80 public answeredInRound = 1;
    uint256 public updatedAt;
    int256 public answer;

    constructor(uint8 dp, int256 initial) {
        decimals = dp;
        answer = initial;
        updatedAt = block.timestamp;
    }

    function setData(uint80 round, uint80 answered, int256 value, uint256 timestamp) external {
        roundId = round;
        answeredInRound = answered;
        answer = value;
        updatedAt = timestamp;
    }

    function latestRoundData()
        external
        view
        override
        returns (uint80, int256, uint256, uint256, uint80)
    {
        return (roundId, answer, updatedAt, updatedAt, answeredInRound);
    }
}

contract OptionalExtensionsTest is Test {
    function test_Tier3_FreshNav_Normalizes18DecimalsToEight() public {
        vm.warp(10 days);
        AdjustableFeed feed = new AdjustableFeed(18, 1_250_000_000_000_000_000);
        NavSafetyReader reader = new NavSafetyReader(feed, 1 days);
        assertEq(reader.freshNav8(), 125_000_000);
    }

    function test_Tier3_StaleNavRejected() public {
        vm.warp(10 days);
        AdjustableFeed feed = new AdjustableFeed(8, 1e8);
        NavSafetyReader reader = new NavSafetyReader(feed, 1 hours);
        uint256 publishedAt = block.timestamp;
        vm.warp(publishedAt + 1 hours + 1);
        vm.expectRevert(
            abi.encodeWithSelector(NavSafetyReader.StaleNav.selector, publishedAt, block.timestamp)
        );
        reader.freshNav8();
    }

    function test_Tier3_NavAcceptedAtExactMaxAge() public {
        vm.warp(10 days);
        AdjustableFeed feed = new AdjustableFeed(8, 1e8);
        NavSafetyReader reader = new NavSafetyReader(feed, 1 hours);
        vm.warp(block.timestamp + 1 hours);
        assertEq(reader.freshNav8(), 1e8);
    }

    function test_Tier3_ZeroAndFutureTimestampsRejected() public {
        vm.warp(10 days);
        AdjustableFeed feed = new AdjustableFeed(8, 1e8);
        NavSafetyReader reader = new NavSafetyReader(feed, 1 hours);
        feed.setData(1, 1, 1e8, 0);
        vm.expectRevert(
            abi.encodeWithSelector(NavSafetyReader.StaleNav.selector, 0, block.timestamp)
        );
        reader.freshNav8();
        uint256 future = block.timestamp + 1;
        feed.setData(1, 1, 1e8, future);
        vm.expectRevert(
            abi.encodeWithSelector(NavSafetyReader.StaleNav.selector, future, block.timestamp)
        );
        reader.freshNav8();
    }

    function test_Tier3_InvalidReaderConfigurationRejected() public {
        vm.expectRevert(NavSafetyReader.InvalidFeed.selector);
        new NavSafetyReader(IPriceFeed(address(0)), 1 hours);
        AdjustableFeed feed = new AdjustableFeed(8, 1e8);
        vm.expectRevert(NavSafetyReader.InvalidFeed.selector);
        new NavSafetyReader(feed, 0);
        AdjustableFeed unsupported = new AdjustableFeed(19, 1e19);
        vm.expectRevert(NavSafetyReader.InvalidFeed.selector);
        new NavSafetyReader(unsupported, 1 hours);
    }

    function test_Tier3_NegativeAndRoundedToZeroNavRejected() public {
        vm.warp(10 days);
        AdjustableFeed feed = new AdjustableFeed(18, -1);
        NavSafetyReader reader = new NavSafetyReader(feed, 1 hours);
        vm.expectRevert(NavSafetyReader.InvalidNav.selector);
        reader.freshNav8();
        feed.setData(1, 1, 1e10 - 1, block.timestamp);
        vm.expectRevert(NavSafetyReader.InvalidNav.selector);
        reader.freshNav8();
        feed.setData(1, 1, 1e10, block.timestamp);
        assertEq(reader.freshNav8(), 1);
    }

    function testFuzz_Tier3_LowerPrecisionNavNormalizes(uint64 wholeAndFraction) public {
        vm.warp(10 days);
        uint256 answer6 = bound(uint256(wholeAndFraction), 1, type(uint64).max);
        AdjustableFeed feed = new AdjustableFeed(6, int256(answer6));
        NavSafetyReader reader = new NavSafetyReader(feed, 1 hours);
        assertEq(reader.freshNav8(), answer6 * 100);
    }

    function test_Tier3_IncompleteRoundAndNonPositiveNavRejected() public {
        vm.warp(10 days);
        AdjustableFeed feed = new AdjustableFeed(8, 1e8);
        NavSafetyReader reader = new NavSafetyReader(feed, 1 hours);
        feed.setData(2, 1, 1e8, block.timestamp);
        vm.expectRevert(NavSafetyReader.IncompleteRound.selector);
        reader.freshNav8();
        feed.setData(2, 2, 0, block.timestamp);
        vm.expectRevert(NavSafetyReader.InvalidNav.selector);
        reader.freshNav8();
    }

    function test_Tier3_ChainlinkAdapter_PreservesRoundMetadata() public {
        vm.warp(10 days);
        AdjustableFeed feed = new AdjustableFeed(8, 123_456_789);
        feed.setData(7, 7, 123_456_789, block.timestamp);
        ChainlinkNavAdapter adapter = new ChainlinkNavAdapter(IAggregatorV3(address(feed)));
        assertEq(adapter.decimals(), 8);
        (uint80 rid, int256 answer,, uint256 updated, uint80 answered) = adapter.latestRoundData();
        assertEq(rid, 7);
        assertEq(answer, 123_456_789);
        assertEq(updated, block.timestamp);
        assertEq(answered, 7);
    }

    function test_Tier3_ChainlinkAdapter_RejectsZeroSource() public {
        vm.expectRevert(ChainlinkNavAdapter.InvalidAggregator.selector);
        new ChainlinkNavAdapter(IAggregatorV3(address(0)));
    }

    function test_Tier3_ChainlinkAdapter_PreservesInvalidDataForReaderToReject() public {
        vm.warp(10 days);
        AdjustableFeed feed = new AdjustableFeed(6, 1e6);
        ChainlinkNavAdapter adapter = new ChainlinkNavAdapter(IAggregatorV3(address(feed)));
        NavSafetyReader reader = new NavSafetyReader(adapter, 1 hours);
        assertEq(adapter.decimals(), 6);
        assertEq(reader.freshNav8(), 1e8);
        feed.setData(9, 8, 1e6, block.timestamp);
        (uint80 round, int256 answer,, uint256 timestamp, uint80 answered) =
            adapter.latestRoundData();
        assertEq(round, 9);
        assertEq(answered, 8);
        assertEq(answer, 1e6);
        assertEq(timestamp, block.timestamp);
        vm.expectRevert(NavSafetyReader.IncompleteRound.selector);
        reader.freshNav8();
    }

    function test_Tier3_StalePriceActuallyBlocksSubscriptions() public {
        vm.warp(10 days);
        AdjustableFeed source = new AdjustableFeed(8, 1e8);
        NavSafetyReader reader = new NavSafetyReader(source, 1 hours);
        MockUSDC cash = new MockUSDC();
        ComplianceRegistry compliance = new ComplianceRegistry(address(this));
        TBillToken share = new TBillToken(address(this), compliance);
        GuardedSubscriptionVault sub = new GuardedSubscriptionVault(cash, share, reader);
        share.grantRole(share.MINTER_ROLE(), address(sub));
        address alice = makeAddr("subscribed-alice");
        compliance.setWhitelisted(alice, true);
        cash.faucet(alice, 200e6);
        vm.startPrank(alice);
        cash.approve(address(sub), 200e6);
        assertEq(sub.subscribe(100e6), 100e18);
        vm.stopPrank();
        assertEq(share.balanceOf(alice), 100e18);
        uint256 publishedAt = block.timestamp;
        vm.warp(publishedAt + 1 hours + 1);
        vm.expectRevert(
            abi.encodeWithSelector(NavSafetyReader.StaleNav.selector, publishedAt, block.timestamp)
        );
        vm.prank(alice);
        sub.subscribe(100e6);
        assertEq(cash.balanceOf(alice), 100e6);
        assertEq(cash.balanceOf(address(sub)), 100e6);
        assertEq(cash.allowance(alice, address(sub)), 100e6);
        assertEq(share.balanceOf(alice), 100e18);
        assertEq(share.totalSupply(), 100e18);
    }

    function test_Tier3_SubscriptionRejectionRollsBackCashAndAllowance() public {
        vm.warp(10 days);
        AdjustableFeed source = new AdjustableFeed(8, 1e8);
        NavSafetyReader reader = new NavSafetyReader(source, 1 hours);
        MockUSDC cash = new MockUSDC();
        ComplianceRegistry compliance = new ComplianceRegistry(address(this));
        TBillToken share = new TBillToken(address(this), compliance);
        GuardedSubscriptionVault sub = new GuardedSubscriptionVault(cash, share, reader);
        share.grantRole(share.MINTER_ROLE(), address(sub));
        address alice = makeAddr("unverified-subscriber");
        cash.faucet(alice, 100e6);
        vm.prank(alice);
        cash.approve(address(sub), 100e6);
        vm.expectRevert(abi.encodeWithSelector(TBillToken.NotWhitelisted.selector, alice));
        vm.prank(alice);
        sub.subscribe(100e6);
        assertEq(cash.balanceOf(alice), 100e6);
        assertEq(cash.balanceOf(address(sub)), 0);
        assertEq(cash.allowance(alice, address(sub)), 100e6);
        assertEq(share.totalSupply(), 0);
    }

    function test_Tier3_ZeroAndDustSubscriptionsRejectedBeforeCashTransfer() public {
        vm.warp(10 days);
        AdjustableFeed source = new AdjustableFeed(8, 1e20 + 1);
        NavSafetyReader reader = new NavSafetyReader(source, 1 hours);
        MockUSDC cash = new MockUSDC();
        ComplianceRegistry compliance = new ComplianceRegistry(address(this));
        TBillToken share = new TBillToken(address(this), compliance);
        GuardedSubscriptionVault sub = new GuardedSubscriptionVault(cash, share, reader);
        vm.expectRevert(GuardedSubscriptionVault.ZeroAmount.selector);
        sub.subscribe(0);
        vm.expectRevert(GuardedSubscriptionVault.DustSubscription.selector);
        sub.subscribe(1);
        assertEq(cash.balanceOf(address(sub)), 0);
        assertEq(share.totalSupply(), 0);
    }

    function test_Tier3_RestrictedSecurityToken_ComplianceAndFreeze() public {
        address alice = makeAddr("alice");
        address bob = makeAddr("bob");
        RegulatedTransferPolicy registry = new RegulatedTransferPolicy(address(this));
        RegulatedTBillToken token = new RegulatedTBillToken(address(this), registry);
        registry.setVerified(alice, true);
        token.mint(alice, 100e18);
        vm.expectRevert(abi.encodeWithSelector(RegulatedTBillToken.IneligibleAccount.selector, bob));
        vm.prank(alice);
        token.transfer(bob, 1e18);
        registry.setVerified(bob, true);
        vm.prank(alice);
        token.transfer(bob, 1e18);
        assertEq(token.balanceOf(bob), 1e18);
        registry.setFrozen(alice, true);
        vm.expectRevert(
            abi.encodeWithSelector(RegulatedTBillToken.IneligibleAccount.selector, alice)
        );
        vm.prank(alice);
        token.transfer(bob, 1e18);
    }

    function test_Tier3_RestrictedTransferFromAndBurnApplyEligibility() public {
        address alice = makeAddr("alice");
        address bob = makeAddr("bob");
        address broker = makeAddr("broker");
        RegulatedTransferPolicy registry = new RegulatedTransferPolicy(address(this));
        RegulatedTBillToken token = new RegulatedTBillToken(address(this), registry);
        registry.setVerified(alice, true);
        registry.setVerified(bob, true);
        token.mint(alice, 100e18);
        vm.prank(alice);
        token.approve(broker, 10e18);
        registry.setFrozen(bob, true);
        vm.expectRevert(abi.encodeWithSelector(RegulatedTBillToken.IneligibleAccount.selector, bob));
        vm.prank(broker);
        token.transferFrom(alice, bob, 10e18);
        assertEq(token.allowance(alice, broker), 10e18);
        registry.setFrozen(bob, false);
        registry.setVerified(alice, false);
        vm.expectRevert(
            abi.encodeWithSelector(RegulatedTBillToken.IneligibleAccount.selector, alice)
        );
        vm.prank(broker);
        token.transferFrom(alice, bob, 10e18);
        vm.expectRevert(
            abi.encodeWithSelector(RegulatedTBillToken.IneligibleAccount.selector, alice)
        );
        token.redeemBurn(alice, 10e18);
        assertEq(token.balanceOf(alice), 100e18);
        registry.setVerified(alice, true);
        token.redeemBurn(alice, 10e18);
        assertEq(token.balanceOf(alice), 90e18);
        assertEq(token.totalSupply(), 90e18);
    }

    function test_Tier3_PolicyAndIssuanceRequireAuthorizedRoles() public {
        address outsider = makeAddr("outsider");
        RegulatedTransferPolicy registry = new RegulatedTransferPolicy(address(this));
        RegulatedTBillToken token = new RegulatedTBillToken(address(this), registry);
        bytes32 agentRole = registry.AGENT_ROLE();
        bytes32 issuerRole = token.ISSUER_ROLE();
        bytes memory policyError = abi.encodeWithSelector(
            IAccessControl.AccessControlUnauthorizedAccount.selector, outsider, agentRole
        );
        vm.expectRevert(policyError);
        vm.prank(outsider);
        registry.setVerified(outsider, true);
        vm.expectRevert(policyError);
        vm.prank(outsider);
        registry.setFrozen(outsider, true);
        bytes memory issuerError = abi.encodeWithSelector(
            IAccessControl.AccessControlUnauthorizedAccount.selector, outsider, issuerRole
        );
        vm.expectRevert(issuerError);
        vm.prank(outsider);
        token.mint(outsider, 1);
        vm.expectRevert(issuerError);
        vm.prank(outsider);
        token.redeemBurn(outsider, 1);
        assertFalse(registry.verified(outsider));
        assertFalse(registry.frozen(outsider));
        assertEq(token.totalSupply(), 0);
    }
}
