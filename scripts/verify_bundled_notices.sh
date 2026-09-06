#!/bin/zsh

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
. "$SCRIPT_DIR/release_preflight.sh"

APP_ROOT="${1:-${APP_PATH:-$PROJECT_ROOT/build/export/Stem Separator.app}}"
RESOURCES_ROOT="$APP_ROOT/Contents/Resources"

if [[ ! -d "$APP_ROOT" ]]; then
  echo "App bundle not found at $APP_ROOT." >&2
  exit 1
fi

if [[ ! -d "$RESOURCES_ROOT" ]]; then
  echo "App resources directory not found at $RESOURCES_ROOT." >&2
  exit 1
fi

forbidden_downloader_files=(
  "yt-dlp-LICENSE.txt"
  "yt-dlp-source.txt"
  "FFmpeg-GPL-3.0-or-later.txt"
  "ffmpeg-source.txt"
  "yt-dlp.json"
  "ffmpeg.json"
)

printf 'Verifying bundled third-party notice boundary:\n'
printf '  app: %s\n' "$APP_ROOT"

for filename in "${forbidden_downloader_files[@]}"; do
  local_path="$RESOURCES_ROOT/$filename"
  if [[ -f "$local_path" ]]; then
    echo "Downloader-specific runtime notice or manifest should not be bundled in the base template lane: $local_path" >&2
    exit 1
  fi
done

printf 'Verified base template bundle does not carry downloader-specific notices or runtime manifests.\n'

for required in THIRD_PARTY_NOTICES.md RuntimeLicenses/Python-LICENSE.txt RuntimeLicenses/Sparkle-LICENSE.txt; do
  [[ -s "$RESOURCES_ROOT/$required" ]] || { echo "Missing required notice: $required" >&2; exit 1; }
done
