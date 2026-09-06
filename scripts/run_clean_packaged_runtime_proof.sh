#!/bin/zsh

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
. "$SCRIPT_DIR/release_preflight.sh"

DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$PROJECT_ROOT/build/DerivedDataCleanProof}"
CONFIGURATION="${CONFIGURATION:-Release}"
DESTINATION="${DESTINATION:-platform=macOS,arch=arm64}"
APP_PATH="${APP_PATH:-$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/Stem Separator.app}"

require_xcode_tooling
require_xcodegen

printf 'Running clean packaged runtime proof.\n'
printf '  derived data: %s\n' "$DERIVED_DATA_PATH"
printf '  configuration: %s\n' "$CONFIGURATION"
printf '  destination: %s\n' "$DESTINATION"

cd "$PROJECT_ROOT"
"$SCRIPT_DIR/build_stem_runtime.sh"
xcodegen generate

xcodebuild \
  -project "TemplateApp.xcodeproj" \
  -scheme "TemplateApp" \
  -configuration "$CONFIGURATION" \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  CODE_SIGNING_ALLOWED=NO \
  clean \
  build

APP_PATH="$APP_PATH" "$SCRIPT_DIR/verify_packaged_runtime_launch.sh"

printf 'Clean packaged runtime proof passed.\n'
printf '  built app: %s\n' "$APP_PATH"
