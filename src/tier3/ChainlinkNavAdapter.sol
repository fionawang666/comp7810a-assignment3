// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IPriceFeed} from "../exercises/IPriceFeed.sol";

/// @dev Minimal Chainlink AggregatorV3 interface; no additional package dependency.
interface IAggregatorV3 {
    function decimals() external view returns (uint8);
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);
}

/// @notice Chainlink-compatible passthrough into the lab's IPriceFeed interface.
/// @dev A live ETH/USD price is NOT T-Bill NAV. Only use a feed that economically
///      represents the actual fund NAV, with authorized publishing and custody attestations.
contract ChainlinkNavAdapter is IPriceFeed {
    IAggregatorV3 public immutable aggregator;
    error InvalidAggregator();

    constructor(IAggregatorV3 source) {
        if (address(source) == address(0)) revert InvalidAggregator();
        aggregator = source;
    }

    function decimals() external view returns (uint8) {
        return aggregator.decimals();
    }

    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80) {
        return aggregator.latestRoundData();
    }
}
