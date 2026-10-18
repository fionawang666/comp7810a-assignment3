# Assignment Three completion and verification report

Review branch: `codex/complete-rwa-lab` in `fionawang666/comp7810a-assignment3`.
Evidence files record their actual UTC timestamps. The client timezone is
Asia/Shanghai. This is ready for code review; **Moodle submission
is not complete**, because real Sepolia deployments and verification remain.

## Result and two original failures

All seven required check commands actually exited **0**. The full Foundry run
reported **50 passed, 0 failed, 0 skipped**. The lecturer's seven core tests and
eleven queue acceptance tests remain byte-identical to upstream. All 662
bundled library files are intact. See `source-provenance.md` for the source
commit and acceptance hashes.

The setup's reported 32 passed / 2 failed was consistent with both reproduced
Tier 3 failures. A targeted reproduction returned 4 passed / 2 failed, exit 1:
`test_Tier3_StaleNavRejected` and
`test_Tier3_StalePriceActuallyBlocksSubscriptions`. The reader correctly
returned `StaleNav(864000, 867601)`. The overlay tests expected only a selector,
which did not match the full ABI error in Foundry 1.8.3. Exact encoded error
arguments now replace those expectations; subscription rejection also checks
that cash, allowance and share supply remain unchanged. No production safety
check or lecturer assertion was removed. Raw before/after logs are in
`evidence/optional-before.log` and `evidence/optional-after.log`.

## Exercise and rubric status

| Requirement | Local status and evidence |
|---|---|
| Ex0 | Doctor passes all 6 environment checks; 7 original core tests pass. |
| Ex1 | Real local Anvil run exits 0: seven deployments, 29 decimal/wiring/role checks, funding, subscription, NAV, enqueue, settlement and claim. `local-walkthrough.md` and `evidence/ex1-local.log`. |
| Ex2 | Both custody tests pass: shares with no custody holdings, and reported holdings without cash transfer. |
| Ex3 | Both attestation tests pass: unchanged share counts, changed claim values for multiple holders. |
| Ex4 | All three admission tests pass with exact `NotWhitelisted(address)` errors, including freeze-versus-burn. |
| Ex5 | Required `1e20` conversion, escrow, fixed NAV tickets, FIFO full-ticket settlement, burns and CEI claim implemented. All 11 original acceptance tests pass. |
| Ex6 | Required handler methods and both invariants pass at 256 runs / 128,000 calls / 0 reverts. Actual state-change counters, independent ghost ledgers and deterministic T+1 test added. Separate random traces prove real enqueues, settlements and cash claims. |
| Ex7 | Both original challenge tests pass; solution preserves fixture and profit/shortfall conditions. Attacker pays 100 USDC for shares, reports NAV 5 and redeems 500, ending at 1,400 versus 1,000 initial USDC. |
| A–D | Original lecturer questions preserved verbatim; eight answers are 217, 230, 243, 236, 228, 246, 249 and 241 words. All within 150–300. |
| E | Seven real, distinct Ex2–Ex4 function names checked against source; additional exploit explains assumptions and mitigation. |
| Diagram | Reviewed and rendered SVG/PNG show all seven contracts, four planks, cash/shares/NAV/tickets/claims and the off-chain legal boundary. |
| Tier 2, seven Sepolia deployments | Deployment/verification commands and wiring checks prepared; no real Sepolia deployment or explorer verification obtained. Mandatory submission blocker. |

The formal PDF was unavailable. Questions were verified against lecturer source;
rubric priorities and 40%/20%/25%/15% weights follow the user's supplied brief.
This report does not claim independent PDF verification or a guaranteed grade.

## Real check results

Foundry v1.8.3 and native Solidity 0.8.24 were used. The full unedited combined
outputs, versions and each exit code are in `submission-checks.txt`.
`submission-checks.json` records a source snapshot digest and log digest.
The evidence validator rejects changed sources, missing commands or failures.

