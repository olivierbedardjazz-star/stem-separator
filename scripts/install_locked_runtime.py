#!/usr/bin/env python3
"""Fetch hash-pinned artifacts and install without network-enabled build isolation."""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import urllib.request

ROOT = Path(__file__).resolve().parents[1]

def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()

def main():
    destination = ROOT / 'build/StemRuntime/locked-downloads'
    destination.mkdir(parents=True, exist_ok=True)
    records = json.loads((ROOT / 'runtime/artifacts-lock.json').read_text())['artifacts']
    for record in records:
        path = destination / record['filename']
        if not path.exists():
            temporary = path.with_suffix(path.suffix + '.partial')
            urllib.request.urlretrieve(record['url'], temporary)
            if digest(temporary) != record['sha256']:
                temporary.unlink()
                raise RuntimeError('Downloaded artifact hash mismatch: ' + record['filename'])
            temporary.replace(path)
        if digest(path) != record['sha256']:
            raise RuntimeError('Cached artifact hash mismatch: ' + record['filename'])
    environment = dict(os.environ, PIP_NO_INDEX='1', PIP_DISABLE_PIP_VERSION_CHECK='1',
                       PIP_NO_CACHE_DIR='1', PYTHONHASHSEED='0', SOURCE_DATE_EPOCH='1788652800')
    wheels = [str(destination / r['filename']) for r in records if r['filename'].endswith('.whl')]
    subprocess.run([sys.executable, '-m', 'pip', 'install', '--no-deps', *wheels],
                   env=environment, check=True)
    subprocess.run([sys.executable, '-m', 'pip', 'install', '--no-deps', '--no-build-isolation',
                    '--require-hashes', '--find-links', str(destination),
                    '-r', str(ROOT / 'runtime/requirements-lock.txt')], env=environment, check=True)
    subprocess.run([sys.executable, '-m', 'pip', 'check'], env=environment, check=True)

if __name__ == '__main__':
    main()
