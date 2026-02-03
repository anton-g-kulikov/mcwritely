#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if xcode-select -p 2>/dev/null | grep -q "CommandLineTools"; then
  echo "error: xcode-select points to CommandLineTools. XCTest is missing in this configuration." >&2
  echo "Switch to Xcode and retry:" >&2
  echo "  xcode-select --switch /Applications/Xcode.app/Contents/Developer" >&2
  exit 1
fi

export SWIFTPM_DISABLE_SANDBOX=1
export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-/tmp/clang-module-cache}"
mkdir -p "$CLANG_MODULE_CACHE_PATH"

swift test --disable-sandbox
