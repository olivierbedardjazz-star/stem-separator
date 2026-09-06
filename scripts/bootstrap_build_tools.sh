#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
mkdir -p build/BuildTools
archive=build/BuildTools/xcodegen.zip
[[ -f "$archive" ]] || curl --fail --location --retry 3 https://github.com/yonaskolb/XcodeGen/releases/download/2.46.0/xcodegen.zip -o "$archive"
[[ $(shasum -a 256 "$archive" | cut -d ' ' -f 1) == 4d9e34b62172d645eed6457cac13fc222569974098ef4ee9c3368bedf0196806 ]] || exit 1
ditto -x -k "$archive" build/BuildTools
build/BuildTools/xcodegen/bin/xcodegen --version
