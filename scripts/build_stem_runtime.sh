#!/bin/zsh
set -euo pipefail
STEM_ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$STEM_ROOT"
[[ $(uname -m) == arm64 ]] || { echo 'The runtime requires an Apple Silicon build host.' >&2; exit 1; }
mkdir -p build/StemRuntime runtime/models
STEM_ARCHIVE=build/StemRuntime/python-standalone.tar.gz
if [[ ! -f "$STEM_ARCHIVE" ]]; then
  curl --fail --location --retry 3 'https://github.com/astral-sh/python-build-standalone/releases/download/20260901/cpython-3.11.16%2B20260901-aarch64-apple-darwin-install_only_stripped.tar.gz' -o "$STEM_ARCHIVE"
fi
[[ $(shasum -a 256 "$STEM_ARCHIVE" | cut -d ' ' -f 1) == 768f05cf200273bbdda9a5955a5a6892a4b22f2a0b1e4b0a9160f5c7fce86816 ]] || { echo 'Python archive hash mismatch' >&2; exit 1; }
if [[ ! -x build/StemRuntime/portable/python/bin/python3.11 ]]; then
  mkdir -p build/StemRuntime/portable
  tar -xzf "$STEM_ARCHIVE" -C build/StemRuntime/portable
fi
[[ -x build/StemRuntime/portable-venv/bin/python ]] || build/StemRuntime/portable/python/bin/python3.11 -m venv build/StemRuntime/portable-venv
STEM_VENV="$STEM_ROOT/build/StemRuntime/portable-venv/bin/python"
"$STEM_VENV" scripts/install_locked_runtime.py
if [[ ! -f runtime/models/955717e8-8726e21a.th ]]; then
  curl --fail --location --retry 3 https://dl.fbaipublicfiles.com/demucs/hybrid_transformer/955717e8-8726e21a.th -o runtime/models/955717e8-8726e21a.th
fi
[[ $(shasum -a 256 runtime/models/955717e8-8726e21a.th | cut -d ' ' -f 1) == 8726e21a993978c7ba086d3872e7608d7d5bfca646ca4aca459ffda844faa8b4 ]] || { echo 'Model hash mismatch' >&2; exit 1; }
"$STEM_VENV" runtime/collect_notices.py
"$STEM_VENV" -m PyInstaller --noconfirm --workpath build/StemRuntime/portable-freeze --distpath build/StemRuntime/dist runtime/StemWorker.spec
"$STEM_VENV" scripts/audit_stem_runtime.py build/StemRuntime/dist/StemWorker.app > build/StemRuntime/runtime-audit.json
