# Submission evidence index

## Sepolia deployment verification

The student confirmed seven successful Ethereum Sepolia deployments, six
successful setup transactions, and 29 successful on-chain configuration checks.
The network is chain ID `11155111`; the public deployer is
`0x87b370f0f860831DA4000dDAF742f8fa7fdbB549`. The completed deployment record and
explorer links are in [the Sepolia record](../deployment-sepolia.md).

The student identifies the following seven files as the original authentic
Etherscan screenshots. The links retain the supplied filenames. At the time of
this index update, these PNG files were not present in the available repository
checkout, so their visible verification classifications could not be inspected.
No Exact Match or Similar Match classification is inferred from a filename or
from another contract's verification record.

| Contract | Authentic Etherscan screenshot | Visible match classification |
|---|---|---|
| MockUSDC | [01-mockusdc.png](01-mockusdc.png) | Not assessed. |
| ComplianceRegistry | [02-compliance.png](02-compliance.png) | Not assessed. |
| MockPriceFeed | [03-pricefeed.png](03-pricefeed.png) | Not assessed. |
| TBillToken | [04-tbilltoken.png](04-tbilltoken.png) | Not assessed. |
| MockTBillCustodian | [05-custodian.png](05-custodian.png) | Not assessed. |
| TBillVault | [06-vault.png](06-vault.png) | Not assessed. |
| RedemptionQueue | [07-queue.png](07-queue.png) | Not assessed. |

All seven source-code verification records were confirmed by the student, and
some display Similar Match. Record a contract's Exact Match or Similar Match
classification only when that wording is legible in its original screenshot.
When the wording is not visible, leave the classification unassigned. The PNG
files must be available at the linked paths before final submission review;
no screenshots have been generated, recreated or modified by this update.

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
service credentials. Transaction hashes, remote command exit codes and screenshot
classifications have not been reconstructed from assumptions.
