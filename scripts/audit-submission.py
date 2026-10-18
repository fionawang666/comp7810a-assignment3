#!/usr/bin/env python3
"""Check readiness; pattern matching cannot guarantee that all secrets are absent."""
from pathlib import Path
import re
import runpy
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
FILES = runpy.run_path(str(ROOT / 'scripts/submission-files.py'))
CONTRACTS = (
    'MockUSDC', 'ComplianceRegistry', 'MockPriceFeed', 'TBillToken',
    'MockTBillCustodian', 'TBillVault', 'RedemptionQueue',
)
REQUIRED = (
    'src/exercises/RedemptionQueue.sol', 'test/exercises/01_BridgeTasks.t.sol',
    'test/exercises/02_QueueTasks.t.sol', 'test/exercises/03_InvariantTasks.t.sol',
    'test/challenges/FalseNav.t.sol', 'STUDENT-QUESTIONS.md',
    'docs/architecture.svg', 'README.md', 'EXERCISES.md', 'script/Deploy.s.sol',
    'docs/submission-checks.txt', 'docs/submission-checks.json',
    'lib/forge-std/src/Test.sol', 'lib/forge-std/src/Script.sol',
    'lib/forge-std/src/Vm.sol',
    'lib/openzeppelin-contracts/contracts/access/AccessControl.sol',
    'lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol',
    'lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol',
)


def deployment_errors(readme):
    """Require each actual table row's distinct address and matching real link.

    This structural check cannot itself prove source verification on Etherscan;
    the student must review authentic explorer verification evidence separately.
    """
    errors = []
    sections = re.split(r'^## Deployment \(Sepolia\)\s*$', readme, flags=re.M)
    if len(sections) != 2:
        return ['README requires exactly one ## Deployment (Sepolia) heading']
    section = re.split(r'^## ', sections[1], maxsplit=1, flags=re.M)[0]
    addresses = []
    for name in CONTRACTS:
        rows = re.findall(r'^\|\s*' + re.escape(name) + r'\s*\|([^\n]*)$', section, re.M)
        if len(rows) != 1:
            errors.append('Need exactly one deployment-table row for ' + name)
            continue
        cells = [cell.strip() for cell in rows[0].split('|')]
        if len(cells) < 2 or re.search(r'NOT\s+(?:DEPLOYED|VERIFIED)|TODO|PLACEHOLDER|PENDING', rows[0], re.I):
            errors.append('Complete the real Sepolia deployment and verification row for ' + name)
            continue
        address = re.findall(r'(?<![0-9a-fA-F])0x[0-9a-fA-F]{40}(?![0-9a-fA-F])', cells[0])
        links = re.findall(r'https://sepolia\.etherscan\.io/address/(0x[0-9a-fA-F]{40})(?![0-9a-fA-F])', cells[1])
        if len(address) != 1 or not links or any(link.lower() != address[0].lower() for link in links):
            errors.append('Need one address and its matching Sepolia Etherscan link for ' + name)
            continue
        if int(address[0], 16) == 0:
            errors.append('Zero address is not a deployment for ' + name)
            continue
        addresses.append(address[0].lower())
    if len(addresses) == len(CONTRACTS) and len(set(addresses)) != len(CONTRACTS):
        errors.append('The seven Sepolia deployments must have seven distinct addresses')
    return errors


