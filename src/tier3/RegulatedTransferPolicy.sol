// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/// @notice Simplified ERC-3643-inspired on-chain identity / freeze registry.
/// @dev NOT a full ERC-3643 implementation. Production needs ONCHAINID,
///      claim issuers, jurisdictions, transfer restrictions and recovery governance.
contract RegulatedTransferPolicy is AccessControl {
    bytes32 public constant AGENT_ROLE = keccak256("AGENT_ROLE");
    mapping(address => bool) public verified;
    mapping(address => bool) public frozen;
    event IdentityStatus(address indexed account, bool approved);
    event FreezeStatus(address indexed account, bool isFrozen);

    constructor(address admin) {
        require(admin != address(0), "zero admin");
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(AGENT_ROLE, admin);
    }

    function setVerified(address account, bool yes) external onlyRole(AGENT_ROLE) {
        require(account != address(0), "zero account");
        verified[account] = yes;
        emit IdentityStatus(account, yes);
    }

    function setFrozen(address account, bool yes) external onlyRole(AGENT_ROLE) {
        require(account != address(0), "zero account");
        frozen[account] = yes;
        emit FreezeStatus(account, yes);
    }

    function eligible(address account) public view returns (bool) {
        return verified[account] && !frozen[account];
    }
}
