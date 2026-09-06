#!/bin/zsh
set -euo pipefail
STEM_ROOT=${0:A:h:h}
source "$STEM_ROOT/scripts/release_configuration.sh"
STEM_APP="${APP_PATH:-$STEM_ROOT/build/export/$APP_NAME}"
STEM_HELPER="$STEM_APP/Contents/Helpers/StemWorker.app"
[[ -d "$STEM_HELPER" ]] || { print -u2 'Bundled StemWorker.app is missing'; exit 1; }
security find-identity -v -p codesigning | /usr/bin/grep -F "$CODE_SIGN_IDENTITY" >/dev/null || { print -u2 'Developer ID identity unavailable'; exit 1; }
"$STEM_BUILD_PYTHON" - "$STEM_HELPER" "$CODE_SIGN_IDENTITY" <<'PY'
from pathlib import Path
import subprocess,sys
root=Path(sys.argv[1]).resolve(); identity=sys.argv[2]
magic={b'\xcf\xfa\xed\xfe',b'\xfe\xed\xfa\xcf',b'\xce\xfa\xed\xfe',b'\xfe\xed\xfa\xce',b'\xca\xfe\xba\xbe',b'\xbe\xba\xfe\xca',b'\xca\xfe\xba\xbf',b'\xbf\xba\xfe\xca'}
for p in root.rglob('*'):
    if p.is_symlink():
        if not p.resolve().is_relative_to(root) or not p.exists(): raise SystemExit('Invalid helper symlink: '+str(p.relative_to(root)))
        continue
    if not p.is_file(): continue
    with p.open('rb') as f: head=f.read(4)
    if head not in magic: continue
    header=subprocess.check_output(['otool','-hv',str(p)],text=True)
    args=['codesign','--force','--timestamp','--sign',identity]
    if 'EXECUTE' in header: args += ['--options','runtime']
    subprocess.run(args+[str(p)],check=True)
# Seal nested containers only after every contained leaf has its final signature.
bundles=[p for p in root.rglob('*') if p.is_dir() and not p.is_symlink() and p.suffix in ('.framework','.app','.xpc')]
for p in sorted(bundles,key=lambda p:len(p.parts),reverse=True):
    subprocess.run(['codesign','--force','--timestamp','--options','runtime','--sign',identity,str(p)],check=True)
subprocess.run(['codesign','--force','--timestamp','--options','runtime','--sign',identity,str(root)],check=True)
PY
"$STEM_ROOT/scripts/verify_stem_runtime_signatures.sh" "$STEM_APP"
