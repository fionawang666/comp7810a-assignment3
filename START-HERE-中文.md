# Assignment Three: Project Status and Submission Preparation

The project contains the complete lecturer source, all bundled dependencies,
completed exercises, written answers and architecture diagrams. The
[README](README.md) records the seven actual Ethereum Sepolia contract addresses
and Etherscan source-code links. The student has confirmed seven successful
contract creations, six successful setup transactions, and 29 successful
on-chain decimal, wiring and permission checks on chain ID `11155111`.

All seven contracts have confirmed source-code verification records. Some
records display **Similar Match** and must not be described as Exact Match.
All seven original verification screenshots are present in `docs/evidence/`
following commit `bdc8dc1`. Their links and legible verification labels are
recorded in the [evidence index](docs/evidence/README.md): six display Similar
Match and RedemptionQueue displays Exact Match. The images remain unchanged.

The [Sepolia record](docs/deployment-sepolia.md) preserves the original workflow
as historical reproducibility instructions. Deployment has already been
completed; this documentation update does not require another broadcast.
The [local walkthrough](docs/local-walkthrough.md) describes Anvil only.

The [completion report](docs/completion-report.md) distinguishes the historical
implementation checks from the current documentation audit. The existing
Foundry evidence records 50 passing tests. Source code, test coverage,
configuration, dependencies, answers and architecture are preserved.

Before submission:

1. Review the seven linked original Etherscan screenshots and retain the
   recorded per-contract Similar Match or Exact Match classification.
2. Review the answers, architecture, evidence and formal Assignment Three PDF.
3. Run `python3 scripts/capture-checks.py --check-evidence` and
   `python3 scripts/audit-submission.py`. If the tested source changes later,
   recapture the full checks before packaging.
4. After final evidence review, prepare and inspect the submission ZIP, retaining
   complete `lib/` and excluding Git history, generated caches, environment
   files and credentials. Keep private keys, seed phrases, encrypted keystores,
   passwords and private service credentials outside the submission.
5. Submit through Moodle personally and confirm the final submitted status.
   The student reports the extended deadline as **20 October 2026, 23:55**;
   confirm the course page's displayed timezone and deadline.

No transaction was broadcast and nothing was submitted to Moodle during this
documentation update. The formal PDF was not available in the workspace;
rubric priorities follow the assignment brief supplied by the student.
