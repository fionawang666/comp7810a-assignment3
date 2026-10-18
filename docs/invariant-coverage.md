# Randomized invariant progress evidence

No repository sources or default test settings were edited for these diagnostic runs. All commands started with `source /workspace/cloud-setup/env.sh`.

## Requested verbose trace

```sh
FOUNDRY_INVARIANT_RUNS=1 FOUNDRY_INVARIANT_DEPTH=500 FOUNDRY_FUZZ_SEED=0x7810 \
  forge test --match-contract InvariantTasksTest --match-test invariant -vvvv
```

Raw output: `evidence/invariant-coverage.log`. Actual test exit code: **0**. Both invariants passed; Foundry reported one run, 500 calls and zero reverts. The earlier depth-128 run is retained as `evidence/invariant-coverage-depth128.log`; it settled dust tickets but had no positive cash claims, so it was insufficient evidence of the cash path.

The depth-500 trace contains 62 successful enqueue events, 29 settlement calls which advanced at least one ticket, 62 settled tickets including 15 positive-cash tickets, and 11 successful claim events. Settled and claimed assets both total **317,729,872,753 USDC smallest units**. The final getter traces report `ghost_enqueuedShares == ghost_burnedShares == 259918982252410358177966` and `ghost_settledTickets == 62`.

## Actual operation-counter storage proof

The existing invariant bodies do not call `ghost_enqueues()`, `ghost_settles()` or `ghost_claims()`, so their getters cannot appear in a `-vvvv` trace. To read the actual counters without editing the tests, an additional run used the identical environment and command with `-vvvvv`, which prints storage changes. `forge inspect BridgeHandler storage-layout --json` supplies each counter's source-declared storage slot.

Raw output: `evidence/invariant-coverage-storage.log`. Layout: `evidence/handler-storage-layout.json`. Actual test exit code: **0**. One run, 500 calls, zero reverts.

| Actual final counter | Storage slot | Value | Final write, raw log line |
| --- | ---: | ---: | ---: |
| ghost_enqueues | 38 | 62 | 10937 |
| ghost_settles | 39 | 30 | 10977 |
| ghost_claims | 40 | 10 | 9280 |
| ghost_settledTickets | 42 | 62 | 10978 |
| ghost_settledAssets | 44 | 292136409111 | 8954 |
| ghost_claimedAssets | 45 | 292136409111 | 9281 |

An independent parser cross-checked those actual storage values against 62 `RedeemRequested` events, 30 event-bearing settle calls, 62 `Settled` events, 10 `Claimed` events and the respective cash sums. Thirteen tickets in this run had positive cash payouts. These cross-checks all passed; the output with line locations is `evidence/invariant-coverage-counters.json`.

The fixed fuzz seed is confirmed in `forge config --json` as `0x7810`. Separate diagnostic executions produced different cash totals despite that configured seed; the values above belong to their explicitly named raw logs and must not be combined as one sequence. Both demonstrate nonzero real randomized enqueue, settlement and claim activity, independently of the deterministic T+1 test or selector dispatch totals.

A separate solvency-only trace is also retained in `evidence/invariant-coverage-solvency.log` (exit 0). Its final actual getter traces report `ghost_settledAssets() == ghost_claimedAssets() == 460991693652` for that distinct execution.
