#!/usr/bin/env python3
"""Audit an explicit proposed public file list; never print suspected secret values."""
import argparse
import json
from pathlib import Path, PurePosixPath
import re

FORBIDDEN_PARTS = {'.git', 'build', 'release-evidence', '.venv-packaging', 'xcuserdata', '__pycache__', 'archive'}
FORBIDDEN_SUFFIXES = {'.p12', '.pfx', '.key', '.pem', '.heic', '.xcresult', '.dmg', '.zip', '.th'}
SECRET_PATTERNS = (
    re.compile(rb'-----BEGIN (?:RSA |EC |OPENSSH |ENCRYPTED )?PRIVATE KEY-----'),
    re.compile(rb'\bgh[pousr]_[A-Za-z0-9_]{20,}\b'),
    re.compile(rb'\bgithub_pat_[A-Za-z0-9_]{20,}\b'),
    re.compile(rb'\bAKIA[A-Z0-9]{16}\b'),
)
LEGACY = ('TemplateApp/Download/', 'TemplateApp/Runtime/', 'TemplateApp/RuntimeDependencies/')

def audit(root, entries):
    root = Path(root).resolve()
    issues = []
    for name in sorted(set(entries)):
        relative = PurePosixPath(name)
        if relative.is_absolute() or '..' in relative.parts or not relative.parts:
            issues.append({'path': '<invalid entry>', 'category': 'unsafe path'})
            continue
        path = root.joinpath(*relative.parts)
        if any(part in FORBIDDEN_PARTS or part.startswith('DerivedData') for part in relative.parts) or path.suffix.lower() in FORBIDDEN_SUFFIXES or name.startswith(LEGACY):
            issues.append({'path': name, 'category': 'non-public material'})
            continue
        if any(parent.is_symlink() for parent in [path, *list(path.parents)[:len(relative.parts)-1]]):
            issues.append({'path': name, 'category': 'symlink requires separate review'})
            continue
        if not path.is_file() or not path.resolve().is_relative_to(root):
            issues.append({'path': name, 'category': 'missing or unsafe file'})
            continue
        if path.stat().st_size > 50 * 1024 * 1024:
            issues.append({'path': name, 'category': 'large artifact requires separate review'})
            continue
        data = path.read_bytes()
        if any(pattern.search(data) for pattern in SECRET_PATTERNS):
            issues.append({'path': name, 'category': 'possible credential'})
    return issues

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', default='.')
    parser.add_argument('--paths-from', required=True, help='UTF-8 newline-separated relative file paths')
    args = parser.parse_args()
    entries = Path(args.paths_from).read_text().splitlines()
    issues = audit(args.root, entries)
    print(json.dumps({'schemaVersion': 1, 'fileCount': len(set(entries)), 'issues': issues}, indent=2))
    return bool(issues)

if __name__ == '__main__':
    raise SystemExit(main())
