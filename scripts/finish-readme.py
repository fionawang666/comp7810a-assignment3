#!/usr/bin/env python3
"""Document the exact rubric and deliverables without inventing on-chain deployments."""
from pathlib import Path
p = Path('README.md')
if not p.exists():
    raise SystemExit('Run from the OFFICIAL rwa-lab-2026 project root.')
s = p.read_text(encoding='utf-8')
marker = '<!-- ASSIGNMENT3_CUSTOM_SECTION -->'
if marker in s:
    print('Assignment 3 README appendix already present')
    raise SystemExit(0)
appendix = '''

---

<!-- ASSIGNMENT3_CUSTOM_SECTION -->
## Assignment Three — architecture and evidence

The following diagram distinguishes **cash** (USDC, 6 decimals), **fund shares**
(tBILL, 18 decimals), **NAV** (8 decimals), and **permission checks**. The four
planks are custody, attestation, physical redemption and admission.

![Four-plank RWA bridge and share/cash flows](docs/architecture.svg)

The core lesson is that the two queue invariants guarantee on-chain bookkeeping,
not that real US Treasuries exist: `MockTBillCustodian.realHoldings()` and
`MockPriceFeed` are trusted, mutable reports. The settlement queue is FIFO;
tickets lock NAV on enqueue and settle only in full.

### Validation evidence

- Tier 1: `make doctor`, `make test`, `make exercise`.
- Optional Ex7: `make challenge`.
- Optional local prototypes: `forge test --match-path 'test/tier3/*.t.sol'`.
- Full suite: `forge test`.
- Actual outputs are recorded in `docs/submission-checks.txt` **only after**
  `python3 scripts/capture-checks.py` succeeds. No tests are claimed as passed here
  until run in Foundry.

### Optional extension scope

- **Ex7:** `test/challenges/FalseNav.t.sol` illustrates profit from a false NAV.
- **NAV age / completeness:** `NavSafetyReader` rejects stale, future, zero and
  incomplete feed rounds; it is a separately tested safety component, not
  silently wired into the teaching vault; `GuardedSubscriptionVault` shows
  the check actually blocking subscriptions when a feed becomes stale.
- **ERC-3643-inspired policy:** `RegulatedTransferPolicy` and
  `RegulatedTBillToken` demonstrate enrollment and account freezes. These are
  **not** a certified or complete ERC-3643 implementation.
- **Chainlink-compatible feed:** `ChainlinkNavAdapter` reads an AggregatorV3
  interface and preserves round metadata. Mocked local tests exist. It is
  **not** a deployed live NAV oracle. ETH/USD is not the NAV of a T-Bill fund.

## Deployment (Sepolia)

**MANDATORY Tier 2 (20% per the formal Assignment Three PDF).**
The original lab README describes this as a bonus, but the separately supplied
Assignment Three grading PDF explicitly assigns a 20% weight to it.

After deploying via `script/Deploy.s.sol`, replace *all seven* `NOT DEPLOYED YET`
entries below with your **actual** Sepolia contract address and Etherscan link.
Do not submit these placeholders as if they were deployments.

| Contract | Sepolia address | Etherscan verification |
|---|---|---|
| MockUSDC | NOT DEPLOYED YET | NOT VERIFIED YET |
| ComplianceRegistry | NOT DEPLOYED YET | NOT VERIFIED YET |
| MockPriceFeed | NOT DEPLOYED YET | NOT VERIFIED YET |
| TBillToken | NOT DEPLOYED YET | NOT VERIFIED YET |
| MockTBillCustodian | NOT DEPLOYED YET | NOT VERIFIED YET |
| TBillVault | NOT DEPLOYED YET | NOT VERIFIED YET |
| RedemptionQueue | NOT DEPLOYED YET | NOT VERIFIED YET |

Add authentic Etherscan screenshots to `docs/` only after verification.
The local deployment uses mock securities/cash; no financial asset is bought.

### README vs rubric

For grading, rely on the formal Assignment Three PDF: Ex0–Ex6 (40%),
Sepolia's seven deployments and verification (20%), A–E discussion (25%),
and documentation/architecture (15%). Optional Tier 3 is unmarked.
'''
p.write_text(s.rstrip()+appendix,encoding='utf-8')
print('README appendix added: diagram, extension scope, 7-address Sepolia table.')
