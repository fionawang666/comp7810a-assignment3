#!/usr/bin/env python3
"""Ex1 on a fresh local Anvil, with unlocked accounts and no private-key access."""

import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, default=18545)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    rpc = f"http://127.0.0.1:{args.port}"
    # Pass only tool/runtime settings; do not inspect or copy wallet credential variables.
    runtime_names = ("PATH", "FOUNDRY_SOLC", "XDG_CACHE_HOME", "HOME", "TMPDIR", "NO_PROXY", "no_proxy")
    env = {name: os.environ[name] for name in runtime_names if name in os.environ}
    env["RPC_URL"] = rpc

    def run(*command, receipt=False):
        print("$ " + " ".join(command), flush=True)
        result = subprocess.run(command, cwd=root, env=env, text=True, capture_output=True)
        if receipt and result.returncode == 0:
            tx = json.loads(result.stdout)
            print(json.dumps({key: tx[key] for key in ("transactionHash", "status", "blockNumber")}))
            if int(tx["status"], 16) != 1:
                sys.exit("Transaction reverted.")
        else:
            print(result.stdout, end="", flush=True)
        print(result.stderr, end="", flush=True)
        print(f"EXIT_CODE={result.returncode}", flush=True)
        if result.returncode:
            sys.exit(result.returncode)
        return result.stdout.strip()

    probe = subprocess.run(
        ["cast", "chain-id", "--rpc-url", rpc], capture_output=True, text=True, timeout=5
    )
    if probe.returncode == 0:
        sys.exit(f"Port {args.port} already has an RPC node; choose another --port for a fresh chain.")
    # --silent suppresses Anvil's default mnemonic/private-key banner. No key is read or copied.
    node = subprocess.Popen(
        ["anvil", "--silent", "--host", "127.0.0.1", "--port", str(args.port), "--chain-id", "31337",
         "--accounts", "1"],
        env=env,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    try:
        for _ in range(50):
            ready = subprocess.run(
                ["cast", "chain-id", "--rpc-url", rpc], capture_output=True, text=True, timeout=5
            )
            if ready.returncode == 0:
                break
            if node.poll() is not None:
                sys.exit("Anvil failed to start.")
            time.sleep(0.1)
        else:
            sys.exit("Anvil did not become ready.")
        assert ready.stdout.strip() == "31337", "Unexpected local chain ID"
        print("LOCAL ANVIL ONLY: chain ID 31337; receipt output shows selected real fields.")
        env["DEPLOYER"] = json.loads(run("cast", "rpc", "eth_accounts", "--rpc-url", rpc))[0]
        print("DEPLOYER=" + env["DEPLOYER"])
        deployment = run(
            "forge", "script", "script/Deploy.s.sol:Deploy", "--rpc-url", rpc,
            "--sender", env["DEPLOYER"], "--unlocked", "--broadcast", "--color", "never",
        )
        for name, label in (
            ("USDC", "MockUSDC"), ("COMPLIANCE", "Compliance"), ("FEED", "NAV feed"),
            ("TBILL", "TBillToken"), ("CUSTODIAN", "Custodian"),
            ("VAULT", "TBillVault"), ("QUEUE", "Queue"),
        ):
            match = re.search(re.escape(label) + r"\s*:\s*(0x[0-9A-Fa-f]{40})", deployment)
            if not match:
                sys.exit(f"Cannot find {name} in the actual deployment output.")
            env[name] = match.group(1)
        run("python3", "scripts/check-deployment.py", "--chain-id", "31337")

        def send(contract, signature, *arguments):
            return run("cast", "send", env[contract], signature, *arguments,
                       "--from", env["DEPLOYER"], "--unlocked", "--rpc-url", rpc, "--json", receipt=True)

        def read(contract, signature, expected, *arguments):
            actual = run("cast", "call", env[contract], signature, *arguments, "--rpc-url", rpc)
            if actual.split()[0].lower() != str(expected).lower():
                sys.exit(f"Unexpected {contract}.{signature}: {actual}; expected {expected}")

        send("USDC", "faucet(address,uint256)", env["DEPLOYER"], "1000000000")
        send("USDC", "approve(address,uint256)", env["VAULT"], "1000000000")
        send("VAULT", "subscribe(uint256)", "1000000000")
        read("TBILL", "balanceOf(address)(uint256)", 1000 * 10**18, env["DEPLOYER"])
        read("CUSTODIAN", "realHoldings()(uint256)", 0)
        send("VAULT", "attest(int256)", "125000000")
        read("VAULT", "navPerShare()(uint256)", 125000000)
        read("TBILL", "balanceOf(address)(uint256)", 1000 * 10**18, env["DEPLOYER"])
        read("VAULT", "totalClaimValue()(uint256)", 1250 * 10**6)
        send("TBILL", "approve(address,uint256)", env["QUEUE"], "1000000000000000000")
        send("QUEUE", "enqueue(uint256)", "1000000000000000000")
        read("QUEUE", "pendingShares()(uint256)", 10**18)
        read("QUEUE", "pendingAssets()(uint256)", 1250000)
        # A later NAV does not reprice a ticket: its 1.25 USDC payout is already locked.
        send("VAULT", "attest(int256)", "150000000")
        read("QUEUE", "pendingAssets()(uint256)", 1250000)
        send("QUEUE", "settle(uint256)", "1250000")
        read("QUEUE", "claimable(address)(uint256)", 1250000, env["DEPLOYER"])
        read("TBILL", "balanceOf(address)(uint256)", 0, env["QUEUE"])
        send("QUEUE", "claim()")
        read("USDC", "balanceOf(address)(uint256)", 1250000, env["DEPLOYER"])
        read("TBILL", "balanceOf(address)(uint256)", 999 * 10**18, env["DEPLOYER"])
        read("QUEUE", "pendingShares()(uint256)", 0)
        read("QUEUE", "pendingAssets()(uint256)", 0)
        read("QUEUE", "totalClaimable()(uint256)", 0)
        read("VAULT", "reserveBalance()(uint256)", 998750000)
        print("PASS Ex1: funded, subscribed, moved NAV, enqueued, settled, and claimed on local Anvil.")
    finally:
        node.terminate()
        node.wait(timeout=10)


if __name__ == "__main__":
    main()
