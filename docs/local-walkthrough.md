# Ex1: completed locally with unlocked Anvil accounts

This warm-up ran against a fresh **local Anvil, chain ID 31337**. It did not
contact Sepolia, use a wallet private key, or produce explorer verification.
The complete authentic command output, selected transaction receipt fields,
and individual exit codes are in [evidence/ex1-local.log](evidence/ex1-local.log).

## Reproduce

From the repository root, with Foundry available:

```bash
source /workspace/cloud-setup/env.sh   # this cloud environment's installed toolchain
python3 scripts/local-walkthrough.py --port 18546
```

The helper starts `anvil --silent` bound to `127.0.0.1`, obtains only the public
address using `cast rpc eth_accounts`, deploys the seven contracts, and uses
`--from <public-address> --unlocked` for local transactions. It refuses to reuse
an existing RPC node on the selected port, verifies chain ID 31337, and stops
its child Anvil on exit. Anvil's default key/mnemonic banner is suppressed; no
wallet credential environment variables are copied into the subprocesses.
Changing `--port` is safe if 18546 is already in use.

The default execution sandbox initially rejected the local listening socket:
`anvil --silent --host 127.0.0.1 --port 18545 --chain-id 31337` returned
`Error: Operation not permitted (os error 1)`, exit **1**. The successful run used
the cloud execution tool's scoped network permission for the localhost listener.
No external deployment permission or wallet access was needed.

## Actual successful outputs

`python3 scripts/local-walkthrough.py --port 18546` exited **0**. Every command
it executed exited **0**, including the real local broadcast. The deployment
printed `ONCHAIN EXECUTION COMPLETE & SUCCESSFUL.` The read-only checker printed:

```text
PASS chain ID 31337
PASS all seven contracts: code and 29 decimal/wiring/permission checks
EXIT_CODE=0
```

The seven addresses below are **local only**, derived from the actual fresh
Anvil deployment. They have no claimed existence or verification on Sepolia.

| Local contract | Actual address, chain 31337 |
|---|---|
| MockUSDC | `0x5FbDB2315678afecb367f032d93F642f64180aa3` |
| ComplianceRegistry | `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512` |
| MockPriceFeed | `0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0` |
| TBillToken | `0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9` |
| MockTBillCustodian | `0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9` |
| TBillVault | `0x5FC8d32690cc91D4c39d9d3abcBD16989F875707` |
| RedemptionQueue | `0x0165878A594ca255338adfa4d48449f69242Eb8F` |

The helper funded the whitelisted deployer with 1000 mock USDC, approved the
vault, and subscribed at NAV 1.00. It observed `1000000000000000000000` share
units (1000 tBILL) and custodian holdings `0`. After `attest(125000000)`, the
share balance stayed 1000 tBILL while `totalClaimValue()` became `1250000000`
USDC units (1250 USDC). A number re-priced the claim; no T-Bills or cash arrived.

It then approved and enqueued `1000000000000000000` share units (1 tBILL),
observing `pendingShares = 1000000000000000000` and `pendingAssets = 1250000`.
After another NAV update to 1.50, the queued payout remained `1250000`: the
request locked its payout at NAV 1.25. `settle(1250000)` burned the escrowed
share and made 1.25 USDC claimable. `claim()` paid that cash to the user.

Final actual reads (all exit **0**):

| Read | Actual smallest-unit value | Meaning |
|---|---|---|
| User USDC | `1250000` | 1.25 USDC paid |
| User tBILL | `999000000000000000000` | 999 shares remain |
| Queue tBILL | `0` | escrow was burned |
| Queue `pendingShares` | `0` | no pending share tickets |
| Queue `pendingAssets` | `0` | no pending cash obligations |
| Queue `totalClaimable` | `0` | payment was claimed |
| Vault reserve balance | `998750000` | 998.75 USDC remains |

The test is synchronous because Anvil mines transactions immediately; the queue
models asynchronous request/settle/claim stages and does not enforce a literal
one-day time lock. No real T+1 settlement or custody has been demonstrated.

## Deployment regression

The added `test/deployment/DeploymentWiring.t.sol` executes the actual deployment
script, checks pointers and roles, then subscribes, invests, enqueues, settles
and claims. This is a separate regression test; lecturer acceptance tests were
not altered for deployment work.

Actual targeted command:

```text
$ forge test --match-path 'test/deployment/*.t.sol' -vv
[PASS] test_Deployment_WiresRolesAndCompletesRedemption()
1 tests passed, 0 failed, 0 skipped (1 total tests)
exit code: 0
```

For deployment preparation and the outstanding user-approved Sepolia work, see
[deployment-sepolia.md](deployment-sepolia.md).
