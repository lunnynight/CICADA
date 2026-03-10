#!/bin/bash
# Package Cicada for Windows distribution
set -e

FLUTTER="${FLUTTER:-D:/flutter/bin/flutter}"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="0.1.0"

echo "=== Building Cicada v${VERSION} for Windows ==="

cd "$PROJECT_DIR"

"$FLUTTER" clean
"$FLUTTER" pub get
"$FLUTTER" build windows --release

RELEASE_DIR="build/windows/x64/runner/Release"
OUTPUT="cicada-v${VERSION}-windows-x64.zip"

cd "$RELEASE_DIR"
if command -v 7z &>/dev/null; then
  7z a -tzip "../../../../../$OUTPUT" .
elif command -v zip &>/dev/null; then
  zip -r "../../../../../$OUTPUT" .
else
  echo "Error: No zip tool found (need 7z or zip)"
  exit 1
fi

cd "$PROJECT_DIR"
echo "=== Package created: $OUTPUT ($(du -h "$OUTPUT" | cut -f1)) ==="
