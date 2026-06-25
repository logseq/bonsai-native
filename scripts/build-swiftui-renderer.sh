#!/usr/bin/env bash
set -euo pipefail

TARGET="${IOS_TARGET:-arm64-apple-ios17.0-simulator}"
SDKROOT="${IOS_SDKROOT:-$(xcrun --sdk iphonesimulator --show-sdk-path)}"
OUTPUT="${1:-/tmp/BonsaiNativeSwiftUI.o}"
if [[ "$OUTPUT" != /* ]]; then
  OUTPUT="$PWD/$OUTPUT"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

xcrun swiftc \
  -target "$TARGET" \
  -sdk "$SDKROOT" \
  ${SWIFT_FLAGS:-} \
  -parse-as-library \
  -emit-object \
  "$REPO_ROOT/apple/swiftui/BonsaiNativeSwiftUI.swift" \
  -o "$OUTPUT"
