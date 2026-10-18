# Sepolia deployment record and reproducibility instructions

## Completed deployment

The student confirmed successful deployment of all seven base contracts to
**Ethereum Sepolia (chain ID `11155111`)** using public deployer address
`0x87b370f0f860831DA4000dDAF742f8fa7fdbB549`.

| Verification item | Confirmed result |
|---|---|
| Contract creation | Seven deployments succeeded. |
| Role assignment and contract wiring | All six setup transactions succeeded. |
| Total on-chain transactions | All 13 transactions succeeded. |
| Decimal, wiring and permission validation | `python3 scripts/check-deployment.py --chain-id 11155111` passed all 29 checks. |
| Etherscan source-code records | Verification was confirmed for all seven contracts; some display Similar Match. |
| Authentic screenshots | All seven original PNGs are committed in `bdc8dc1`, present in `docs/evidence/` and linked in the evidence index. |

| Contract | Sepolia address | Etherscan source-code verification |
|---|---|---|
| MockUSDC | `0x25B1A3CAD54102f0c798697057f642fa54215aEC` | [Verified source code](https://sepolia.etherscan.io/address/0x25B1A3CAD54102f0c798697057f642fa54215aEC#code) |
| ComplianceRegistry | `0x82990740bFF5089d66b323cF27187f2d0539A0c4` | [Verified source code](https://sepolia.etherscan.io/address/0x82990740bFF5089d66b323cF27187f2d0539A0c4#code) |
| MockPriceFeed | `0x9603c3E0177FC72b8bB3387761b30bc1619994A5` | [Verified source code](https://sepolia.etherscan.io/address/0x9603c3E0177FC72b8bB3387761b30bc1619994A5#code) |
| TBillToken | `0x99469750CCF235fc004021229274AbE005b75612` | [Verified source code](https://sepolia.etherscan.io/address/0x99469750CCF235fc004021229274AbE005b75612#code) |
| MockTBillCustodian | `0xAebC532482aC32F70568b173f4F1339A7fB65A54` | [Verified source code](https://sepolia.etherscan.io/address/0xAebC532482aC32F70568b173f4F1339A7fB65A54#code) |
| TBillVault | `0xdA9EA7738eF4134ac911b9dBa23012aD69f1d177` | [Verified source code](https://sepolia.etherscan.io/address/0xdA9EA7738eF4134ac911b9dBa23012aD69f1d177#code) |
| RedemptionQueue | `0x66A5f06Ca5709efE50c72206Bbdc4b7AE17A6406` | [Verified source code](https://sepolia.etherscan.io/address/0x66A5f06Ca5709efE50c72206Bbdc4b7AE17A6406#code) |

The results above document the student's completed deployment. This editing task
has not broadcast transactions, redeployed contracts or repeated the on-chain
checker. The original screenshots have now been inspected directly: six display
Similar Match, while RedemptionQueue displays Exact Match. The evidence index
records these visible per-contract classifications. Individual transaction
hashes were not supplied and are not invented.

The [evidence index](evidence/README.md) records the current screenshot inventory
and the local documentation checks. Anvil addresses in `local-walkthrough.md`
refer to the earlier local demonstration and are separate from this deployment.

## Historical preparation and reproducibility

The sections below retain the workflow prepared before the student completed
Sepolia deployment. They explain how the deployment was configured and how it
can be reviewed. They are not a request to repeat deployment or verification;
the completed addresses above remain the authoritative record for this
submission. No credentials or signer material are included in this document.

`script/Deploy.s.sol` reads only the public `DEPLOYER` address and uses
`vm.startBroadcast(address)`. Foundry receives the signer separately through an
existing encrypted `--account` or a hardware wallet. Never place wallet private
keys, mnemonics, keystores, or keystore passwords in this repository, its `.env`,
reports, logs, or submission archive. The agent has not used a wallet private key.

### Historical pre-broadcast preparation

The original preparation required a student-controlled testnet signer, Sepolia
ETH for gas, a reachable RPC endpoint and an Etherscan credential. The earlier
cloud session had no configured signer or remote-service credentials and
therefore prepared instructions only. The student subsequently completed the
deployment and verification recorded above. Any future read-only validation
should use privately configured service credentials; the public `DEPLOYER`
address does not require disclosure of a private key.

Run from the repository root with Foundry and Solidity 0.8.24 available. In this
cloud environment, the toolchain is selected by:

```bash
source /workspace/cloud-setup/env.sh
```

Set `DEPLOYER` and `SEPOLIA_RPC_URL` privately in your shell. Do not echo the RPC
URL, enable shell tracing (`set -x`), or paste credentials into evidence.

```bash
: "${DEPLOYER:?Set your public testnet deployer address}"
: "${SEPOLIA_RPC_URL:?Configure a private Sepolia RPC endpoint}"
test "$(cast chain-id --rpc-url "$SEPOLIA_RPC_URL")" = 11155111
cast balance "$DEPLOYER" --ether --rpc-url "$SEPOLIA_RPC_URL"

# Simulation: builds and runs the script, without broadcasting or selecting a signer.
forge script script/Deploy.s.sol:Deploy \
  --rpc-url "$SEPOLIA_RPC_URL" --chain 11155111 --sender "$DEPLOYER" -vv
```

Review the simulation, seven creation transactions, six wiring transactions,
estimated gas, and correct chain. Simulated addresses are predictions until real
transaction receipts confirm creation. A later account nonce may change them.
The public-address script can also be reviewed locally without an RPC:
`DEPLOYER=<your-public-address> forge script script/Deploy.s.sol:Deploy -vv`.

### Historical broadcast procedure

The following command is retained from the pre-deployment guide. It submits real
Sepolia transactions and spends test ETH; it must not be rerun to document the
existing deployment. The student has already completed the seven creations and
six setup transactions. This documentation task did not execute the command.
The account name is a historical example of an encrypted signer configured
outside the repository, and is not a stored keystore or password.

```bash
# User-approved broadcast with an existing encrypted keystore (interactive password).
forge script script/Deploy.s.sol:Deploy \
  --rpc-url "$SEPOLIA_RPC_URL" --chain 11155111 --sender "$DEPLOYER" \
  --account rwa-sepolia --broadcast --slow -vv
```

For a hardware wallet, replace `--account rwa-sepolia` with `--ledger` (and the
appropriate public derivation selection for the user's device). Review and
confirm every transaction on the device. Do not use `--unlocked` on a public RPC.

Keep the genuine broadcast record locally at
`broadcast/Deploy.s.sol/11155111/run-latest.json`; `broadcast/` and `cache/` stay
excluded from Git and the submission archive. The script creates contracts in
this order, then runs the wiring calls:

| Order | Public variable | Contract source | Constructor values |
|---|---|---|---|
| 1 | `USDC` | `src/MockUSDC.sol:MockUSDC` | none |
| 2 | `COMPLIANCE` | `src/ComplianceRegistry.sol:ComplianceRegistry` | `DEPLOYER` |
| 3 | `FEED` | `src/exercises/MockPriceFeed.sol:MockPriceFeed` | `100000000` (NAV 1.00) |
| 4 | `TBILL` | `src/TBillToken.sol:TBillToken` | `DEPLOYER, COMPLIANCE` |
| 5 | `CUSTODIAN` | `src/exercises/MockTBillCustodian.sol:MockTBillCustodian` | `DEPLOYER` |
| 6 | `VAULT` | `src/TBillVault.sol:TBillVault` | `USDC, TBILL, FEED, CUSTODIAN, DEPLOYER` |
| 7 | `QUEUE` | `src/exercises/RedemptionQueue.sol:RedemptionQueue` | `VAULT, TBILL, USDC, DEPLOYER` |

For the completed deployment, populate the public address variables from the
address table above. The student confirmed success of all 13 transactions,
including the six setup calls. The historical recovery guidance remains to
inspect an actual failed or interrupted broadcast before considering
`--resume`; it does not apply as a request to repeat this successful deployment.

## Postdeployment configuration checks

The student confirmed that the command below passed all 29 configuration
checks for the deployed Sepolia contracts. This documentation update does not
claim a second execution or an independently observed exit code for that run.
The checker is read-only and needs no signer. It rejects the wrong chain, missing
code, zero addresses, missing roles, missing whitelist entries, and broken
contract pointers. It does not claim that custody or NAV is verified off-chain.

```bash
: "${USDC:?}" "${COMPLIANCE:?}" "${FEED:?}" "${TBILL:?}"
: "${CUSTODIAN:?}" "${VAULT:?}" "${QUEUE:?}"
python3 scripts/check-deployment.py --chain-id 11155111
```

It checks the USDC, tBILL and NAV decimals (6, 18, 8); all vault and queue
dependencies; compliance's deployer and queue whitelist entries; and:

| Contract | Required role assignment |
|---|---|
| Compliance | deployer: default admin and `COMPLIANCE_ROLE` |
| Token | deployer: default admin, `MINTER_ROLE`, `PAUSER_ROLE`; vault and queue: `MINTER_ROLE` |
| Custodian | deployer: default admin and `CUSTODIAN_ROLE`; vault: `CUSTODIAN_ROLE` |
| Vault | deployer: default admin, `REPORTER_ROLE`, `OPERATOR_ROLE` |
| Queue | deployer: default admin and `SETTLER_ROLE` |

`MockUSDC` and `MockPriceFeed` intentionally have no access-control roles. The
mock faucet and `MockPriceFeed.setPrice` are publicly callable. Role gating on
`vault.attest` does **not** protect the feed from direct external writes. These
are lab mocks, not a secured production oracle or evidence of Treasury ownership.

## Historical source-verification commands

The commands below preserve the original verification procedure for
reproducibility. The student subsequently confirmed source-code verification
records for all seven Sepolia contracts. This documentation update does not
claim to have executed these commands or observed their individual exit codes.
The common compiler and optimizer settings match this repository
(Solidity 0.8.24, 200 runs).
`ETHERSCAN_API_KEY` is read by Foundry from the environment and is not printed.

```bash
: "${ETHERSCAN_API_KEY:?Configure privately; never print the value}"
verify_args=(--chain sepolia --watch --compiler-version 0.8.24+commit.e11b9ed9 --num-of-optimizations 200)

forge verify-contract "$USDC" src/MockUSDC.sol:MockUSDC "${verify_args[@]}"

forge verify-contract "$COMPLIANCE" src/ComplianceRegistry.sol:ComplianceRegistry \
  "${verify_args[@]}" --constructor-args "$(cast abi-encode 'constructor(address)' "$DEPLOYER")"

forge verify-contract "$FEED" src/exercises/MockPriceFeed.sol:MockPriceFeed \
  "${verify_args[@]}" --constructor-args "$(cast abi-encode 'constructor(int256)' 100000000)"

forge verify-contract "$TBILL" src/TBillToken.sol:TBillToken \
  "${verify_args[@]}" --constructor-args "$(cast abi-encode 'constructor(address,address)' "$DEPLOYER" "$COMPLIANCE")"

forge verify-contract "$CUSTODIAN" src/exercises/MockTBillCustodian.sol:MockTBillCustodian \
  "${verify_args[@]}" --constructor-args "$(cast abi-encode 'constructor(address)' "$DEPLOYER")"

forge verify-contract "$VAULT" src/TBillVault.sol:TBillVault \
  "${verify_args[@]}" --constructor-args "$(cast abi-encode 'constructor(address,address,address,address,address)' "$USDC" "$TBILL" "$FEED" "$CUSTODIAN" "$DEPLOYER")"

forge verify-contract "$QUEUE" src/exercises/RedemptionQueue.sol:RedemptionQueue \
  "${verify_args[@]}" --constructor-args "$(cast abi-encode 'constructor(address,address,address,address)' "$VAULT" "$TBILL" "$USDC" "$DEPLOYER")"
```

## Evidence completion

The README now records all seven actual addresses and their Etherscan Code
links. All seven authentic verification screenshots are present in
`docs/evidence/`, following commit `bdc8dc1`. Their original filenames are linked
in [evidence/README.md](evidence/README.md); every PNG link resolves to an existing
file and each screenshot's displayed address matches the deployment record.
The original images have not been modified.

The original screenshots show **Similar Match** for MockUSDC,
ComplianceRegistry, MockPriceFeed, TBillToken, MockTBillCustodian and TBillVault,
and **Exact Match** for RedemptionQueue. These labels are visible in the images;
no match category or transaction hash is inferred.
The existing automated audit validates table structure and local test evidence,
not screenshot existence or the explorer's source-verification classification.
