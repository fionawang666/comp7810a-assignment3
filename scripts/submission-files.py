#!/usr/bin/env python3
"""Shared conservative selection of project files for audit and offline ZIPs."""
from pathlib import Path
import re

EXCLUDED_DIRS = {
    '.git', '.hg', '.svn', 'cache', 'out', 'broadcast', 'node_modules',
    '.venv', 'venv', '__pycache__', '.pytest_cache', '.mypy_cache',
    '.ruff_cache', '.cache', 'work', 'keystore', 'keystores', 'wallet',
    'wallets', '.ssh', '.aws', '.foundry',
}
EXCLUDED_NAMES = {
    '.git', '.ds_store', 'demo-state.json', 'start-here-中文.md', 'codex-task.md',
    'wallet.dat', 'id_rsa', 'id_ed25519', 'id_ecdsa', 'credentials',
    '.git-credentials', '.netrc', '.npmrc', '.pypirc',
}
EXCLUDED_SUFFIXES = {
    '.key', '.pem', '.p12', '.pfx', '.jks', '.keystore', '.wallet',
    '.zip', '.tar', '.gz', '.tgz', '.bz2', '.xz', '.7z', '.rar', '.zst', '.lz4',
}


def excluded(relative):
    name = relative.name.lower()
    return (
        any(part.lower() in EXCLUDED_DIRS for part in relative.parts[:-1])
        or name in EXCLUDED_NAMES
        or name.startswith('.env') or '.env.' in name or name.endswith('.env')
        or relative.suffix.lower() in EXCLUDED_SUFFIXES
        or name.endswith('.zip.tmp')
        or name.startswith('utc--')
        or 'private-key' in name or 'private_key' in name
        or bool(re.fullmatch(r'(?:wallets?|keystores?)(?:[._-].*)?', name))
        or bool(re.fullmatch(r'(?:wallets?|keystores?|keys?)(?:[._-].*)?\.json', name))
    )


def submission_files(root):
    """Include complete libraries, omitting generated files and credential paths.

    Path.rglob does not follow directory symlinks. Reject file symlinks too;
    they may point to an excluded credential or a file outside the project.
    Excluded files are never opened by this function or the audit scanner.
    """
    root = Path(root)
    for file in sorted(root.rglob('*')):
        if not file.is_symlink() and not excluded(file.relative_to(root)) and file.is_file():
            yield file
