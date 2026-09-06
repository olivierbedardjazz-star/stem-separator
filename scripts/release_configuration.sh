#!/bin/zsh
# Shared non-secret release defaults. Caller remains responsible for phase preflight.
STEM_RELEASE_ROOT=${0:A:h:h}
STEM_BUILD_PYTHON="${STEM_BUILD_PYTHON:-$STEM_RELEASE_ROOT/build/StemRuntime/portable-venv/bin/python}"
[[ -x "$STEM_BUILD_PYTHON" ]] || { print -u2 'Bootstrap the declared runtime/build Python first.'; return 1; }
stem_config_value() {
  "$STEM_BUILD_PYTHON" -c 'import json,sys; print(json.load(open(sys.argv[1]))[sys.argv[2]])' "$STEM_RELEASE_ROOT/Packaging/release-config.json" "$1"
}
APP_NAME="${APP_NAME:-$(stem_config_value appName)}"
SOURCE_REPOSITORY="${SOURCE_REPOSITORY:-$(stem_config_value repository)}"
GH_REPOSITORY="${GH_REPOSITORY:-$SOURCE_REPOSITORY}"
TEAM_ID="${TEAM_ID:-$(stem_config_value teamID)}"
CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY:-$(stem_config_value signingIdentity)}"
SPARKLE_KEY_ACCOUNT="${SPARKLE_KEY_ACCOUNT:-$(stem_config_value sparkleAccount)}"
NOTARYTOOL_KEYCHAIN_PROFILE="${NOTARYTOOL_KEYCHAIN_PROFILE:-$(stem_config_value notaryProfile)}"
export APP_NAME SOURCE_REPOSITORY GH_REPOSITORY TEAM_ID CODE_SIGN_IDENTITY SPARKLE_KEY_ACCOUNT NOTARYTOOL_KEYCHAIN_PROFILE STEM_BUILD_PYTHON
