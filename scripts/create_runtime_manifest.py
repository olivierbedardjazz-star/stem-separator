#!/usr/bin/env python3
"""Record the exact embedded helper payload before outer application sealing."""
import hashlib,json,pathlib,sys
helper=pathlib.Path(sys.argv[1]);output=pathlib.Path(sys.argv[2])
files=[]
for path in sorted(helper.rglob('*')):
    relative=str(path.relative_to(helper))
    if path.is_symlink():
        files.append(dict(path=relative,symlink=str(path.readlink())))
    elif path.is_file():
        with path.open('rb') as f: digest=hashlib.file_digest(f,'sha256').hexdigest()
        files.append(dict(path=relative,size=path.stat().st_size,sha256=digest))
output.write_text(json.dumps(dict(schemaVersion=1,helper='Contents/Helpers/StemWorker.app',files=files),indent=2)+'\n')
