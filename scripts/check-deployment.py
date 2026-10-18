#!/usr/bin/env python3
"""Read-only checks for the seven lab contracts; never signs a transaction."""

import argparse
import os
import re
import subprocess
import sys


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--chain-id", type=int, required=True)
    args = parser.parse_args()
    names = ("DEPLOYER", "USDC", "COMPLIANCE", "FEED", "TBILL", "CUSTODIAN", "VAULT", "QUEUE")
    addresses = {name: os.environ.get(name, "") for name in names}
    for name, value in addresses.items():
        if not re.fullmatch(r"0x[0-9a-fA-F]{40}", value) or int(value, 16) == 0:
            sys.exit(f"Set {name} to a real, nonzero public address.")
    rpc = os.environ.get("RPC_URL") or os.environ.get("SEPOLIA_RPC_URL")
    if not rpc:
        sys.exit("Set RPC_URL (local) or SEPOLIA_RPC_URL (Sepolia); its value will not be printed.")

    def cast(*arguments):
        # Do not print the command or stderr: RPC endpoints can contain API credentials.
        result = subprocess.run(
            ["cast", *arguments, "--rpc-url", rpc], capture_output=True, text=True, check=False
        )
        if result.returncode:
            sys.exit(f"cast {arguments[0]} failed (exit {result.returncode}); RPC details omitted.")
        return result.stdout.strip()

    chain_id = int(cast("chain-id"))
    if chain_id != args.chain_id:
        sys.exit(f"Wrong chain: expected {args.chain_id}, received {chain_id}.")
    print(f"PASS chain ID {chain_id}")
    for name in names[1:]:
        if cast("code", addresses[name]) == "0x":
            sys.exit(f"No deployed code at {name}.")
        print(f"PASS {name} deployed code")

    checks = 0

    def expect(name, signature, expected, *values):
        nonlocal checks
        actual = cast("call", addresses[name], signature, *values).split()[0]
        if actual.lower() != str(expected).lower():
            sys.exit(f"FAIL {name}.{signature}: expected {expected}, received {actual}")
        checks += 1
        print(f"PASS {name}.{signature.split('(')[0]}")

    for name, signature, target in (
        ("TBILL", "compliance()(address)", "COMPLIANCE"),
        ("VAULT", "usdc()(address)", "USDC"),
        ("VAULT", "tBill()(address)", "TBILL"),
        ("VAULT", "navFeed()(address)", "FEED"),
        ("VAULT", "custodian()(address)", "CUSTODIAN"),
        ("VAULT", "queue()(address)", "QUEUE"),
        ("QUEUE", "vault()(address)", "VAULT"),
        ("QUEUE", "tBill()(address)", "TBILL"),
        ("QUEUE", "usdc()(address)", "USDC"),
    ):
        expect(name, signature, addresses[target])
    expect("USDC", "decimals()(uint8)", "6")
    expect("TBILL", "decimals()(uint8)", "18")
    expect("FEED", "decimals()(uint8)", "8")
    expect("COMPLIANCE", "isWhitelisted(address)(bool)", "true", addresses["DEPLOYER"])
    expect("COMPLIANCE", "isWhitelisted(address)(bool)", "true", addresses["QUEUE"])
    zero_role = "0x" + "00" * 32
    for name in ("COMPLIANCE", "TBILL", "CUSTODIAN", "VAULT", "QUEUE"):
        expect(name, "hasRole(bytes32,address)(bool)", "true", zero_role, addresses["DEPLOYER"])
    for name, role, recipient in (
        ("COMPLIANCE", "COMPLIANCE_ROLE", "DEPLOYER"),
        ("TBILL", "MINTER_ROLE", "DEPLOYER"),
        ("TBILL", "PAUSER_ROLE", "DEPLOYER"),
        ("TBILL", "MINTER_ROLE", "VAULT"),
        ("TBILL", "MINTER_ROLE", "QUEUE"),
        ("CUSTODIAN", "CUSTODIAN_ROLE", "DEPLOYER"),
        ("CUSTODIAN", "CUSTODIAN_ROLE", "VAULT"),
        ("VAULT", "REPORTER_ROLE", "DEPLOYER"),
        ("VAULT", "OPERATOR_ROLE", "DEPLOYER"),
        ("QUEUE", "SETTLER_ROLE", "DEPLOYER"),
    ):
        role_id = cast("call", addresses[name], f"{role}()(bytes32)")
        expect(name, "hasRole(bytes32,address)(bool)", "true", role_id, addresses[recipient])
    print(f"PASS all seven contracts: code and {checks} decimal/wiring/permission checks")


if __name__ == "__main__":
    main()
