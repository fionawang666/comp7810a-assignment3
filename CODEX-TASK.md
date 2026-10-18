# Codex task — COMP7810A RWA Assignment Three

Work on **my private repository** `comp7810a-assignment3`, starting from the lecturer's `hgwoops/rwa-lab-2026` and overlay supplied in this repo. Do not edit or push to the lecturer's upstream repository.

Rules:
1. First read the formal Assignment Three grading PDF (if available), `EXERCISES.md`, `STUDENT-QUESTIONS.md` and the existing tests.
2. Run `make doctor`, `make test`, `make exercise`, `make challenge`, `forge test --match-path 'test/tier3/*.t.sol'`, and `forge test` **for real**. Fix all failures while preserving intended Ex2–Ex6 behaviors. Do not disable tests, weaken assertions, fabricate evidence or silently change the grading tests.
3. Review FIFO all-or-nothing settlement, NAV 18+8-6=20 decimals, queue whitelist and MINTER_ROLE wiring, CEI, escrow conservation, cash solvency and the false-NAV exploit.
4. Review Tier 3 as genuine **local prototypes** only: NAV staleness (valid `updatedAt`), restricted on-chain identity + freeze, Chainlink AggregatorV3 adapter. Do NOT claim these represent deployed real-world compliance or verified Treasury NAV. Add edge-case tests when genuinely valuable.
5. Check `STUDENT-QUESTIONS.md` for all eight A1–D2 answers, 150–300 words each, and accurate E test names. Fix factual inaccuracies without inventing off-chain evidence.
6. Verify README diagram, exact seven-address `## Deployment (Sepolia)` table, package scripts and redaction. Do not remove `lib/`.
7. Protect wallet secrets: never read, echo, upload, commit or copy `.env` into reports. Do not include private keys in zip or Git. Only read nonsecret env variable *presence*, never the key itself.
8. If a network-connected environment has Sepolia RPC and an Etherscan API key but no wallet configured, **do not invent** addresses or sign transactions. Ask the user before performing external deployment involving the wallet. If deployment is authorized, use a throwaway testnet-only wallet and record 7 real contract addresses and verification URLs.
9. Present actual test commands and exact results, changed files, limitations and a PR diff. Do not claim green unless actual command exit code is zero. Prefer a PR for review rather than pushing directly to main.
