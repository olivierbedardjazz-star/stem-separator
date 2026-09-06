#!/bin/zsh
set -euo pipefail
STEM_ROOT=${0:A:h:h}
STEM_DERIVED_DATA="${DERIVED_DATA_PATH:-$STEM_ROOT/build/LocalRelease/DerivedData}"
STEM_BIN="${SPARKLE_BIN_DIR:-$STEM_DERIVED_DATA/SourcePackages/artifacts/sparkle/Sparkle/bin}"
for STEM_TOOL in generate_keys generate_appcast sign_update; do
  [[ -x "$STEM_BIN/$STEM_TOOL" ]] || { print -u2 "Missing pinned Sparkle tool: $STEM_TOOL. Resolve the package in the explicit DerivedData path first."; exit 1; }
done
print -r -- "$STEM_BIN"
