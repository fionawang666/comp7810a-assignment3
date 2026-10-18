#!/usr/bin/env python3
"""Check first-party code for accidental raw private-key signing instructions."""
from pathlib import Path
import re
import sys
root = Path(__file__).resolve().parents[1]
failures = []
for name in ('Makefile', 'EXERCISES.md', 'script/Deploy.s.sol', 'script/BreakIt.s.sol'):
    text = (root / name).read_text()
    if re.search(r'0x[0-9a-fA-F]{64}', text) or 'envUint("PRIVATE_KEY")' in text or '--private-key' in text:
        failures.append(name)
if failures:
    sys.exit('Remove raw private-key use from: ' + ', '.join(failures))
print('Key hygiene passed: public addresses and signer selection only.')
