#!/bin/zsh
set -euo pipefail
STEM_ROOT=$(cd "$(dirname "$0")/.." && pwd)
APP_PATH="${APP_PATH:-$STEM_ROOT/build/LocalRelease/DerivedData/Build/Products/Release/Stem Separator.app}"
[[ -d "$APP_PATH/Contents/Frameworks/Sparkle.framework" ]] || { echo 'Sparkle is missing' >&2; exit 1; }
"$STEM_ROOT/scripts/verify_bundled_notices.sh" "$APP_PATH"
"$STEM_ROOT/scripts/verify_bundled_legal_documents.sh" "$APP_PATH"
cd "$STEM_ROOT"
STEM_PYTHON="$STEM_ROOT/build/StemRuntime/portable-venv/bin/python"
"$STEM_PYTHON" scripts/audit_stem_runtime.py "$APP_PATH" > build/StemRuntime/packaged-runtime-audit.json
"$STEM_PYTHON" runtime/test_worker.py "$APP_PATH/Contents/Helpers/StemWorker.app/Contents/MacOS/StemWorker"
echo 'PASS: actual packaged worker inference, legal resources, and nested binary dependency audit.'
