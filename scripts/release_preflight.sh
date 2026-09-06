#!/bin/zsh

set -euo pipefail

fail_preflight() {
  echo "$1" >&2
  exit 1
}

require_command() {
  local command_name="$1"
  local failure_message="$2"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    fail_preflight "$failure_message"
  fi
}

require_xcode_tooling() {
  require_command xcodebuild "xcodebuild is required. Install Xcode command-line tooling and make sure xcodebuild is on PATH."

  local developer_dir
  developer_dir=$(xcode-select -p 2>/dev/null || true)
  if [[ -z "$developer_dir" || ! -d "$developer_dir" ]]; then
    fail_preflight "Xcode developer tooling is not configured. Run 'xcode-select -p' successfully or select an active Xcode installation first."
  fi
}

require_xcodegen() {
  require_command xcodegen "xcodegen is required to regenerate TemplateApp.xcodeproj from project.yml before release builds."
}

require_code_signing_identity() {
  local code_sign_identity="$1"

  if ! command -v security >/dev/null 2>&1; then
    fail_preflight "The macOS 'security' tool is required to verify local code signing identities."
  fi

  if ! security find-identity -v -p codesigning 2>/dev/null | grep -F "$code_sign_identity" >/dev/null 2>&1; then
    fail_preflight "The requested CODE_SIGN_IDENTITY was not found in the local keychain: $code_sign_identity"
  fi
}

require_archive_exists() {
  local archive_path="$1"

  if [[ ! -d "$archive_path" ]]; then
    fail_preflight "Archive not found at $archive_path. Run scripts/archive_release_app.sh first."
  fi
}

require_github_cli_ready() {
  require_command gh "GitHub CLI is required for publishing releases. Install 'gh' and make sure it is on PATH."

  if ! gh auth status >/dev/null 2>&1; then
    fail_preflight "GitHub CLI is not authenticated. Run 'gh auth login' before publishing a release."
  fi
}

require_updates_repo_publish_credential() {
  local target_repository="$1"
  local source_repository="${2:-}"
  local updates_repository="olivierbedardjazz-star/template-app-UPDATES"
  local private_source_repository="olivierbedardjazz-star/template-app"

  if [[ "$target_repository" != "$updates_repository" ]]; then
    return 0
  fi

  if [[ "$source_repository" == "$private_source_repository" ]]; then
    if [[ -z "${UPDATES_REPO_TOKEN:-}" ]]; then
      fail_preflight "UPDATES_REPO_TOKEN is required when the private source repo publishes to $updates_repository."
    fi

    return 0
  fi

  if [[ -z "${GH_TOKEN:-}" && -z "${GITHUB_TOKEN:-}" ]]; then
    fail_preflight "A GitHub publish token is required for $updates_repository. Set GH_TOKEN, GITHUB_TOKEN, or UPDATES_REPO_TOKEN before publishing."
  fi
}

require_notarytool() {
  require_command xcrun "xcrun is required for Apple notarization submission."

  if ! xcrun --find notarytool >/dev/null 2>&1; then
    fail_preflight "Apple notarytool is required. Install a recent Xcode and make sure xcrun can locate notarytool."
  fi
}

require_notarytool_keychain_profile_name() {
  local profile_name="$1"

  if [[ -z "$profile_name" ]]; then
    fail_preflight "NOTARYTOOL_KEYCHAIN_PROFILE is required for notarization submission."
  fi
}
