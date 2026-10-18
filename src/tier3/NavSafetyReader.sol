// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IPriceFeed} from "../exercises/IPriceFeed.sol";

/// @notice Optional Tier 3: time- and round-aware NAV validation.
/// @dev This is a standalone reader. To protect the base vault in production,
///      wire this policy into ALL minting, valuation and redemption entry points.
contract NavSafetyReader {
    IPriceFeed public immutable feed;
    uint256 public immutable maxAge;
    uint8 public immutable feedDecimals;

    error InvalidFeed();
    error InvalidNav();
    error StaleNav(uint256 updatedAt, uint256 currentTime);
    error IncompleteRound();

    constructor(IPriceFeed feed_, uint256 maxAge_) {
        if (address(feed_) == address(0) || maxAge_ == 0) revert InvalidFeed();
        uint8 dp = feed_.decimals();
        if (dp > 18) revert InvalidFeed();
        feed = feed_;
        maxAge = maxAge_;
        feedDecimals = dp;
    }

    /// @return nav8 NAV per share in the lab's 8-decimal scale.
    function freshNav8() external view returns (uint256 nav8) {
        (uint80 round, int256 answer,, uint256 updatedAt, uint80 answeredInRound) =
            feed.latestRoundData();
        if (answer <= 0) revert InvalidNav();
        if (updatedAt == 0 || updatedAt > block.timestamp || block.timestamp - updatedAt > maxAge) {
            revert StaleNav(updatedAt, block.timestamp);
        }
        if (answeredInRound < round) revert IncompleteRound();
        uint256 value = uint256(answer);
        if (feedDecimals >= 8) nav8 = value / (10 ** (feedDecimals - 8));
        else nav8 = value * (10 ** (8 - feedDecimals));
        if (nav8 == 0) revert InvalidNav();
    }
}
