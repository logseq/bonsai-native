#!/usr/bin/env bash
set -euo pipefail

TARGET="${IOS_TARGET:-arm64-apple-ios17.0-simulator}"
SDKROOT="${IOS_SDKROOT:-$(xcrun --sdk iphonesimulator --show-sdk-path)}"
OUTPUT="${1:-/tmp/BonsaiNativeSwiftUI.o}"

xcrun swiftc \
  -target "$TARGET" \
  -sdk "$SDKROOT" \
  -parse-as-library \
  -emit-object \
  apple/swiftui/BonsaiNativeSwiftUI.swift \
  -o "$OUTPUT"
