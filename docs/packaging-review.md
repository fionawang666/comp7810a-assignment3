# Submission audit and packaging review

This document preserves the packaging review performed before the student
completed Sepolia deployment. At that checkpoint, no final submission ZIP was
generated because the seven deployment rows were placeholders and the packaging
gate correctly rejected them. The README now contains the actual deployed
addresses and verification links. Current local audit results are recorded
separately below; the original exit codes and raw logs remain historical
records. No wallet credential material was accessed during this review.

## Changes

- `scripts/submission-files.py` shares the audit/ZIP file selection. It excludes all `.env*` names (including `.env.example`), other `.env` variants, wallet/keystore/key artifacts, Git history, caches, build/broadcast output, prior archives, temporary ZIP files and symlinks. Neither the selector nor audit opens excluded credential files.
- Every eligible file in both vendored library trees is retained. The ZIP inventory must exactly match the complete selected project inventory; library entrypoint checks and the Foundry evidence gate prevent an empty or superficially present `lib/` from satisfying readiness.
- `scripts/audit-submission.py` requires the exact seven contract rows, one distinct nonzero address each, matching Sepolia Etherscan links and no deployment/verification placeholders. It checks the restored A1–D2 answer structure, section E's seven implemented function names and exploit answer, mandatory project files and the structured Foundry evidence validator.
- The credential scan reports filenames only. It recognizes explicit private/secret key assignments and command arguments, mnemonic literals and encrypted-wallet ciphertext fields, without treating ordinary SHA-256 hashes, transaction hashes or role constants as wallet keys. This heuristic still requires a student's final review; it cannot prove the absence of every secret format.
- `scripts/package-submission.py` runs the full audit first. It creates no output when that audit fails. Successful packaging writes a temporary ZIP, verifies CRC and exact file inventory, validates source/evidence freshness again and only then replaces the final ZIP atomically.
- Explorer links are structural checks. They do not prove that Etherscan has verified the source. Authentic explorer verification and screenshots still require manual review after actual deployments.

## Historical executed checks

| Command | Actual exit | Result |
|---|---:|---|
| `python3 -m py_compile scripts/audit-submission.py scripts/package-submission.py scripts/submission-files.py` | 0 | All three scripts compile. |
| `python3 scripts/audit-submission.py` | 1 | Expected block: all seven Sepolia rows are undeployed; the structured Foundry evidence was not yet captured at this execution. |
| `python3 scripts/package-submission.py` | 1 | Same expected readiness block. No final or temporary ZIP exists. This command was executed by the scratch regression script below. |
| `python3 /workspace/work/package-review.py` | 0 | Six meaningful regression checks passed, including the expected real packaging failure. |

The scratch regression script creates temporary fixtures outside the repository and removes them afterwards. It checks exclusion of environment/wallet/history/cache/archive paths and symlinks while retaining both library trees; acceptance of ordinary evidence hashes; rejection of credential-context invalid scalar fixtures; rejection of the actual seven placeholder rows; rejection of a wrong deployment heading; rejection of zero addresses; and the real packager's refusal to emit an archive. The fixture values are not deployment evidence and are not included in the project.

Answer word counts observed by the real audit: A1 217, A2 230, B1 243, B2 236, C1 228, C2 246, D1 249, D2 241. All meet 150–300 words.

The original review required capture of stable-source Foundry evidence and a
subsequent audit. At that time, the missing deployment rows were a valid
packaging blocker. The captured evidence and the student's later completed
Sepolia deployment supersede that earlier readiness status. No addresses,
screenshots or passing check outputs have been fabricated.

## Historical readiness run after Foundry capture

The root task reran both commands after capture. The evidence validator exited
0 and reported current successful results for all seven required commands.
`audit-submission.py` and `package-submission.py` still exited **1**, exclusively
because all seven real Sepolia deployment/verification rows were incomplete
at that historical checkpoint.
No final ZIP was generated. Full actual outputs are in
`evidence/final-audit.log` and `evidence/final-package.log`.

## Current documentation audit after completed deployment

After the README was updated with the student's seven actual Sepolia addresses
and matching Etherscan Code links, the following requested checks were executed:

| Command | Actual exit | Current result |
|---|---:|---|
| `python3 scripts/capture-checks.py --check-evidence` | 0 | Existing successful seven-command evidence is current for the unchanged source snapshot. |
| `python3 scripts/audit-submission.py` | 0 | `Preflight: PASS`; deployment rows, answer lengths and existing local evidence accepted. |

Full current outputs are in `evidence/documentation-check-evidence.log` and
`evidence/documentation-audit.log`, with exit-code metadata in
`evidence/documentation-checks.json`. The package script was not executed during
this update, and no new ZIP was generated.

All seven authentic explorer screenshots are now present in `docs/evidence/`
from commit `bdc8dc1`. Their links resolve to existing PNG files, and direct
image inspection supports six Similar Match labels and one Exact Match label
for RedemptionQueue. The evidence index preserves these per-contract labels.
The audit does not perform screenshot inspection or query the live explorer.
No package or audit script was modified, and no ZIP was generated during this
documentation review.
