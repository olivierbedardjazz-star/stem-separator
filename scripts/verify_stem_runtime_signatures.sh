#!/bin/zsh
set -euo pipefail
STEM_ROOT=${0:A:h:h}
source "$STEM_ROOT/scripts/release_configuration.sh"
STEM_APP="${1:-${APP_PATH:-$STEM_ROOT/build/export/$APP_NAME}}"
"$STEM_BUILD_PYTHON" - "$STEM_APP/Contents/Helpers/StemWorker.app" "$TEAM_ID" <<'PY'
from pathlib import Path
import re,subprocess,sys
root=Path(sys.argv[1]).resolve(); team=sys.argv[2]
if not root.is_dir(): raise SystemExit('Missing bundled helper')
magic={b'\xcf\xfa\xed\xfe',b'\xfe\xed\xfa\xcf',b'\xce\xfa\xed\xfe',b'\xfe\xed\xfa\xce',b'\xca\xfe\xba\xbe',b'\xbe\xba\xfe\xca',b'\xca\xfe\xba\xbf',b'\xbf\xba\xfe\xca'}
count=0
for p in root.rglob('*'):
    if p.is_symlink():
        if not p.exists() or not p.resolve().is_relative_to(root): raise SystemExit('Invalid helper symlink')
        continue
    if not p.is_file(): continue
    with p.open('rb') as f: head=f.read(4)
    if head not in magic: continue
    subprocess.run(['codesign','--verify','--strict',str(p)],check=True,capture_output=True)
    info=subprocess.run(['codesign','-dv','--verbose=4',str(p)],check=True,capture_output=True,text=True).stderr
    if f'TeamIdentifier={team}' not in info or 'Authority=Developer ID Application:' not in info or 'Timestamp=' not in info or 'Signature=adhoc' in info:
        raise SystemExit('Invalid distribution identity/timestamp: '+str(p.relative_to(root)))
    header=subprocess.check_output(['otool','-hv',str(p)],text=True)
    if 'EXECUTE' in header:
        flags=re.search(r'flags=0x([0-9a-fA-F]+)',info)
        if not flags or not int(flags[1],16)&0x10000: raise SystemExit('Missing hardened runtime')
        ent=subprocess.run(['codesign','-d','--entitlements',':-',str(p)],check=True,capture_output=True).stdout
        if ent.strip():
            import plistlib
            values=plistlib.loads(ent)
            if any(values.get(key) for key in ['com.apple.security.get-task-allow','com.apple.security.cs.disable-library-validation','com.apple.security.cs.allow-unsigned-executable-memory','com.apple.security.cs.allow-jit']):
                raise SystemExit('Unreviewed executable entitlement')
    count+=1
if not count: raise SystemExit('No helper Mach-O files found')
subprocess.run(['codesign','--verify','--deep','--strict',str(root)],check=True)
print('Verified Developer ID helper Mach-O files:',count)
PY