| Actual command | Actual result | Exit |
|---|---|---:|
| `make doctor` | 6 environment checks passed; runs the 7 original core tests | 0 |
| `make test` | 7 passed, 0 failed | 0 |
| `make exercise` | 20 passed, 0 failed; includes both properties grouped into one invariant result by this Foundry version | 0 |
| `make challenge` | 2 passed, 0 failed | 0 |
| `forge test --match-path 'test/tier3/*.t.sol' -vv` | 17 passed, 0 failed, including 256 fuzz cases | 0 |
| `forge test` | 50 passed, 0 failed, 0 skipped across 8 suites | 0 |
| `forge fmt --check` | No formatting differences | 0 |
| `python3 scripts/capture-checks.py` | All seven commands captured and source remained stable | 0 |
| `python3 scripts/capture-checks.py --check-evidence` | Current successful evidence | 0 |
| `forge clean`, then `forge build` | Clean build, compiler successful with warnings | 0 each |
| `python3 scripts/preflight-project.py` | Files, TODO completion, diagram embed, eight answer lengths pass | 0 |
| `python3 scripts/harden-demo-keys.py` | Key-use hygiene check passes | 0 |
| `python3 scripts/local-walkthrough.py --port 18546` | Actual local broadcast and full Ex1 round trip pass | 0 |
| `python3 /workspace/work/package-review.py` | Six scratch packaging/secret-selection regression checks pass | 0 |
| `python3 scripts/audit-submission.py` | Expected readiness failure: seven missing real Sepolia rows only | 1 |
| `python3 scripts/package-submission.py` | Correctly refuses a final ZIP for the same missing deployments | 1 |
| `git diff 66c314b --check` | Upstream vendored whitespace and raw terminal whitespace preserved; source/document-only diff check passes | 2 for full tree, 0 excluding vendored files and raw logs |

Additional focused queue/deployment tests passed. Random trace evidence at
one run/depth 500 showed actual nonzero progress: one execution had 62 enqueues,
29 effective settlement calls and 11 cash claims. A separate storage-visible
execution had `ghost_enqueues=62`, `ghost_settles=30`, `ghost_claims=10`, matched
against its own events. These executions are kept separate in
`invariant-coverage.md`; their values are not combined. Default full checks
retain 256 runs and 128,000 calls.

The initial localhost listener attempt exited 1 under the default sandbox;
the successful walkthrough used scoped network permission. A fresh lecturer
clone also succeeded with scoped network permission. These are resolved local
runtime restrictions, not claimed Sepolia results.

## Files and behavior changed

The initial repository contained a README and completion archive. This branch
assembles the full lecturer project plus the overlay while preserving student
Git history and removing the temporary archive from the tracked final tree.
The PR therefore includes the complete source and 662 unchanged library files.
The principal implementation/review changes are:

- `src/exercises/RedemptionQueue.sol`, `test/exercises/01_BridgeTasks.t.sol`,
  `test/exercises/03_InvariantTasks.t.sol`, and `test/challenges/FalseNav.t.sol`:
  completed exercise TODOs, exact revert checks and meaningful invariant ledgers.
- `test/regression/RedemptionQueueRegression.t.sol`: FIFO head blocking,
  batch rollback and failed-escrow atomicity; lecturer acceptance unchanged.
- `src/tier3/*`, `test/tier3/OptionalExtensions.t.sol`: five reviewed local
  prototype contracts, repaired exact stale-NAV tests and boundary/access tests.
- `script/Deploy.s.sol`, `script/BreakIt.s.sol`, `Makefile`, `.env.example`,
  `test/deployment/DeploymentWiring.t.sol`, `scripts/check-deployment.py`,
  `scripts/local-walkthrough.py`: public-address signer selection, local
  unlocked-account workflow, seven-contract wiring checks and regression.
