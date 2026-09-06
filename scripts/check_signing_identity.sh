#!/bin/zsh

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/release_preflight.sh"

EXPECTED_CODE_SIGN_IDENTITY="${EXPECTED_CODE_SIGN_IDENTITY:-Developer ID Application: Olivier Grenier Bedard (5SVUWU2ZGY)}"

require_command security "The macOS 'security' tool is required to enumerate local code signing identities."

printf 'Enumerating local code signing identities:\n'
security find-identity -v -p codesigning

printf '\nExpecting identity:\n'
printf '  %s\n' "$EXPECTED_CODE_SIGN_IDENTITY"

require_code_signing_identity "$EXPECTED_CODE_SIGN_IDENTITY"

printf '\nVerified expected signing identity is visible to command-line release tooling.\n'
printf 'Next step: signed archive/export work may proceed.\n'
