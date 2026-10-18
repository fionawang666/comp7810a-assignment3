# Assignment Three completion and verification report

Documentation review branch: `codex/final-screenshot-consistency` in
`fionawang666/comp7810a-assignment3`. Implementation
[PR #1](https://github.com/fionawang666/comp7810a-assignment3/pull/1) was merged
by the student at **2026-10-18 16:22:35 UTC**. This documentation update is a
separate review from that completed implementation merge.
Evidence files record their actual UTC timestamps. The client timezone is
Asia/Shanghai. The student has
confirmed completion of the seven Sepolia deployments and Etherscan source
verification. All seven original screenshot files are now included and have
been inspected. **Moodle submission is not complete**: the final submission
package must still be checked and uploaded by the student.

## Result and two original failures

At the captured implementation checkpoint, all seven required check commands
actually exited **0**. The full Foundry run
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

| Requirement | Status and evidence |
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
| Tier 2, seven Sepolia deployments | Student confirms seven contract creations, six setup transactions, all 29 deployment checks and seven Etherscan source verifications. Some explorer results are Similar Match. All seven original screenshots are committed in `bdc8dc1`, linked and inspected; six display Similar Match and RedemptionQueue displays Exact Match. |

The formal PDF was unavailable. Questions were verified against lecturer source;
rubric priorities and 40%/20%/25%/15% weights follow the user's supplied brief.
This report does not claim independent PDF verification or a guaranteed grade.

## Sepolia deployment and verification status

The following external results are recorded from the student's confirmation;
they are not presented as an independent RPC rerun. Screenshot classifications
were subsequently checked against the original images, as noted below:

- Network: Sepolia, chain ID **11155111**.
- Public deployer:
  [`0x87b370f0f860831DA4000dDAF742f8fa7fdbB549`](https://sepolia.etherscan.io/address/0x87b370f0f860831DA4000dDAF742f8fa7fdbB549).
- Transactions: all **seven contract-creation transactions and six setup
  transactions** succeeded.
- Deployment validation: the student reports that
  `python3 scripts/check-deployment.py --chain-id 11155111` passed **29 checks**.
  No independently captured Sepolia command exit code is asserted here.
- Source verification: the student reports that **all seven contracts are
  verified on Sepolia Etherscan**. Some results are **Similar Match**; the report
  does not represent them as Exact Match. See the
  [README's Sepolia deployment table](../README.md#deployment-sepolia) for the
  seven public contract addresses and their explorer links.
- Screenshots: all seven original PNGs were committed in `bdc8dc1` and are
  linked in [the evidence index](evidence/README.md). All seven links resolve
  to existing files; each image shows Sepolia Testnet and the corresponding
  deployed address. Six show Similar Match; RedemptionQueue shows Exact Match.
  The original images have not been altered or substituted.

Earlier statements and evidence recording an undeployed project describe the
initial local-checkpoint stage. They remain part of the audit history; the
student-confirmed deployment above supersedes that earlier deployment status.
No new deployment or further wallet transaction is required by this report.

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
| `python3 scripts/capture-checks.py --check-evidence` | Successful evidence at the captured implementation checkpoint | 0 |
| `forge clean`, then `forge build` | Clean build, compiler successful with warnings | 0 each |
| `python3 scripts/preflight-project.py` | Files, TODO completion, diagram embed, eight answer lengths pass | 0 |
| `python3 scripts/harden-demo-keys.py` | Key-use hygiene check passes | 0 |
| `python3 scripts/local-walkthrough.py --port 18546` | Actual local broadcast and full Ex1 round trip pass | 0 |
| `python3 /workspace/work/package-review.py` | Six scratch packaging/secret-selection regression checks pass | 0 |
| `python3 scripts/audit-submission.py` | Historical, before the student-confirmed deployment: readiness failed because seven real Sepolia rows were missing | 1 |
| `python3 scripts/package-submission.py` | Historical, before the student-confirmed deployment: final ZIP refused because those deployment rows were missing | 1 |
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

The two historical readiness failures above must not be interpreted as current
deployment failures. Their raw logs are preserved in
`evidence/final-audit.log` and `evidence/final-package.log`. The current
local checks are recorded separately below. The packager was not executed
during this documentation update.

## Documentation finalization and current audit

The README now records the seven actual Sepolia addresses and their Etherscan
Code links, together with the student-confirmed seven creations, six setup
transactions and 29 configuration checks. Historical preparation remains
explicitly separated from this completed deployment. Source-code verification
is not uniformly classified as Exact Match: inspection of the original images
supports six Similar Match labels and one Exact Match label for RedemptionQueue.

The preceding documentation-finalization update changed the following
documentation and local check-evidence files:

- `README.md`, `docs/deployment-sepolia.md` and `docs/completion-report.md`:
  completed deployment, verification provenance and current readiness status.
- `docs/evidence/README.md`: evidence index, now updated with seven existing
  screenshot links and the match classifications visible in the original images.
- `OVERLAY-MANIFEST.md`, `START-HERE-中文.md`, `docs/local-walkthrough.md` and
  `docs/packaging-review.md`: professional English status updates that preserve
  the earlier preparation and audit history.
- `docs/evidence/documentation-check-evidence.log`,
  `docs/evidence/documentation-audit.log` and
  `docs/evidence/documentation-checks.json`: actual output and exit-code records
  from this documentation update.

| Requested command | Actual output summary | Exit code |
|---|---|---:|
| `python3 scripts/capture-checks.py --check-evidence` | `Evidence current: all seven required commands exited 0 for this source snapshot.` | 0 |
| `python3 scripts/audit-submission.py` | Evidence current; all eight answer word counts accepted; `Preflight: PASS` | 0 |

The complete outputs are preserved in the two new logs, and the JSON record
contains their exact argument lists, exit codes and execution timestamp.
These are local validation results. They are not a fresh full Foundry run or
a second execution of the student's Sepolia checker. Contracts, Foundry
configuration, deployment scripts, tests, package and audit scripts, dependencies,
assignment answers and architecture images remain unchanged.

**Screenshot consistency review:** all seven original PNGs from `bdc8dc1`
are present and linked. Their visible addresses and match labels have been
checked directly against the deployment record and evidence index. Original
screenshot files remain unchanged. The automated audit alone does not perform
image inspection or establish a current live explorer status.
No final ZIP was created and nothing was submitted to Moodle during this
update. Packaging and the final submission review remain subsequent steps.

## Implementation changes retained from the merged pull request

The initial repository contained a README and completion archive. The merged
implementation assembled the full lecturer project plus the overlay while
preserving student Git history and removing the temporary archive from the
tracked final tree.
That pull request included the complete source and 662 unchanged library files.
The principal implementation and review changes retained in the project are:

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

During the repository implementation work, no wallet private key or mnemonic
was requested, read, used or committed. The local helper only inherited a narrow
runtime-variable allowlist, and signing in Anvil used RPC unlocked accounts.
The student subsequently executed the reported Sepolia deployment; the
assistant did not submit those transactions. No explorer screenshot was
invented. The student later merged implementation PR #1; this follow-up
documentation update remains subject to its own review.
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

1. Review the documentation follow-up, written answers, diagram and the actual
   Assignment Three PDF. Implementation PR #1 has already been merged by the
   student; review and approve any subsequent documentation merge separately.
2. Review the recorded Sepolia address table against the student's successful
   deployment and verification records. Preserve the public deployer and chain
   ID, and distinguish Exact Match from Similar Match for each contract where
   the explorer provides that status. Deployment itself is student-confirmed
   complete; no additional broadcast approval is requested.
3. Retain the seven original explorer screenshots and the evidence index's
   observed match labels: six Similar Match and Exact Match for RedemptionQueue.
   Include real transaction or verification records where required by the
   assignment; do not create replacement screenshots or invent command results.
4. Revalidate the existing evidence and run the audit and packager for the final
   submission package. Recapture the full Foundry checks only if
   the tested source changes or the evidence validator fails. Inspect the
   final ZIP: keep complete `lib/`,
   exclude Git history, caches, `.env*`, wallets and credentials. Upload the ZIP
   to Moodle, confirm final submitted status and save authentic confirmation.
   The user reports the extended deadline as **20 October 2026, 23:55**; use the
   course page's displayed timezone and deadline.
