#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SDK_VOLUME="${SDK_VOLUME:-rm_chiappa_sdk}"
SDK_PATH="${SDK_PATH:-/opt/codex/chiappa/5.7.119}"
SDK_IMAGE="${SDK_IMAGE:-python:3.12-bookworm}"
BUILD_JOBS="${BUILD_JOBS:-2}"
QRCODEGEN_SOURCE_DIR="${QRCODEGEN_SOURCE_DIR:-$ROOT_DIR/downloads/sources/QR-Code-generator-1.8.0}"

"$ROOT_DIR/scripts/fetch-build-dependencies.sh"

docker run --rm --platform linux/arm64 \
  -e BUILD_JOBS="$BUILD_JOBS" \
  -e QRCODEGEN_SOURCE_DIR=/work/downloads/sources/QR-Code-generator-1.8.0 \
  -v "$SDK_VOLUME:/opt/codex/chiappa" \
  -v "$ROOT_DIR:/work" \
  -w /work/apps/weread-qt \
  "$SDK_IMAGE" \
  bash -lc "set -euo pipefail; rm -rf build; . '$SDK_PATH/environment-setup-cortexa55-remarkable-linux'; export LANG=C.UTF-8 LC_ALL=C.UTF-8; cmake -S . -B build -DQRCODEGEN_SOURCE_DIR=\"\$QRCODEGEN_SOURCE_DIR\"; cmake --build build -j\"\$BUILD_JOBS\""

echo "Built $ROOT_DIR/apps/weread-qt/build/rm_weread_qt"
