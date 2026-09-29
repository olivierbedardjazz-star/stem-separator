#!/bin/zsh
# Clean-runner proof for the second build target; the direct proof builds the
# shared pinned Demucs runtime first in the same workflow job.
set -euo pipefail
cd "${0:A:h:h}"
mkdir -p build/CIProof/logs
[[ $(uname -m) == arm64 ]] || { print -u2 'Expected Apple Silicon runner'; exit 1; }
[[ -d build/StemRuntime/dist/StemWorker.app ]] || {
  print -u2 'Build the pinned worker before the Store proof'; exit 1
}

scripts/build_store_libomp.sh > build/CIProof/logs/store-libomp-build.log 2>&1
build/BuildTools/xcodegen/bin/xcodegen generate > build/CIProof/logs/store-project-generation.log 2>&1
git diff --exit-code -- TemplateApp.xcodeproj/project.pbxproj > build/CIProof/logs/store-project-drift.log
xcodebuild build -project TemplateApp.xcodeproj -scheme StemSeparatorAppStore \
  -configuration Release -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath build/CIProof/StoreDerivedData CODE_SIGNING_ALLOWED=NO -quiet \
  > build/CIProof/logs/store-release-build.log 2>&1

python3 - <<'PY' > build/CIProof/logs/store-bundle-proof.log
import hashlib, json, pathlib, plistlib
root = pathlib.Path('build/CIProof/StoreDerivedData/Build/Products/Release/Stem Separator.app')
assert root.is_dir()
helper = root / 'Contents/Helpers/StemWorker.app'
assert helper.is_dir()
lib = helper / 'Contents/Frameworks/torch/lib/libomp.dylib'
record = json.loads((root / 'Contents/Resources/StemRuntimeMetadata/store-libomp-provenance.json').read_text())
assert hashlib.sha256(lib.read_bytes()).hexdigest() == record['binary_sha256']
assert record['target'] == 'arm64-apple-macos15.1'
assert not (root / 'Contents/Frameworks/Sparkle.framework').exists()
info = plistlib.loads((root / 'Contents/Info.plist').read_bytes())
assert info['CFBundleIdentifier'] == 'com.oliviergrenierbedard.stemseparator'
assert not any(key.startswith('SU') for key in info)
assert (root / 'Contents/Resources/APP_STORE_PRIVACY.md').exists()
assert (root / 'Contents/Resources/APP_STORE_TERMS.md').exists()
import ctypes
openmp = ctypes.CDLL(str(lib.resolve()))
openmp.omp_set_num_threads.argtypes = [ctypes.c_int]
openmp.omp_set_num_threads(4)
openmp.omp_get_max_threads.restype = ctypes.c_int
assert openmp.omp_get_max_threads() == 4
print('Store bundle, pin, and updater boundary verified')
PY
scripts/verify_bundled_notices.sh \
  'build/CIProof/StoreDerivedData/Build/Products/Release/Stem Separator.app' \
  > build/CIProof/logs/store-notices-proof.log 2>&1
