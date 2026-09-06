#!/bin/zsh

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
PROJECT_FILE="$PROJECT_ROOT/project.yml"

source "$SCRIPT_DIR/release_preflight.sh"

usage() {
  cat <<'EOF'
Usage:
  scripts/configure_github_appcast.sh owner/repository [sparkle_public_ed_key]

Environment overrides:
  APPCAST_URL            Explicit feed URL. Defaults to:
                         https://github.com/<owner>/<repository>/releases/latest/download/appcast.xml
  XCODEGEN_BIN           Optional xcodegen executable path override.

This script updates project.yml with the real GitHub Releases appcast URL,
optionally refreshes the Sparkle public ED key, and regenerates the Xcode project.
EOF
}

fail_configuration() {
  echo "$1" >&2
  exit 1
}

repository_slug="${1:-${GH_REPOSITORY:-}}"
sparkle_public_key="${2:-${SPARKLE_PUBLIC_ED_KEY:-}}"

if [[ -z "$repository_slug" ]]; then
  usage >&2
  fail_configuration "A GitHub repository slug is required in the form owner/repository."
fi

if [[ ! "$repository_slug" =~ '^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$' ]]; then
  fail_configuration "Invalid GitHub repository slug: $repository_slug"
fi

appcast_url="${APPCAST_URL:-https://github.com/${repository_slug}/releases/latest/download/appcast.xml}"

if [[ ! "$appcast_url" =~ '^https://github\.com/[A-Za-z0-9._-]+/[A-Za-z0-9._-]+/releases/.+/appcast\.xml$' ]]; then
  fail_configuration "APPCAST_URL must be an HTTPS GitHub Releases appcast URL ending in appcast.xml."
fi

if [[ -n "$sparkle_public_key" && "$sparkle_public_key" == *SET_SPARKLE_PUBLIC_KEY* ]]; then
  fail_configuration "SPARKLE_PUBLIC_ED_KEY still contains the placeholder token."
fi

if ! command -v "${XCODEGEN_BIN:-xcodegen}" >/dev/null 2>&1; then
  require_xcodegen
fi

/usr/bin/python3 - "$PROJECT_FILE" "$appcast_url" "${sparkle_public_key:-__KEEP_EXISTING__}" <<'PY'
from pathlib import Path
import re
import sys

project_file = Path(sys.argv[1])
appcast_url = sys.argv[2]
sparkle_public_key = sys.argv[3]

text = project_file.read_text()

text, appcast_count = re.subn(
    r"(^\s*TEMPLATE_APP_SPARKLE_APPCAST_URL:\s*).*$",
    rf"\1{appcast_url}",
    text,
    count=1,
    flags=re.MULTILINE,
)

if appcast_count != 1:
    raise SystemExit("Failed to locate TEMPLATE_APP_SPARKLE_APPCAST_URL in project.yml.")

if sparkle_public_key != "__KEEP_EXISTING__":
    text, key_count = re.subn(
        r"(^\s*TEMPLATE_APP_SPARKLE_PUBLIC_ED_KEY:\s*).*$",
        rf"\1{sparkle_public_key}",
        text,
        count=1,
        flags=re.MULTILINE,
    )

    if key_count != 1:
        raise SystemExit("Failed to locate TEMPLATE_APP_SPARKLE_PUBLIC_ED_KEY in project.yml.")

project_file.write_text(text)
PY

"${XCODEGEN_BIN:-xcodegen}" generate --spec "$PROJECT_FILE"

printf 'Configured updater feed in %s\n' "$PROJECT_FILE"
printf '  repository: %s\n' "$repository_slug"
printf '  appcast URL: %s\n' "$appcast_url"

if [[ -n "$sparkle_public_key" ]]; then
  printf '  public key: updated from CLI/env input\n'
else
  printf '  public key: kept existing checked-in value\n'
fi

printf '\nNext steps:\n'
printf '  1. Build the app again so Info.plist expands the updated settings.\n'
printf '  2. Verify Help > Check for Updates... is enabled.\n'
printf '  3. Run the 266 and 276 verification checklists before shipping.\n'
