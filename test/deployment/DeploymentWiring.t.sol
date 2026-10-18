// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Deploy} from "../../script/Deploy.s.sol";

/// @notice Exercise the real deployment script, including every permission the loop needs.
contract DeploymentWiringTest is Test {
    function test_Deployment_WiresRolesAndCompletesRedemption() public {
        address admin = makeAddr("deployment-admin");
        vm.setEnv("DEPLOYER", vm.toString(admin));
        Deploy.Deployment memory d = (new Deploy()).run();

        assertEq(address(d.tBill.compliance()), address(d.compliance));
        assertEq(address(d.vault.usdc()), address(d.usdc));
        assertEq(address(d.vault.tBill()), address(d.tBill));
        assertEq(address(d.vault.navFeed()), address(d.feed));
        assertEq(address(d.vault.custodian()), address(d.custodian));
        assertEq(d.vault.queue(), address(d.queue));
        assertEq(address(d.queue.vault()), address(d.vault));
        assertEq(address(d.queue.tBill()), address(d.tBill));
        assertEq(address(d.queue.usdc()), address(d.usdc));
        assertTrue(d.compliance.isWhitelisted(admin));
        assertTrue(d.compliance.isWhitelisted(address(d.queue)));
        assertTrue(d.tBill.hasRole(d.tBill.MINTER_ROLE(), address(d.vault)));
        assertTrue(d.tBill.hasRole(d.tBill.MINTER_ROLE(), address(d.queue)));
        assertTrue(d.custodian.hasRole(d.custodian.CUSTODIAN_ROLE(), address(d.vault)));
        assertTrue(d.vault.hasRole(d.vault.REPORTER_ROLE(), admin));
        assertTrue(d.vault.hasRole(d.vault.OPERATOR_ROLE(), admin));
        assertTrue(d.queue.hasRole(d.queue.SETTLER_ROLE(), admin));

        vm.startPrank(admin);
        d.usdc.faucet(admin, 1000e6);
        d.usdc.approve(address(d.vault), 1000e6);
        d.vault.subscribe(1000e6);
        d.vault.invest(100e6);
        assertEq(d.custodian.realHoldings(), 100e6);
        d.tBill.approve(address(d.queue), 1e18);
        d.queue.enqueue(1e18);
        assertEq(d.queue.settle(1e6), 1e6);
        assertEq(d.queue.claim(), 1e6);
        vm.stopPrank();

        assertEq(d.usdc.balanceOf(admin), 1e6);
        assertEq(d.tBill.balanceOf(admin), 999e18);
        assertEq(d.queue.pendingShares(), 0);
        assertEq(d.queue.totalClaimable(), 0);
    }
}
