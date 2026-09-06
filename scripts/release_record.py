#!/usr/bin/env python3
"""Artifact identity records for local release handoffs. Never execute record contents."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import tempfile


def fingerprint(path):
    path = Path(path)
    if path.is_symlink() or not path.exists():
        raise ValueError('Missing artifact or unsafe artifact symlink')
    if path.is_file():
        with path.open('rb') as stream:
            return hashlib.file_digest(stream, 'sha256').hexdigest()
    rows = []
    for entry in sorted(path.rglob('*')):
        relative = str(entry.relative_to(path))
        if entry.is_symlink():
            if not entry.exists() or not entry.resolve().is_relative_to(path.resolve()):
                raise ValueError('Escaping or broken artifact link')
            rows.append([relative, 'link', str(entry.readlink())])
        elif entry.is_file():
            rows.append([relative, 'file', entry.stat().st_mode & 0o777, fingerprint(entry)])
    return hashlib.sha256(json.dumps(rows, separators=(',', ':')).encode()).hexdigest()


def write_record(destination, artifact, evidence=None):
    destination = Path(destination)
    value = dict(schemaVersion=1, artifact=str(Path(artifact).resolve()), sha256=fingerprint(artifact), evidence=evidence or {})
    destination.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(mode='w', dir=destination.parent, delete=False) as stream:
        json.dump(value, stream, indent=2)
        stream.write('\n'); stream.flush(); os.fsync(stream.fileno())
        temporary = Path(stream.name)
    temporary.replace(destination)
    return value


def verify_record(record, artifact):
    value = json.loads(Path(record).read_text())
    if value['schemaVersion'] != 1 or value['artifact'] != str(Path(artifact).resolve()) or value['sha256'] != fingerprint(artifact):
        raise ValueError('Release artifact changed or does not match its handoff')
    return value


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('operation', choices=['record', 'verify'])
    parser.add_argument('record'); parser.add_argument('artifact')
    args = parser.parse_args()
    if args.operation == 'record': write_record(args.record, args.artifact)
    else: verify_record(args.record, args.artifact)
