#!/bin/zsh

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
. "$SCRIPT_DIR/release_preflight.sh"

APP_NAME="${APP_NAME:-Template App.app}"
EXPORT_PATH="${EXPORT_PATH:-$PROJECT_ROOT/build/export}"
APP_PATH="${APP_PATH:-$EXPORT_PATH/$APP_NAME}"
CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY:-}"

if [[ -z "$CODE_SIGN_IDENTITY" ]]; then
  echo "CODE_SIGN_IDENTITY is required to sign bundled helper executables." >&2
  exit 1
fi

if [[ ! -d "$APP_PATH" ]]; then
  echo "Exported app bundle not found at $APP_PATH. Run scripts/export_release_app.sh first." >&2
  exit 1
fi

require_command codesign "codesign is required to sign bundled helper executables."
require_code_signing_identity "$CODE_SIGN_IDENTITY"

SPARKLE_FRAMEWORK_ROOT="$APP_PATH/Contents/Frameworks/Sparkle.framework"
SPARKLE_VERSION_ROOT="$SPARKLE_FRAMEWORK_ROOT/Versions/Current"
SPARKLE_AUTOUPDATE_PATH="$SPARKLE_VERSION_ROOT/Autoupdate"
SPARKLE_DOWNLOADER_XPC_PATH="$SPARKLE_VERSION_ROOT/XPCServices/Downloader.xpc"
SPARKLE_INSTALLER_XPC_PATH="$SPARKLE_VERSION_ROOT/XPCServices/Installer.xpc"
SPARKLE_UPDATER_APP_PATH="$SPARKLE_VERSION_ROOT/Updater.app"

printf 'Signing bundled helper executables with hardened runtime.\n'
printf '  app: %s\n' "$APP_PATH"
printf '  signing identity: %s\n' "$CODE_SIGN_IDENTITY"

for sparkle_path in \
  "$SPARKLE_FRAMEWORK_ROOT" \
  "$SPARKLE_AUTOUPDATE_PATH" \
  "$SPARKLE_DOWNLOADER_XPC_PATH" \
  "$SPARKLE_INSTALLER_XPC_PATH" \
  "$SPARKLE_UPDATER_APP_PATH"; do
  if [[ ! -e "$sparkle_path" ]]; then
    echo "Sparkle runtime component not found at $sparkle_path." >&2
    exit 1
  fi
done

sign_path() {
  local component_path="$1"
  codesign --force --timestamp --options runtime --sign "$CODE_SIGN_IDENTITY" "$component_path"
  printf 'Signed helper executable with hardened runtime: %s\n' "$component_path"
}

sign_path "$SPARKLE_AUTOUPDATE_PATH"
sign_path "$SPARKLE_DOWNLOADER_XPC_PATH"
sign_path "$SPARKLE_INSTALLER_XPC_PATH"
sign_path "$SPARKLE_UPDATER_APP_PATH"
sign_path "$SPARKLE_FRAMEWORK_ROOT"

printf 'Finished signing bundled helper executables.\n'
