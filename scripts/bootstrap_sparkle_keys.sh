#!/bin/zsh

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
SPARKLE_KEY_ACCOUNT="${SPARKLE_KEY_ACCOUNT:-stem-separator-ed25519}"

sparkle_bin_dir=$("$SCRIPT_DIR/locate_sparkle_bin.sh")

"$sparkle_bin_dir/generate_keys" --account "$SPARKLE_KEY_ACCOUNT"
public_key=$("$sparkle_bin_dir/generate_keys" --account "$SPARKLE_KEY_ACCOUNT" -p)

cat <<EOF

Sparkle key bootstrap completed for account '$SPARKLE_KEY_ACCOUNT'.

Current Sparkle public key:
$public_key

If this is the updater identity the app should trust, update:
  $PROJECT_ROOT/project.yml

Then regenerate the Xcode project:
  xcodegen generate

Normal release preparation will not rotate Sparkle keys automatically.
EOF
