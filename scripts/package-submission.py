#!/usr/bin/env python3
"""Build an offline submission after strict evidence and deployment gates."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import runpy
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def main():
    # No archive is created or replaced if readiness checks fail.
    check = subprocess.run([sys.executable, str(ROOT / 'scripts/audit-submission.py')], cwd=ROOT, check=False)
    if check.returncode:
        print('Packaging blocked: complete the submission audit first.', file=sys.stderr)
        return check.returncode
    selection = runpy.run_path(str(ROOT / 'scripts/submission-files.py'))
    files = list(selection['submission_files'](ROOT))
    expected = {file.relative_to(ROOT).as_posix() for file in files}
    required = runpy.run_path(str(ROOT / 'scripts/audit-submission.py'))['REQUIRED']
    output = ROOT / 'Assignment3-Yijia-Wang-final.zip'
    temporary = output.with_suffix('.zip.tmp')
    try:
        with ZipFile(temporary, 'w', ZIP_DEFLATED, compresslevel=6) as archive:
            for file in files:
                archive.write(file, file.relative_to(ROOT).as_posix())
        with ZipFile(temporary) as archive:
            if archive.testzip():
                raise ValueError('ZIP CRC failed for a project file')
            contents = set(archive.namelist())
            if contents != expected:
                raise ValueError('ZIP inventory differs from the complete selected project inventory')
            if not set(required).issubset(contents):
                raise ValueError('ZIP is missing required submission files')
            if any(selection['excluded'](Path(name)) for name in contents):
                raise ValueError('ZIP contains an excluded credential or generated file')
            # All selected lib files are in expected; a single lib/ entry alone
            # would not establish dependency completeness for offline grading.
            for library in ('lib/forge-std/', 'lib/openzeppelin-contracts/'):
                if not any(name.startswith(library) for name in contents):
                    raise ValueError('ZIP is missing bundled offline dependencies')
        evidence = subprocess.run([sys.executable, str(ROOT / 'scripts/capture-checks.py'), '--check-evidence'], cwd=ROOT, check=False)
        if evidence.returncode:
            raise ValueError('Source or evidence changed during packaging; rerun checks')
        temporary.replace(output)
    except (OSError, ValueError) as error:
        temporary.unlink(missing_ok=True)
        print('Packaging failed:', str(error), file=sys.stderr)
        return 1
    print('Created:', output)
    print('Files:', len(expected))
    print('Size:', output.stat().st_size, 'bytes')
    print('ZIP integrity and complete selected-file inventory: OK')
    print('Review the archive and authentic Etherscan evidence before Moodle submission.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
