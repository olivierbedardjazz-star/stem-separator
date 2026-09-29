#!/bin/zsh
set -euo pipefail
STEM_ROOT="${SRCROOT:?}"
STEM_WORKER="$STEM_ROOT/build/StemRuntime/dist/StemWorker.app"
[[ -x "$STEM_WORKER/Contents/MacOS/StemWorker" ]] || { echo 'Build the bundled runtime first: scripts/build_stem_runtime.sh' >&2; exit 1; }
mkdir -p "$TARGET_BUILD_DIR/$CONTENTS_FOLDER_PATH/Helpers"
/usr/bin/rsync -a --delete "$STEM_WORKER/" "$TARGET_BUILD_DIR/$CONTENTS_FOLDER_PATH/Helpers/StemWorker.app/"
if [[ "${TARGET_NAME:-}" == StemSeparatorAppStore ]]; then
  STEM_STORE_LIBOMP="$STEM_ROOT/build/AppStoreRuntime/libomp.dylib"
  [[ -f "$STEM_STORE_LIBOMP" ]] || {
    echo 'Build the sandbox-compatible Store OpenMP runtime first: scripts/build_store_libomp.sh' >&2
    exit 1
  }
  cp "$STEM_STORE_LIBOMP" "$TARGET_BUILD_DIR/$CONTENTS_FOLDER_PATH/Helpers/StemWorker.app/Contents/Frameworks/torch/lib/libomp.dylib"
fi
STEM_METADATA="$TARGET_BUILD_DIR/$CONTENTS_FOLDER_PATH/Resources/StemRuntimeMetadata"
mkdir -p "$STEM_METADATA"
for STEM_RECORD in provenance.json dependency-inventory.json requirements-lock.txt artifacts-lock.json python-build-metadata.json; do
  cp "$STEM_ROOT/runtime/$STEM_RECORD" "$STEM_METADATA/$STEM_RECORD"
done
if [[ "${TARGET_NAME:-}" == StemSeparatorAppStore ]]; then
  cp "$STEM_ROOT/build/AppStoreRuntime/provenance.json" "$STEM_METADATA/store-libomp-provenance.json"
fi
"$STEM_ROOT/build/StemRuntime/portable-venv/bin/python" "$STEM_ROOT/scripts/create_runtime_manifest.py" "$TARGET_BUILD_DIR/$CONTENTS_FOLDER_PATH/Helpers/StemWorker.app" "$STEM_METADATA/manifest.json"
