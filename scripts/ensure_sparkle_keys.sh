#!/bin/zsh

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
SPARKLE_KEY_ACCOUNT="${SPARKLE_KEY_ACCOUNT:-stem-separator-ed25519}"
PROJECT_YML_PATH="${PROJECT_YML_PATH:-$PROJECT_ROOT/project.yml}"
PBXPROJ_PATH="${PBXPROJ_PATH:-$PROJECT_ROOT/TemplateApp.xcodeproj/project.pbxproj}"

trim_value() {
  printf '%s' "$1" | tr -d "[:space:]'\";"
}

extract_public_key_from_file() {
  local file_path="$1"

  sed -n 's/^[[:space:]]*TEMPLATE_APP_SPARKLE_PUBLIC_ED_KEY[[:space:]]*[:=][[:space:]]*//p' "$file_path" \
    | head -n 1
}

fail_missing_keys() {
  cat >&2 <<EOF
Missing Sparkle signing key material for account '$SPARKLE_KEY_ACCOUNT'.

Normal release preparation must not generate or rotate updater keys automatically.
Bootstrap or import the intended stable Sparkle key explicitly, then make sure
project.yml and the generated Xcode project trust that same public key.

Recommended next steps:
  1. Run: scripts/bootstrap_sparkle_keys.sh
  2. If the updater identity is changing intentionally, update:
     $PROJECT_YML_PATH
  3. Regenerate the Xcode project:
     xcodegen generate
EOF
  exit 1
}

sparkle_bin_dir=$("$SCRIPT_DIR/locate_sparkle_bin.sh")

if [[ ! -f "$PROJECT_YML_PATH" ]]; then
  echo "project.yml was not found at $PROJECT_YML_PATH." >&2
  exit 1
fi

if [[ ! -f "$PBXPROJ_PATH" ]]; then
  echo "Generated Xcode project file was not found at $PBXPROJ_PATH. Run xcodegen generate first." >&2
  exit 1
fi

configured_public_key=$(trim_value "$(extract_public_key_from_file "$PROJECT_YML_PATH")")
if [[ -z "$configured_public_key" ]]; then
  echo "TEMPLATE_APP_SPARKLE_PUBLIC_ED_KEY is missing from $PROJECT_YML_PATH." >&2
  exit 1
fi

if [[ ! "$configured_public_key" =~ '^[A-Za-z0-9+/=]{40,}$' ]]; then
  echo "Configured Sparkle public key in $PROJECT_YML_PATH does not look valid: $configured_public_key" >&2
  exit 1
fi

generated_project_public_key=$(trim_value "$(extract_public_key_from_file "$PBXPROJ_PATH")")
if [[ -z "$generated_project_public_key" ]]; then
  echo "TEMPLATE_APP_SPARKLE_PUBLIC_ED_KEY is missing from $PBXPROJ_PATH. Run xcodegen generate first." >&2
  exit 1
fi

if [[ "$generated_project_public_key" != "$configured_public_key" ]]; then
  cat >&2 <<EOF
Sparkle public key drift detected between project.yml and the generated Xcode project.

project.yml key: $configured_public_key
project.pbxproj key: $generated_project_public_key

Run 'xcodegen generate' so the built app trusts the same updater identity declared in project.yml.
EOF
  exit 1
fi

if ! active_public_key=$("$sparkle_bin_dir/generate_keys" --account "$SPARKLE_KEY_ACCOUNT" -p 2>/dev/null); then
  fail_missing_keys
fi

active_public_key=$(trim_value "$active_public_key")
if [[ -z "$active_public_key" ]]; then
  fail_missing_keys
fi

if [[ "$active_public_key" != "$configured_public_key" ]]; then
  cat >&2 <<EOF
Sparkle key mismatch detected.

Embedded updater public key: $configured_public_key
Active Sparkle signing public key for account '$SPARKLE_KEY_ACCOUNT': $active_public_key

Release preparation stopped before signing or publishing any updater assets.
If this key change is intentional, update $PROJECT_YML_PATH, run 'xcodegen generate',
and rebuild with the new trusted updater identity.
EOF
  exit 1
fi

printf 'Verified Sparkle updater identity for account %s.\n' "$SPARKLE_KEY_ACCOUNT"
