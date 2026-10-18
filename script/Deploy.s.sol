// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";

import {MockUSDC} from "../src/MockUSDC.sol";
import {ComplianceRegistry} from "../src/ComplianceRegistry.sol";
import {TBillToken} from "../src/TBillToken.sol";
import {TBillVault} from "../src/TBillVault.sol";
import {MockPriceFeed} from "../src/exercises/MockPriceFeed.sol";
import {MockTBillCustodian} from "../src/exercises/MockTBillCustodian.sol";
import {RedemptionQueue} from "../src/exercises/RedemptionQueue.sol";

/// @notice Deploy the whole bridge with one command.
/// @dev The wiring at the bottom is the part you cannot skip:
///        - the vault needs MINTER_ROLE to mint shares on subscribe;
///        - the queue needs MINTER_ROLE to burn escrowed shares on settle;
///        - the vault must be told where the queue is, or it will not release reserve cash;
///        - the queue must be whitelisted, because burning its escrowed shares counts as a
///          balance change and every endpoint has to pass compliance;
///        - the custodian must recognize the vault, or `invest` cannot record the purchase.
///      Skip any of these and the loop reverts.
contract Deploy is Script {
    struct Deployment {
        MockUSDC usdc;
        ComplianceRegistry compliance;
        MockPriceFeed feed;
        TBillToken tBill;
        MockTBillCustodian custodian;
        TBillVault vault;
        RedemptionQueue queue;
    }

    /// @dev Signing is supplied by the CLI (an encrypted --account or hardware wallet).
    ///      Local Anvil may instead use --unlocked --sender "$DEPLOYER". The script
    ///      only reads the public address; it never reads a wallet private key.
    function run() external returns (Deployment memory deployed) {
        address admin = vm.envAddress("DEPLOYER");
        require(admin != address(0), "DEPLOYER must be nonzero");

        vm.startBroadcast(admin);

        MockUSDC usdc = new MockUSDC();
        ComplianceRegistry compliance = new ComplianceRegistry(admin);
        MockPriceFeed feed = new MockPriceFeed(1e8); // NAV 1.00 at launch
        TBillToken tBill = new TBillToken(admin, compliance);
        MockTBillCustodian custodian = new MockTBillCustodian(admin);
        TBillVault vault = new TBillVault(usdc, tBill, feed, custodian, admin);
        RedemptionQueue queue = new RedemptionQueue(vault, tBill, usdc, admin);

        tBill.grantRole(tBill.MINTER_ROLE(), address(vault));
        tBill.grantRole(tBill.MINTER_ROLE(), address(queue));
        custodian.grantRole(custodian.CUSTODIAN_ROLE(), address(vault));
        vault.setQueue(address(queue));
        compliance.setWhitelisted(admin, true);
        compliance.setWhitelisted(address(queue), true);

        vm.stopBroadcast();

        console.log("admin      :", admin);
        console.log("MockUSDC   :", address(usdc));
        console.log("Compliance :", address(compliance));
        console.log("NAV feed   :", address(feed));
        console.log("TBillToken :", address(tBill));
        console.log("Custodian  :", address(custodian));
        console.log("TBillVault :", address(vault));
        console.log("Queue      :", address(queue));

        deployed = Deployment(usdc, compliance, feed, tBill, custodian, vault, queue);
    }
}
