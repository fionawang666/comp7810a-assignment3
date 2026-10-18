// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {TBillToken} from "../TBillToken.sol";
import {NavSafetyReader} from "./NavSafetyReader.sol";

/// @notice Optional proof-of-concept of a *used*, guarded NAV in the subscription path.
/// @dev This is not the production replacement for the seven-contract teaching system.
///      It demonstrates that `subscribe` cannot silently price from a stale feed.
contract GuardedSubscriptionVault {
    using SafeERC20 for IERC20;
    IERC20 public immutable usdc;
    TBillToken public immutable tBill;
    NavSafetyReader public immutable navReader;
    uint256 public constant SCALE = 1e20;
    error ZeroAmount();
    error DustSubscription();
    event Subscribed(address indexed user, uint256 assets, uint256 shares, uint256 nav);

    constructor(IERC20 usdc_, TBillToken tBill_, NavSafetyReader navReader_) {
        require(
            address(usdc_) != address(0) && address(tBill_) != address(0)
                && address(navReader_) != address(0),
            "zero address"
        );
        usdc = usdc_;
        tBill = tBill_;
        navReader = navReader_;
    }

    function subscribe(uint256 assets) external returns (uint256 shares) {
        if (assets == 0) revert ZeroAmount();
        uint256 nav8 = navReader.freshNav8();
        shares = assets * SCALE / nav8;
        if (shares == 0) revert DustSubscription();
        usdc.safeTransferFrom(msg.sender, address(this), assets);
        tBill.mint(msg.sender, shares);
        emit Subscribed(msg.sender, assets, shares, nav8);
    }
}
