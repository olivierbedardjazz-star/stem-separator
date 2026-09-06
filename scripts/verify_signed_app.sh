#!/bin/zsh

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
. "$SCRIPT_DIR/release_preflight.sh"

EXPORT_PATH="${EXPORT_PATH:-$PROJECT_ROOT/build/export}"
APP_NAME="${APP_NAME:-Template App.app}"
APP_PATH="${APP_PATH:-$EXPORT_PATH/$APP_NAME}"

if [[ ! -d "$APP_PATH" ]]; then
  echo "Signed app bundle not found at $APP_PATH. Run scripts/export_release_app.sh first." >&2
  exit 1
fi

require_command codesign "codesign is required to verify the signed app bundle."
require_command spctl "spctl is required to assess the signed app bundle."

printf 'Verifying signed exported app bundle:\n'
printf '  app: %s\n' "$APP_PATH"

codesign --verify --deep --strict --verbose=2 "$APP_PATH"
codesign -dv --verbose=4 "$APP_PATH" 2>&1
spctl --assess --type execute --verbose=4 "$APP_PATH"
"$SCRIPT_DIR/verify_bundled_notices.sh" "$APP_PATH"
"$SCRIPT_DIR/verify_bundled_legal_documents.sh" "$APP_PATH"

printf 'Verified signed exported app bundle.\n'
printf 'Next step: scripts/finalize_exported_app_for_notarization.sh\n'