- `STUDENT-QUESTIONS.md`, `README.md`, `START-HERE-中文.md`, `EXERCISES.md`,
  `docs/answer-review.md`, `docs/architecture.svg`, `docs/architecture.png`,
  `docs/local-walkthrough.md`, `docs/deployment-sepolia.md`: corrected written
  work, diagram, honest deployment status and reproducible instructions.
- `scripts/capture-checks.py`, `scripts/preflight-project.py`,
  `scripts/audit-submission.py`, `scripts/package-submission.py`,
  `scripts/submission-files.py`, `scripts/harden-demo-keys.py`,
  `scripts/doctor.sh`, `.gitignore`, `.github/workflows/foundry.yml`:
  real source-bound evidence, submission gates, credential exclusions,
  explicit original-core selection and repeatable CI artifact capture.

No wallet private key or mnemonic was requested, read, used or committed.
The local helper only inherited a narrow runtime-variable allowlist. Signing
in Anvil used RPC unlocked accounts. No Sepolia transaction was submitted,
no explorer screenshot was invented, and no pull request was merged.
The first-party credential-context scan found no suspicious paths; no actual
`.env` or wallet credential file was present. The repository's metadata reports
public visibility; this task did not change it.

## Remaining correctness and security limits

- The base feed is an unrestricted teaching mock: direct `setPrice` bypasses
  the vault's `REPORTER_ROLE`. Neither NAV freshness nor custody truth is
  enforced by the base contracts. The mock also stamps reads with current time,
  so its timestamps do not establish valuation age.
- FIFO tickets lock the reported NAV; correcting a false NAV later does not
  repair already queued payouts. T+1 is modeled, not a timestamp-enforced wait.
  Bad NAV, insufficient reserves, whitelist revocation or token pause can stop
  settlement. Already settled USDC credits remain claimable while shares pause.
- The exact escrow invariant covers the modeled enqueue workflow. An unsolicited
  direct share transfer can leave extra shares in the queue and break equality.
  It proves neither off-chain solvency nor redemption liveness.
- Checked multiplication can revert for unrealistic oversized values; payouts
  below one USDC unit round down. The teaching queue is not a production fund
  design or a claim that all reentrancy, gas or economic risks are resolved.
- Optional identity contracts are ERC-3643-inspired prototypes, not complete
  compliance. The AggregatorV3 adapter was tested with a local mock; it is not
  connected to a live Treasury NAV feed. The guarded subscription example does
  not retrofit all base valuation/redemption entry points.
- Clean build warnings remain: original challenge helper mutability, ignored
  oracle fields, signed conversions after positivity checks, calls/events in
  the settlement loop, timestamp comparisons and test timestamp captures.
  They were recorded rather than suppressed. Passing tests are not an audit.
- Packaging checks source/log freshness, structure, inventory and selected
  credential patterns. It cannot prove explorer verification, absence of every
  possible secret format, legal title or actual securities custody.

## USER ACTION REQUIRED

1. Review the pull request, written answers, diagram and the actual Assignment
   Three PDF. Approve any merge separately; no merge has been performed.
2. Select a separate funded Sepolia signer you control. Configure reachable
   Sepolia RPC and Etherscan credentials privately, keep keys/keystores outside
   the repository, and review the dry run in `deployment-sepolia.md`.
3. Explicitly approve the real deployment, then execute the seven-contract
   broadcast using an encrypted keystore or hardware wallet. Verify all 13
   transactions (7 creations plus 6 setup calls), run the read-only wiring
   checker and execute the seven source-verification commands.
4. Fill all seven README rows with actual distinct addresses and matching
   explorer links. Record real transaction/verification results and authentic
   Code-tab screenshots, distinguishing Exact and Similar Match.
5. Rerun capture, audit and package. Inspect the final ZIP: keep complete `lib/`,
   exclude Git history, caches, `.env*`, wallets and credentials. Upload the ZIP
   to Moodle, confirm final submitted status and save authentic confirmation.
   The user reports the extended deadline as **20 October 2026, 23:55**; use the
   course page's displayed timezone and deadline.
