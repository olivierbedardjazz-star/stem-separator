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

require_command codesign "codesign is required to verify notarization readiness."

SPARKLE_FRAMEWORK_PATH="$APP_PATH/Contents/Frameworks/Sparkle.framework"
SPARKLE_AUTOUPDATE_PATH="$SPARKLE_FRAMEWORK_PATH/Versions/Current/Autoupdate"
SPARKLE_DOWNLOADER_XPC_PATH="$SPARKLE_FRAMEWORK_PATH/Versions/Current/XPCServices/Downloader.xpc"
SPARKLE_INSTALLER_XPC_PATH="$SPARKLE_FRAMEWORK_PATH/Versions/Current/XPCServices/Installer.xpc"
SPARKLE_UPDATER_APP_PATH="$SPARKLE_FRAMEWORK_PATH/Versions/Current/Updater.app"

helper_paths=(
  "$SPARKLE_FRAMEWORK_PATH"
  "$SPARKLE_AUTOUPDATE_PATH"
  "$SPARKLE_DOWNLOADER_XPC_PATH"
  "$SPARKLE_INSTALLER_XPC_PATH"
  "$SPARKLE_UPDATER_APP_PATH"
)

for helper_path in "${helper_paths[@]}"; do
  if [[ ! -e "$helper_path" ]]; then
    echo "Bundled runtime component not found at $helper_path." >&2
    exit 1
  fi
done

assert_runtime_flag() {
  local component_label="$1"
  local component_path="$2"
  local log_output

  log_output=$(codesign -dv --verbose=4 "$component_path" 2>&1)

  if ! printf '%s\n' "$log_output" | grep -F "flags=0x10000(runtime)" >/dev/null 2>&1; then
    echo "$component_label hardened runtime: FAIL" >&2
    echo "Expected flags=0x10000(runtime) for $component_path but it was not present." >&2
    printf '%s\n' "$log_output" >&2
    exit 1
  fi

  printf '%s hardened runtime: PASS\n' "$component_label"
}

assert_developer_id_signature() {
  local component_label="$1"
  local component_path="$2"
  local log_output

  log_output=$(codesign -dv --verbose=4 "$component_path" 2>&1)

  if ! printf '%s\n' "$log_output" | grep -F "Authority=Developer ID Application:" >/dev/null 2>&1; then
    echo "$component_label developer id signature: FAIL" >&2
    echo "Expected a Developer ID Application authority for $component_path." >&2
    printf '%s\n' "$log_output" >&2
    exit 1
  fi

  if ! printf '%s\n' "$log_output" | grep -F "Timestamp=" >/dev/null 2>&1; then
    echo "$component_label secure timestamp: FAIL" >&2
    echo "Expected a secure timestamp for $component_path." >&2
    printf '%s\n' "$log_output" >&2
    exit 1
  fi

  if printf '%s\n' "$log_output" | grep -F "Signature=adhoc" >/dev/null 2>&1; then
    echo "$component_label developer id signature: FAIL" >&2
    echo "Ad-hoc signatures are not acceptable for notarization at $component_path." >&2
    printf '%s\n' "$log_output" >&2
    exit 1
  fi

  printf '%s developer id signature: PASS\n' "$component_label"
}

printf 'Verifying notarization readiness.\n'
printf '  app: %s\n' "$APP_PATH"

codesign --verify --deep --strict --verbose=2 "$APP_PATH"
printf 'App code signature structural verification: PASS\n'

assert_runtime_flag "App bundle" "$APP_PATH"
assert_runtime_flag "Sparkle framework" "$SPARKLE_FRAMEWORK_PATH"
assert_runtime_flag "Sparkle Autoupdate" "$SPARKLE_AUTOUPDATE_PATH"
assert_runtime_flag "Sparkle Downloader.xpc" "$SPARKLE_DOWNLOADER_XPC_PATH"
assert_runtime_flag "Sparkle Installer.xpc" "$SPARKLE_INSTALLER_XPC_PATH"
assert_runtime_flag "Sparkle Updater.app" "$SPARKLE_UPDATER_APP_PATH"

assert_developer_id_signature "App bundle" "$APP_PATH"
assert_developer_id_signature "Sparkle framework" "$SPARKLE_FRAMEWORK_PATH"
assert_developer_id_signature "Sparkle Autoupdate" "$SPARKLE_AUTOUPDATE_PATH"
assert_developer_id_signature "Sparkle Downloader.xpc" "$SPARKLE_DOWNLOADER_XPC_PATH"
assert_developer_id_signature "Sparkle Installer.xpc" "$SPARKLE_INSTALLER_XPC_PATH"
assert_developer_id_signature "Sparkle Updater.app" "$SPARKLE_UPDATER_APP_PATH"

printf 'Notarization readiness verification passed.\n'
printf 'Next step: scripts/submit_notarization.sh\n'
