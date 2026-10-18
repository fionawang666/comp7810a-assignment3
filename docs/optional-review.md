# Optional extension review: reproduced failures and actual results

Repository: `/workspace/comp7810a-assignment3`.
Toolchain: `source /workspace/cloud-setup/env.sh` (Foundry v1.8.3, Solc 0.8.24).

## Root cause and correction

Both failures were in the student completion overlay, `test/tier3/OptionalExtensions.t.sol`:

- `test_Tier3_StaleNavRejected`
- `test_Tier3_StalePriceActuallyBlocksSubscriptions`

The contracts already rejected the stale feed with the correct parameterized custom error:
`StaleNav(864000, 867601)`. The tests supplied only its four-byte selector to
`vm.expectRevert(bytes4)`, which this Foundry toolchain compares against the complete
error. Both expectations now use `abi.encodeWithSelector` and assert the precise
publication and current timestamps. No lecturer acceptance test was edited or weakened.

## Review and additional coverage

Reviewed all five optional contracts: `NavSafetyReader`, `ChainlinkNavAdapter`,
`GuardedSubscriptionVault`, `RegulatedTransferPolicy`, `RegulatedTBillToken`.
No semantic contract change was justified by the review. Those files were formatted.
The adapter deliberately preserves raw round metadata; the safety reader validates
it. The subscription checks freshness before moving cash. Token mint, burn, direct
transfer, and delegated transfer all route through policy checks.

Added 11 tests covering:

- Exactly `maxAge` accepted, `maxAge + 1` rejected; zero and future publication times rejected.
- Zero feed, zero maximum age, and unsupported precision rejected.
- Negative NAV and NAV rounded to zero rejected; smallest representable positive NAV accepted.
- Six-decimal normalization across 256 fuzz cases.
- Zero adapter source rejected; invalid round metadata passes through and is rejected by the reader.
- Stale subscriptions preserve balances, allowance and total supply.
- Compliance mint failure rolls back the preceding cash transfer and allowance spend.
- Zero/dust subscriptions fail before moving cash.
- Frozen receivers, deverified senders, delegated transfer and redemption burn obey policy.
- Unauthorized identity, freeze, mint and burn operations revert with exact AccessControl errors.

## Actual commands and exit codes

| Stage | Command | Actual result | Exit code | Full output |
|---|---|---|---|---|
| Before changes | `forge test --match-path test/tier3/OptionalExtensions.t.sol -vvv` | 4 passed, 2 failed, 0 skipped | 1 | `evidence/optional-before.log` |
| After changes | `forge test --match-path test/tier3/OptionalExtensions.t.sol -vvv` | 17 passed, 0 failed, 0 skipped; fuzz test 256 runs | 0 | `evidence/optional-after.log` |
| Formatting | `forge fmt --check src/tier3 test/tier3` | No formatting differences | 0 | `evidence/optional-fmt.log` |

Exact exit-code sidecars are saved beside each log (`optional-before.exit`,
`optional-after.exit`, `optional-fmt.exit`). No deployment was attempted by this review.

## Scope limits

These are optional local proofs of concept, not an assertion of ERC-3643 compliance
or readiness for a real fund. The standalone safety reader does not alter the base
seven-contract lab; its guarded subscription consumer demonstrates the stale-data
block. The Chainlink adapter must point to a feed that economically represents the
fund NAV, not an unrelated asset price. No external verification result, screenshot,
deployment address, or wallet credential was created or claimed here.
