# Historical completion-overlay manifest

This manifest records the original completion **overlay** for the lecturer's `hgwoops/rwa-lab-2026` repository. It describes the package before assembly, not the current completed project. The full source and dependencies have since been assembled and validated; the student has subsequently completed the seven Sepolia deployments and source-code verifications. Current status is documented in [README.md](README.md), [the completion report](docs/completion-report.md) and [the evidence index](docs/evidence/README.md).

| Official assignment | Included file(s) |
|---|---|
| Ex2 / Ex3 / Ex4 | `test/exercises/01_BridgeTasks.t.sol` (7 required test implementations) |
| Ex5 | `src/exercises/RedemptionQueue.sol` (4 queue TODOs) |
| Ex6 | `test/exercises/03_InvariantTasks.t.sol` (3 handler methods + 2 invariants) |
| Ex7 optional | `test/challenges/FalseNav.t.sol` (False NAV exploit) |
| NAV staleness optional | `src/tier3/NavSafetyReader.sol`, `GuardedSubscriptionVault.sol` |
| Identity permission optional | `src/tier3/RegulatedTransferPolicy.sol`, `RegulatedTBillToken.sol` |
| Chainlink adapter optional | `src/tier3/ChainlinkNavAdapter.sol` |
| Tier 3 local tests | `test/tier3/OptionalExtensions.t.sol` |
| Discussion | `STUDENT-QUESTIONS.md` (8 essays and table E) |
| Diagram | `docs/architecture.svg` + PNG preview |
| README | run `python3 scripts/finish-readme.py` once inside the original repo |
| Private-key hygiene | run `python3 scripts/harden-demo-keys.py` inside the original repo |
| Preflight and evidence | `scripts/preflight-project.py`, `scripts/audit-submission.py`, `scripts/capture-checks.py` |
| Final packaging | `scripts/package-submission.py` |

The original overlay omitted the following **by design**: official `src/` core contracts, official `test/exercises/02_QueueTasks.t.sol` (unchanged acceptance tests), `script/Deploy.s.sol`, and the required `lib/` dependencies. These files were subsequently imported from the lecturer repository, including all 662 bundled library files. The overlay alone was never a complete submission.

**Historical verification status:** compilation, Foundry acceptance tests,
Sepolia transactions and explorer verification were unverified when the overlay
was created. This status was superseded by the captured implementation checks
and the student-confirmed seven-contract Sepolia deployment. The actual
addresses and Code links now appear in the README. All seven authentic
verification screenshots are committed in `bdc8dc1` and linked in the evidence
index. No deployment address or verification image was invented.

The container configuration extends the lecturer image with Python 3 and ZIP
tools while preserving Foundry v1.8.3.