def secret_files(root, files):
    """Find credential-context literals, reporting filenames only, never values.

    Bare 32-byte values are often transaction hashes, roles or evidence digests.
    Do not read excluded env files, wallet artifacts or vendored dependencies.
    """
    hex_key = r'(?:0x)?[0-9a-fA-F]{64}(?![0-9a-fA-F])'
    patterns = [
        re.compile(r'(?:--private-key(?:\s+|=)[\"\']?|(?:[\"\']?[A-Za-z_]*(?:private[_-]?key|secret[_-]?key)[A-Za-z_]*[\"\']?)\s*(?::[^=\n]+)?[=:]\s*(?:uint256\(\s*)?[\"\']?)' + hex_key, re.I),
        re.compile(r'-----BEGIN (?:[A-Z ]+ )?PRIVATE KEY-----'),
        re.compile(r'(?:[\"\']?mnemonic[\"\']?\s*[:=]\s*|--mnemonic\s+)[\"\'][a-z]+(?:\s+[a-z]+){11,23}[\"\']', re.I),
        re.compile(r'[\"\']ciphertext[\"\']\s*:\s*[\"\'][0-9a-f]{32,}[\"\']', re.I),
    ]
    suspicious = []
    for file in files:
        rel = file.relative_to(root)
        if rel.parts[0] == 'lib' or file.suffix.lower() not in {'.sol', '.md', '.toml', '.sh', '.py', '.txt', '.json', '.yaml', '.yml', ''}:
            continue
        if file.stat().st_size > 2_000_000:
            suspicious.append(rel.as_posix())
            continue
        content = file.read_text(encoding='utf-8', errors='replace')
        if any(pattern.search(content) for pattern in patterns):
            suspicious.append(rel.as_posix())
    return suspicious


def audit(root=ROOT):
    errors = []
    files = list(FILES['submission_files'](root))
    included = {file.relative_to(root).as_posix() for file in files}
    for item in REQUIRED:
        if item not in included:
            errors.append('Missing required packaged project file: ' + item)
    readme = (root / 'README.md').read_text(encoding='utf-8') if (root / 'README.md').is_file() else ''
    errors.extend(deployment_errors(readme))
    questions = root / 'STUDENT-QUESTIONS.md'
    if questions.is_file():
        content = questions.read_text(encoding='utf-8')
        for key in ('A1', 'A2', 'B1', 'B2', 'C1', 'C2', 'D1', 'D2'):
            question = re.search(r'^\*\*' + key + r'\.\*\*[^\n]*\n([\s\S]*?)(?=\n\*\*[A-D][12]\.\*\*|\n## |\Z)', content, re.M)
            answer = question.group(1).split('> Your answer:', 1)[1] if question and '> Your answer:' in question.group(1) else ''
            answer = re.sub(r'(?m)^---\s*$', '', answer)
            words = len(answer.split())
            print(key, 'word count', words)
            if not 150 <= words <= 300:
                errors.append(key + ': outside 150–300 words')
        section_e = re.search(r'^## E\.[\s\S]*', content, re.M)
        if not section_e:
            errors.append('Missing section E written answer')
        else:
            section = section_e.group(0)
            names = re.findall(r'^\|[^\n]*\|\s*`(test[A-Za-z0-9_]+)`\s*\|\s*$', section, re.M)
            bridge_path = root / 'test/exercises/01_BridgeTasks.t.sol'
            bridge = bridge_path.read_text(encoding='utf-8') if bridge_path.is_file() else ''
            if len(set(names)) != 7 or any(not re.search(r'\bfunction\s+' + re.escape(name) + r'\s*\(', bridge) for name in names):
                errors.append('Section E must map all seven scenarios to implemented test functions')
            if '> Your answer:' not in section or not section.split('> Your answer:', 1)[1].strip():
                errors.append('Missing section E exploit scenario answer')
    suspicious = secret_files(root, files)
    if suspicious:
        errors.append('Inspect possible secret material or oversized text in: ' + ', '.join(suspicious))
    # Validate exact commands/exit codes plus source, library and log freshness.
    checker = root / 'scripts/capture-checks.py'
    if not checker.is_file():
        errors.append('Missing authentic evidence validator')
    else:
        result = subprocess.run([sys.executable, str(checker), '--check-evidence'], cwd=root, check=False)
        if result.returncode:
            errors.append('Fresh successful Foundry evidence required (validator exit ' + str(result.returncode) + ')')
    print('Preflight:', 'PASS' if not errors else 'REQUIRES ATTENTION')
    for error in errors:
        print(' -', error)
    return 0 if not errors else 1


if __name__ == '__main__':
    sys.exit(audit())
