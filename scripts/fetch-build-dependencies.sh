#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOWNLOAD_DIR="${DOWNLOAD_DIR:-$ROOT_DIR/downloads/sources}"
QRCODEGEN_VERSION="1.8.0"
QRCODEGEN_ARCHIVE="qrcodegen-v${QRCODEGEN_VERSION}.tar.gz"
QRCODEGEN_URL="https://github.com/nayuki/QR-Code-generator/archive/refs/tags/v${QRCODEGEN_VERSION}.tar.gz"
QRCODEGEN_SHA256="2ec0a4d33d6f521c942eeaf473d42d5fe139abcfa57d2beffe10c5cf7d34ae60"
QRCODEGEN_DIR="$DOWNLOAD_DIR/QR-Code-generator-${QRCODEGEN_VERSION}"

mkdir -p "$DOWNLOAD_DIR"

if [[ ! -s "$DOWNLOAD_DIR/$QRCODEGEN_ARCHIVE" ]]; then
  curl -fL --retry 3 --retry-delay 2 "$QRCODEGEN_URL" -o "$DOWNLOAD_DIR/$QRCODEGEN_ARCHIVE"
fi

actual_sha="$(shasum -a 256 "$DOWNLOAD_DIR/$QRCODEGEN_ARCHIVE" | awk '{print $1}')"
if [[ "$actual_sha" != "$QRCODEGEN_SHA256" ]]; then
  echo "QR Code Generator checksum mismatch." >&2
  echo "Expected: $QRCODEGEN_SHA256" >&2
  echo "Actual:   $actual_sha" >&2
  exit 1
fi

if [[ ! -f "$QRCODEGEN_DIR/cpp/qrcodegen.cpp" || ! -f "$QRCODEGEN_DIR/cpp/qrcodegen.hpp" ]]; then
  rm -rf "$QRCODEGEN_DIR"
  tar -xzf "$DOWNLOAD_DIR/$QRCODEGEN_ARCHIVE" -C "$DOWNLOAD_DIR"
fi

test -f "$QRCODEGEN_DIR/cpp/qrcodegen.cpp"
test -f "$QRCODEGEN_DIR/cpp/qrcodegen.hpp"
echo "Build dependencies ready in $DOWNLOAD_DIR"
