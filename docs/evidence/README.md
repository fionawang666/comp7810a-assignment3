# Submission evidence index

## Sepolia deployment verification

The student confirmed seven successful Ethereum Sepolia deployments, six
successful setup transactions, and 29 successful on-chain configuration checks.
The network is chain ID `11155111`; the public deployer is
`0x87b370f0f860831DA4000dDAF742f8fa7fdbB549`. The completed deployment record and
explorer links are in [the Sepolia record](../deployment-sepolia.md).

The seven original Etherscan screenshots were committed to `main` in
`bdc8dc1`. All seven links below resolve to existing PNG files. Each original
image was inspected directly: it displays Sepolia Testnet and the corresponding
contract address recorded in the deployment table. Match classifications below
transcribe only the legible verification labels in the original images.

| Contract | Authentic Etherscan screenshot | Visible match classification |
|---|---|---|
| MockUSDC | [01-mockusdc.png](01-mockusdc.png) | Similar Match |
| ComplianceRegistry | [02-compliance.png](02-compliance.png) | Similar Match |
| MockPriceFeed | [03-pricefeed.png](03-pricefeed.png) | Similar Match |
| TBillToken | [04-tbilltoken.png](04-tbilltoken.png) | Similar Match |
| MockTBillCustodian | [05-custodian.png](05-custodian.png) | Similar Match |
| TBillVault | [06-vault.png](06-vault.png) | Similar Match |
| RedemptionQueue | [07-queue.png](07-queue.png) | Exact Match |

The original images support six Similar Match records and one Exact Match
record, for RedemptionQueue. These observations describe the captured explorer
pages; they are not a new live-chain or explorer query. No screenshot has been
generated, recreated or modified by this update.

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
