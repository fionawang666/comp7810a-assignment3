# Seven-contract Sepolia deployment preparation

Status: **prepared, not broadcast and not explorer verified**. No Sepolia address,
transaction receipt, or verification screenshot has been obtained in this task.
The addresses in the local walkthrough are ephemeral Anvil addresses and must not
be copied into the README's Sepolia table.

`script/Deploy.s.sol` reads only the public `DEPLOYER` address and uses
`vm.startBroadcast(address)`. Foundry receives the signer separately through an
existing encrypted `--account` or a hardware wallet. Never place wallet private
keys, mnemonics, keystores, or keystore passwords in this repository, its `.env`,
reports, logs, or submission archive. The agent has not used a wallet private key.

## Before the user approves a broadcast

The user must select a testnet-only signer they control, arrange Sepolia ETH for
gas, and configure a reachable Sepolia RPC and Etherscan API credential. Use the
existing wallet's public address as `DEPLOYER`; do not provide its private key to
the agent. The current cloud runtime reports no configured secret bindings, RPC
runtime variables, or outbound identities. Therefore these commands are prepared
instructions, not claimed Sepolia results.

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

## Broadcast only after explicit approval

The following commands submit real Sepolia transactions and spend the signer's
test ETH. **They have not been run.** The keystore account name below refers to
an account already configured outside the repository; replace it with the
selected account name. The account's address must equal `DEPLOYER`.

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

Populate those seven public environment variables from the **mined** deployment
record and logs. Check that all 13 transactions succeeded; contract creation
alone does not establish that the six later setup transactions succeeded. If
a transaction failed or the process stopped, inspect the real record before
using Foundry's `--resume`; do not rerun blindly and create a second deployment.

## Postdeployment checks

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

## Exact seven explorer verification commands

These commands have **not been run against Sepolia**. Each must finish with
exit code 0 and an actual explorer verification result. The common compiler and
optimizer settings match this repository (Solidity 0.8.24, 200 runs).
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

After genuine success, update all seven rows under `## Deployment (Sepolia)` in
the README with the actual addresses and `https://sepolia.etherscan.io/address/`
links. Open each address's **Contract → Code** tab, confirm successful source
verification, and take real screenshots with no wallet/credential material.
Record the commands, exit codes and verified URLs in the submission evidence.
Pending rows and screenshots remain a Moodle submission blocker until the user
approves the deployment and completes these steps.
