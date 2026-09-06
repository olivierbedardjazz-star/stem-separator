#!/usr/bin/env python3
import hashlib,json,sys,tarfile,urllib.request
from pathlib import Path
root=Path(__file__).resolve().parents[1]
cache=root/'build/CorrespondingSources';cache.mkdir(parents=True,exist_ok=True)
records=json.loads((root/'Packaging/corresponding-sources.lock.json').read_text())['artifacts']
for r in records:
    p=cache/r['filename']
    if not p.exists():urllib.request.urlretrieve(r['url'],p)
    with p.open('rb') as stream:
        if hashlib.file_digest(stream,'sha256').hexdigest()!=r['sha256']:raise SystemExit('Source archive hash mismatch')
output=Path(sys.argv[1])
if output.exists():raise SystemExit('Refusing to overwrite source archive')
with tarfile.open(output,'w:gz') as archive:
    for r in records:archive.add(cache/r['filename'],arcname=r['filename'])
    archive.add(root/'Packaging/corresponding-sources.lock.json',arcname='sources-lock.json')
    archive.add(root/'docs/LEGAL/RUNTIME_SOURCE_AND_RELINKING.md',arcname='README.md')
