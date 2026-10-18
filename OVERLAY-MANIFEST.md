# Modification manifest

This is an **overlay** for the professor's official `hgwoops/rwa-lab-2026` repository, not a standalone project. Merge it into a clone of the official repository and keep its `lib/` dependencies.

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

Missing from this overlay **by design**: official `src/` core contracts, official `test/exercises/02_QueueTasks.t.sol` (unchanged acceptance tests), `script/Deploy.s.sol`, and the required `lib/` dependencies. These must come from the original professor repository. Do not upload this overlay alone to Moodle.

**Not yet verified**: Solidity compilation, Foundry acceptance tests, Sepolia transactions, Etherscan source code verification. The attached guide explains how to produce genuine results in your Codespace. No actual deployment addresses are fabricated.

| Container environment | `.devcontainer/Dockerfile` extends professor image with Python 3 and ZIP tools, preserving Foundry v1.8.3 |
