# Submission evidence index

## Sepolia deployment verification

The student confirmed seven successful Ethereum Sepolia deployments, six
successful setup transactions, and 29 successful on-chain configuration checks.
The network is chain ID `11155111`; the public deployer is
`0x87b370f0f860831DA4000dDAF742f8fa7fdbB549`. The completed deployment record and
explorer links are in [the Sepolia record](../deployment-sepolia.md).

The student has saved seven authentic Etherscan screenshots, but no screenshot
file is currently present in this directory. Consequently, this index contains
no image links or invented filenames. Add each original screenshot under its
actual filename, then replace the corresponding upload status with a link.
Do not generate, recreate or modify the screenshots.

| Contract | Authentic screenshot in this repository | Match classification |
|---|---|---|
| MockUSDC | Awaiting student upload | Record the explorer's actual Exact Match or Similar Match wording after upload. |
| ComplianceRegistry | Awaiting student upload | Record the explorer's actual Exact Match or Similar Match wording after upload. |
| MockPriceFeed | Awaiting student upload | Record the explorer's actual Exact Match or Similar Match wording after upload. |
| TBillToken | Awaiting student upload | Record the explorer's actual Exact Match or Similar Match wording after upload. |
| MockTBillCustodian | Awaiting student upload | Record the explorer's actual Exact Match or Similar Match wording after upload. |
| TBillVault | Awaiting student upload | Record the explorer's actual Exact Match or Similar Match wording after upload. |
| RedemptionQueue | Awaiting student upload | Record the explorer's actual Exact Match or Similar Match wording after upload. |

All seven source-code verification records were confirmed by the student, and
some display Similar Match. The supplied confirmation did not enumerate the
per-contract match categories; none is inferred in the table above. Screenshot
upload and classification review remain manual evidence-completion steps even
when the automated audit succeeds.

## Local check evidence

- [Foundry output](../submission-checks.txt) and its
  [structured record](../submission-checks.json) retain the actual earlier
  seven-command results, including 50 passing tests. They are unchanged by this
  documentation update.
- [Evidence validation output](documentation-check-evidence.log) and
  [submission audit output](documentation-audit.log) contain the exact outputs
  of the two checks requested for this update. Both exited **0**. Their
  [structured execution record](documentation-checks.json) preserves the
  argument lists, exit codes and timestamp. Interpretation is recorded in
  [the completion report](../completion-report.md).
- `final-audit.log` and `final-package.log` are historical pre-deployment outputs
  that correctly rejected the then-incomplete deployment table. They are
  preserved rather than overwritten and do not represent the current status.
- `ex1-local.log` records the earlier Anvil demonstration on chain ID `31337`;
  it is not a Sepolia deployment transcript.

The student confirmed the remote deployment and configuration-check results.
This documentation task did not execute remote transactions or read private
service credentials. Transaction hashes, remote command exit codes and missing
screenshots have not been reconstructed from assumptions.
