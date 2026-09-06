#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
[[ -x build/PackagingVenv/bin/python ]] || build/StemRuntime/portable/python/bin/python3.11 -m venv build/PackagingVenv
build/PackagingVenv/bin/python -m pip install --require-hashes --only-binary=:all: -r Packaging/packaging-tools.lock
