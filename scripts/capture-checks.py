#!/usr/bin/env python3
"""Capture real checks and bind their results to the checked source snapshot."""
from pathlib import Path
import datetime
import hashlib
import json
import shlex
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [
    ['make', 'doctor'],
    ['make', 'test'],
    ['make', 'exercise'],
    ['make', 'challenge'],
    ['forge', 'test', '--match-path', 'test/tier3/*.t.sol', '-vv'],
    ['forge', 'test'],
    ['forge', 'fmt', '--check'],
]
LOG = ROOT / 'docs/submission-checks.txt'
RECORD = ROOT / 'docs/submission-checks.json'


def source_digest():
    """Include the contracts, tests, libraries, config and check scripts; exclude logs."""
    paths = []
    for directory in ('src', 'test', 'script', 'lib', 'scripts'):
        paths += [p for p in (ROOT / directory).rglob('*')
                  if p.is_file() and not p.is_symlink() and '__pycache__' not in p.parts]
    paths += [ROOT / name for name in ('foundry.toml', 'foundry.lock', 'remappings.txt', 'Makefile')]
    digest = hashlib.sha256()
    for path in sorted(paths):
        digest.update(path.relative_to(ROOT).as_posix().encode() + b'\0')
        digest.update(hashlib.sha256(path.read_bytes()).digest())
    return digest.hexdigest()


def check_evidence():
    try:
        record = json.loads(RECORD.read_text())
        if not isinstance(record, dict) or record.get('schema_version') != 1:
            raise ValueError('unsupported evidence schema')
        if record.get('source_sha256') != source_digest():
            raise ValueError('source changed since checks; recapture')
        if record.get('log_sha256') != hashlib.sha256(LOG.read_bytes()).hexdigest():
            raise ValueError('log changed')
        results = record.get('commands')
        if not isinstance(results, list) or any(not isinstance(r, dict) for r in results):
            raise ValueError('malformed command records')
        if [r.get('argv') for r in results] != COMMANDS:
            raise ValueError('required command missing')
        if record.get('all_passed') is not True or any(
                type(r.get('exit_code')) is not int or r['exit_code'] != 0 for r in results):
            raise ValueError('checks failed or malformed exit code')
    except (OSError, ValueError, KeyError, TypeError, IndexError) as error:
        print('Evidence unavailable or invalid:', error)
        return 1
    print('Evidence current: all seven required commands exited 0 for this source snapshot.')
    return 0


def main():
    if sys.argv[1:] == ['--check-evidence']:
        return check_evidence()
    if sys.argv[1:]:
        print('Usage: python3 scripts/capture-checks.py [--check-evidence]')
        return 2
    LOG.parent.mkdir(exist_ok=True)
    before = source_digest()
    record = {'schema_version': 1, 'source_sha256': before,
              'captured_at_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
              'commands': []}
    with LOG.open('w', encoding='utf-8') as log:
        header = ('COMP7810A Assignment Three — actual check output\n'
                  + record['captured_at_utc'] + '\n'
                  + 'Source snapshot SHA-256: ' + before + '\n')
        log.write(header)
        print(header, flush=True)
        for binary in ('forge', 'cast', 'anvil'):
            try:
                result = subprocess.run([binary, '--version'], cwd=ROOT, text=True,
                                        stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
                log.write(result.stdout + f'[version exit={result.returncode}]\n')
            except FileNotFoundError:
                log.write(f'{binary}: unavailable\n')
        for argv in COMMANDS:
            command = shlex.join(argv)
            log.write('\n' + '=' * 72 + '\n$ ' + command + '\n')
            log.flush()
            print('$ ' + command, flush=True)
            try:
                result = subprocess.run(argv, cwd=ROOT, text=True, errors='replace',
                                        stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
                output, code = result.stdout, result.returncode
            except FileNotFoundError as error:
                output, code = str(error) + '\n', 127
            log.write(output)
            outcome = f'\n[exit={code}] {command}\n'
            log.write(outcome)
            log.flush()
            print(output[-2200:] + outcome, flush=True)
            record['commands'].append({'argv': argv, 'exit_code': code})
        stable = before == source_digest()
        record['all_passed'] = stable and all(r['exit_code'] == 0 for r in record['commands'])
        if not stable:
            log.write('\nSource changed during capture; evidence must be rerun.\n')
        log.write('\nRESULT: ' + ('ALL CHECKS PASSED' if record['all_passed'] else 'FAILED') + '\n')
    record['log_sha256'] = hashlib.sha256(LOG.read_bytes()).hexdigest()
    RECORD.write_text(json.dumps(record, indent=2) + '\n')
    print('Saved actual output and exit codes:', LOG, flush=True)
    return 0 if record['all_passed'] else 1


if __name__ == '__main__':
    sys.exit(main())
