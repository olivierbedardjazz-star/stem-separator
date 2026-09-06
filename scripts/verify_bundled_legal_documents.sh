#!/bin/zsh

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 /path/to/Stem Separator.app" >&2
  exit 1
fi

APP_PATH="$1"
RESOURCES_ROOT="$APP_PATH/Contents/Resources"

if [[ ! -d "$APP_PATH" ]]; then
  echo "App bundle not found at $APP_PATH" >&2
  exit 1
fi

expected_documents=(
  "TEMPLATE_APP_TERMS.md|# Stem Separator Terms of Use"
  "TEMPLATE_APP_PRIVACY.md|# Stem Separator Privacy Policy"
)

for document_contract in "${expected_documents[@]}"; do
  document_name="${document_contract%%|*}"
  expected_heading="${document_contract#*|}"
  document_path="$RESOURCES_ROOT/$document_name"

  if [[ ! -f "$document_path" ]]; then
    echo "Missing bundled legal document: $document_path" >&2
    exit 1
  fi

  if [[ ! -s "$document_path" ]]; then
    echo "Bundled legal document is empty: $document_path" >&2
    exit 1
  fi

  if ! grep -F "$expected_heading" "$document_path" >/dev/null 2>&1; then
    echo "Bundled legal document is missing expected heading '$expected_heading': $document_path" >&2
    exit 1
  fi
done

printf 'Verified bundled legal documents.\n'
