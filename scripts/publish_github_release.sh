#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
exec build/StemRuntime/portable-venv/bin/python scripts/release_pipeline.py publish
