// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {RegulatedTransferPolicy} from "./RegulatedTransferPolicy.sol";

/// @notice Optional ERC-3643-style transfer restriction example, not ERC-3643 compliant.
contract RegulatedTBillToken is ERC20, AccessControl {
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    RegulatedTransferPolicy public immutable policy;
    error IneligibleAccount(address account);

    constructor(address admin, RegulatedTransferPolicy policy_)
        ERC20("Regulated T-Bill Shares (Demo)", "rtBILL")
    {
        require(admin != address(0) && address(policy_) != address(0), "zero address");
        policy = policy_;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ISSUER_ROLE, admin);
    }

    function mint(address to, uint256 amount) external onlyRole(ISSUER_ROLE) {
        _mint(to, amount);
    }

    function redeemBurn(address from, uint256 amount) external onlyRole(ISSUER_ROLE) {
        _burn(from, amount);
    }

    function _update(address from, address to, uint256 amount) internal override {
        if (from != address(0) && !policy.eligible(from)) revert IneligibleAccount(from);
        if (to != address(0) && !policy.eligible(to)) revert IneligibleAccount(to);
        super._update(from, to, amount);
    }
}
