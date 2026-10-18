#!/usr/bin/env python3
"""Fail-fast local preflight; not a substitute for `forge test`."""
from pathlib import Path
import re
import sys
root=Path(__file__).resolve().parents[1]
necessary=[
 'README.md','Makefile','STUDENT-QUESTIONS.md','EXERCISES.md',
 'src/MockUSDC.sol','src/TBillToken.sol','src/TBillVault.sol',
 'src/ComplianceRegistry.sol','src/exercises/RedemptionQueue.sol',
 'test/TBill.t.sol','test/exercises/01_BridgeTasks.t.sol',
 'test/exercises/02_QueueTasks.t.sol','test/exercises/03_InvariantTasks.t.sol',
 'test/challenges/FalseNav.t.sol','lib/forge-std/src/Test.sol',
 'lib/openzeppelin-contracts/contracts/access/AccessControl.sol',
 'docs/architecture.svg'
]
missing=[p for p in necessary if not (root/p).exists()]
for p in missing: print('MISSING',p)
if missing:sys.exit('Official source and overlay are not both present.')
if (root/'.env').exists(): print('NOTICE: .env exists locally. Never add it to Git or ZIP.')
readme=(root/'README.md').read_text()
questions=(root/'STUDENT-QUESTIONS.md').read_text()
if '![Four-plank RWA bridge' not in readme:sys.exit('README SVG embed missing')
for q in ('A1','A2','B1','B2','C1','C2','D1','D2'):
 pattern=rf'(?m)^\*\*{q}\.\*\*[^\n]*(?:\n(?!> Your answer:)[^\n]*)*\n> Your answer:\s*\n([\s\S]*?)(?=\n\*\*[A-D][12]\.\*\*|\n## |\n---|\Z)'
 m=re.search(pattern,questions)
 if not m:sys.exit(f'Missing discussion answer {q}')
 n=len(m.group(1).strip().split())
 print(q,n,'words')
 if not 150 <= n <= 300:sys.exit(f'{q} outside 150–300 words')
for p in ('src/exercises/RedemptionQueue.sol','test/exercises/01_BridgeTasks.t.sol',
          'test/exercises/03_InvariantTasks.t.sol','test/challenges/FalseNav.t.sol'):
 s=(root/p).read_text()
 if 'revert("TODO' in s or 'TODO: your code goes here' in s:
  sys.exit('Unfinished TODO in '+p)
print('STATIC PREFLIGHT PASSED. Next: run actual Foundry tests.')
