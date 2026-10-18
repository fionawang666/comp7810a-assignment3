# Graded contract review

Reviewed the actual source contracts, EXERCISES.md, core acceptance, Ex2–Ex6 tests, and Ex7 challenge. No changes were made to `test/TBill.t.sol` or the lecturer's `test/exercises/02_QueueTasks.t.sol`.

- Ex2 proves shares exist with zero custodian holdings and that custodian holdings can change without receiving cash.
- Ex3 preserves share counts and reprices both holders from a single NAV attestation.
- Ex4 asserts exact `NotWhitelisted(address)` selectors for missing admission, receiver rejection, and frozen-holder transfer/burn rejection.
- Ex5 uses the required 18+8−6 decimal conversion, escrows shares, locks NAV, maintains strict FIFO/all-or-nothing tickets, burns settled shares, and zeroes claims before USDC transfers. Source semantics were retained; formatting was normalized.
- Ex6 originally counted no-op settle calls as settlements, and `fundVault` had no source of funds. Added mock SPV funds to the handler, counters for actual settled tickets/shares/assets and paid claims, independent cumulative share/cash ledger checks, and a deterministic T+1 sequence. No random-run minimum counter assertions were added, avoiding probabilistic failures.
- Ex7 preserves the original player-prank modifier, fixture, initial-state test, and both final challenge assertions. The player honestly buys 100 USDC of shares, attests NAV 5, locks/redeems 500 USDC, and ends with 1,400 USDC against 1,000 initial. No direct storage mutation, forged cash or admin impersonation appears in the solution body.

New regression tests independently check head-of-line blocking when a later smaller ticket would fit, full rollback after a later ticket fails reserve release, and failed escrow transfers creating no request or liability.

## Real local results

Environment: sourced `/workspace/cloud-setup/env.sh`; Foundry v1.8.3, solc 0.8.24.

1. Before edits: `forge test --match-path 'test/exercises/*.t.sol' -vv` exited 0. Output: `19 tests passed, 0 failed, 0 skipped` (7 bridge, 11 official queue, one composite invariant result). The composite invariant run reported 256 runs, 128,000 calls and 0 reverts.
2. After edits: `forge test --match-path 'test/{exercises,regression}/*.t.sol' -vv` exited 0. Full output is `evidence/graded-targeted.log`, including `EXIT_CODE=0`. Output: `23 tests passed, 0 failed, 0 skipped` across four suites. Both bridge invariants passed with 256 runs, 128,000 calls, 0 reverts. The deterministic T+1 handler test and all three new regression tests passed.
3. `forge fmt --check src/exercises/RedemptionQueue.sol test/exercises/03_InvariantTasks.t.sol test/regression/RedemptionQueueRegression.t.sol` exited 0 with no output.

The deterministic handler test asserts exactly one real enqueue/settlement/ticket/claim, 1,000e18 shares burned, 1,000e6 settlement cash, 1,000e6 deposited T+1 proceeds, and 1,000e6 paid claims. It first verifies that an insufficient-budget call and an empty-vault call do not count as settlements.

No wallet private keys were used or committed; no deployments or external verification were performed by this review subtask.
