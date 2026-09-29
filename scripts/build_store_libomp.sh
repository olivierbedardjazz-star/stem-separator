#!/bin/zsh
# Build the Store-only OpenMP replacement with the same macOS floor as the app.
# The libomp shipped in the pinned Torch 2.6 wheel aborts in App Sandbox when
# its shared-memory registration is denied. LLVM 23 falls back correctly.
set -euo pipefail

STEM_ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$STEM_ROOT"
[[ $(uname -m) == arm64 ]] || { echo 'Apple Silicon build host required' >&2; exit 1; }

STEM_VERSION=23.1.2
STEM_SOURCE_HASH=c98bbef08a2b4c2613cd50e9aa9ae7b69b1fe6c16b2c40373bc0ab6116fdf78a
STEM_BUILD_ROOT="$STEM_ROOT/build/AppStoreRuntime"
STEM_ARCHIVE="$STEM_BUILD_ROOT/llvm-project-$STEM_VERSION.src.tar.xz"
STEM_SOURCE="$STEM_BUILD_ROOT/source/llvm-project-$STEM_VERSION.src"
STEM_OUTPUT="$STEM_BUILD_ROOT/libomp.dylib"
mkdir -p "$STEM_BUILD_ROOT"

if [[ ! -f "$STEM_ARCHIVE" ]]; then
  curl --fail --location --retry 3 \
    "https://github.com/llvm/llvm-project/releases/download/llvmorg-$STEM_VERSION/llvm-project-$STEM_VERSION.src.tar.xz" \
    -o "$STEM_ARCHIVE"
fi
[[ $(shasum -a 256 "$STEM_ARCHIVE" | cut -d ' ' -f 1) == "$STEM_SOURCE_HASH" ]] || {
  echo 'LLVM OpenMP source hash mismatch' >&2; exit 1
}

if [[ ! -f "$STEM_SOURCE/openmp/CMakeLists.txt" ]]; then
  mkdir -p "$STEM_BUILD_ROOT/source"
  tar -xJf "$STEM_ARCHIVE" -C "$STEM_BUILD_ROOT/source" \
    "llvm-project-$STEM_VERSION.src/cmake" \
    "llvm-project-$STEM_VERSION.src/runtimes" \
    "llvm-project-$STEM_VERSION.src/openmp" \
    "llvm-project-$STEM_VERSION.src/third-party/unittest" \
    "llvm-project-$STEM_VERSION.src/llvm/cmake" \
    "llvm-project-$STEM_VERSION.src/llvm/include"
fi

cmake -S "$STEM_SOURCE/runtimes" -B "$STEM_BUILD_ROOT/cmake-build" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=15.1 \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DLLVM_ENABLE_RUNTIMES=openmp \
  -DLLVM_INCLUDE_TESTS=OFF \
  -DOPENMP_ENABLE_OMPT_TOOLS=OFF
cmake --build "$STEM_BUILD_ROOT/cmake-build" --target omp -j 8
cp "$STEM_BUILD_ROOT/cmake-build/openmp/runtime/src/libomp.dylib" "$STEM_OUTPUT"

otool -l "$STEM_OUTPUT" | grep -A5 LC_BUILD_VERSION | grep -q 'minos 15.1' || {
  echo 'Store OpenMP runtime does not target macOS 15.1' >&2; exit 1
}
file "$STEM_OUTPUT" | grep -q arm64 || { echo 'Store OpenMP runtime is not arm64' >&2; exit 1; }

python3 - "$STEM_OUTPUT" "$STEM_BUILD_ROOT/provenance.json" "$STEM_VERSION" "$STEM_SOURCE_HASH" <<'PY'
import hashlib, json, pathlib, sys
binary, output, version, source_hash = sys.argv[1:]
record = {
    'component': 'LLVM OpenMP libomp',
    'version': version,
    'source_url': f'https://github.com/llvm/llvm-project/releases/download/llvmorg-{version}/llvm-project-{version}.src.tar.xz',
    'source_sha256': source_hash,
    'binary_sha256': hashlib.sha256(pathlib.Path(binary).read_bytes()).hexdigest(),
    'license': 'Apache-2.0 WITH LLVM-exception',
    'target': 'arm64-apple-macos15.1',
    'purpose': 'Store-only sandbox-compatible replacement for the bundled Torch OpenMP runtime',
}
pathlib.Path(output).write_text(json.dumps(record, indent=2, sort_keys=True) + '\n')
PY
echo "Store OpenMP runtime ready: $STEM_OUTPUT"
