#!/bin/zsh

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$PROJECT_ROOT/build/LocalRelease/DerivedData}"
APP_PATH="$DERIVED_DATA_PATH/Build/Products/Release/Stem Separator.app"

"$SCRIPT_DIR/bootstrap_build_tools.sh"

command -v xcodebuild >/dev/null 2>&1 || {
  echo "xcodebuild is required to build the local Release app." >&2
  exit 1
}

cd "$PROJECT_ROOT"
"$SCRIPT_DIR/build_stem_runtime.sh"
"$PROJECT_ROOT/build/BuildTools/xcodegen/bin/xcodegen" generate

xcodebuild build \
  -project "TemplateApp.xcodeproj" \
  -scheme "TemplateApp" \
  -configuration Release \
  -destination "platform=macOS,arch=arm64" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  CODE_SIGNING_ALLOWED=NO

if [[ ! -d "$APP_PATH" ]]; then
  echo "Release build completed but the app bundle was not found at $APP_PATH." >&2
  exit 1
fi

printf 'Built unsigned local Release app:\n'
printf '  %s\n' "$APP_PATH"
printf 'This uses Release optimization but is not signed, notarized, stapled, or distributable.\n'
printf 'Open it with:\n'
printf '  open "%s"\n' "$APP_PATH"
