// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {TBillToken} from "../TBillToken.sol";
import {TBillVault} from "../TBillVault.sol";

/// @notice FIFO, all-or-nothing redemption at the NAV fixed on request day.
/// @dev The cash leg is asynchronous (T+1); claimable cash is held in this contract.
contract RedemptionQueue is AccessControl {
    using SafeERC20 for IERC20;

    TBillVault public immutable vault;
    TBillToken public immutable tBill;
    IERC20 public immutable usdc;

    bytes32 public constant SETTLER_ROLE = keccak256("SETTLER_ROLE");
    uint256 public constant NAV_PRECISION = 1e8;
    uint256 public constant SHARE_PRECISION = 1e18;
    uint256 public constant ASSET_PRECISION = 1e6;
    uint256 public constant DECIMALS_SCALE = 1e20;

    struct Request {
        address owner;
        uint256 shares;
        uint256 assetsLocked;
        bool settled;
    }

    Request[] public requests;
    uint256 public head;
    uint256 public pendingShares;
    uint256 public pendingAssets;
    uint256 public totalClaimable;
    mapping(address => uint256) public claimable;

    event RedeemRequested(
        uint256 indexed id, address indexed owner, uint256 shares, uint256 assetsLocked
    );
    event Settled(uint256 indexed id, address indexed owner, uint256 assets);
    event Claimed(address indexed owner, uint256 assets);

    error ZeroAddress();
    error ZeroAmount();
    error NothingToClaim();

    constructor(TBillVault vault_, TBillToken tBill_, IERC20 usdc_, address admin) {
        if (
            address(vault_) == address(0) || address(tBill_) == address(0)
                || address(usdc_) == address(0) || admin == address(0)
        ) revert ZeroAddress();
        vault = vault_;
        tBill = tBill_;
        usdc = usdc_;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(SETTLER_ROLE, admin);
    }

    function queueLength() external view returns (uint256) {
        return requests.length;
    }

    function requestAt(uint256 id) external view returns (Request memory) {
        return requests[id];
    }

    /// @dev The product is 26dp; USDC is 6dp. Round down, never promise unearned dust.
    function assetsAtNav(uint256 shares, uint256 nav) public pure returns (uint256) {
        return shares * nav / DECIMALS_SCALE;
    }

    /// @dev Effects are atomic with the escrow transfer: a failed transfer reverts the ticket.
    function enqueue(uint256 shares) external returns (uint256 id) {
        if (shares == 0) revert ZeroAmount();
        IERC20(address(tBill)).safeTransferFrom(msg.sender, address(this), shares);
        uint256 locked = assetsAtNav(shares, vault.navPerShare());
        id = requests.length;
        requests.push(
            Request({owner: msg.sender, shares: shares, assetsLocked: locked, settled: false})
        );
        pendingShares += shares;
        pendingAssets += locked;
        emit RedeemRequested(id, msg.sender, shares, locked);
    }

    /// @dev `assets` is a maximum cash budget, not a pro-rata fill. Never skip a head ticket.
    function settle(uint256 assets) external onlyRole(SETTLER_ROLE) returns (uint256 filled) {
        while (head < requests.length) {
            Request storage ticket = requests[head];
            uint256 due = ticket.assetsLocked;
            if (due > assets - filled) break;

            // All effects happen before touching the vault or token; a downstream revert
            // rolls the whole settlement back, including the head advancement.
            uint256 id = head;
            ticket.settled = true;
            ++head;
            pendingShares -= ticket.shares;
            pendingAssets -= due;
            claimable[ticket.owner] += due;
            totalClaimable += due;
            filled += due;

            vault.releaseReserves(address(this), due);
            tBill.burn(address(this), ticket.shares);
            emit Settled(id, ticket.owner, due);
        }
    }

    function claim() external returns (uint256 assets) {
        assets = claimable[msg.sender];
        if (assets == 0) revert NothingToClaim();
        claimable[msg.sender] = 0;
        totalClaimable -= assets;
        usdc.safeTransfer(msg.sender, assets);
        emit Claimed(msg.sender, assets);
    }
}
