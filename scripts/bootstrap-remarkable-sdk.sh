#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SDK_VERSION="${SDK_VERSION:-5.7.119}"
SDK_VOLUME="${SDK_VOLUME:-rm_chiappa_sdk}"
SDK_DEST="${SDK_DEST:-/opt/codex/chiappa/$SDK_VERSION}"
SDK_IMAGE="${SDK_IMAGE:-python:3.12-bookworm}"
DOWNLOAD_DIR="${DOWNLOAD_DIR:-$ROOT_DIR/downloads/official-sdk}"
SDK_FILE="remarkable-production-image-${SDK_VERSION}-chiappa-public-aarch64-toolchain.sh"
SDK_URL="${SDK_URL:-https://storage.googleapis.com/remarkable-codex-toolchain/$SDK_FILE}"
SDK_SHA256="${SDK_SHA256:-d6e6512f812d1e1c8f721fe1cce957fec461434fd3bd04ce50ff6fdd5744e1ff}"

mkdir -p "$DOWNLOAD_DIR"

if [[ ! -s "$DOWNLOAD_DIR/$SDK_FILE" ]]; then
  curl -fL --retry 3 --retry-delay 2 "$SDK_URL" -o "$DOWNLOAD_DIR/$SDK_FILE"
fi

actual_sha="$(shasum -a 256 "$DOWNLOAD_DIR/$SDK_FILE" | awk '{print $1}')"
if [[ "$actual_sha" != "$SDK_SHA256" ]]; then
  echo "SDK checksum mismatch." >&2
  echo "Expected: $SDK_SHA256" >&2
  echo "Actual:   $actual_sha" >&2
  echo "Verify the current file on https://developer.remarkable.com/links before updating this script." >&2
  exit 1
fi

docker volume create "$SDK_VOLUME" >/dev/null

if docker run --rm --platform linux/arm64 \
  -v "$SDK_VOLUME:/opt/codex/chiappa" \
  "$SDK_IMAGE" \
  test -f "$SDK_DEST/environment-setup-cortexa55-remarkable-linux"; then
  echo "SDK already installed in Docker volume $SDK_VOLUME at $SDK_DEST"
  exit 0
fi

docker run --rm --platform linux/arm64 \
  -v "$SDK_VOLUME:/opt/codex/chiappa" \
  -v "$DOWNLOAD_DIR:/sdk:ro" \
  "$SDK_IMAGE" \
  "/sdk/$SDK_FILE" -y -d "$SDK_DEST"

docker run --rm --platform linux/arm64 \
  -v "$SDK_VOLUME:/opt/codex/chiappa" \
  "$SDK_IMAGE" \
  test -f "$SDK_DEST/environment-setup-cortexa55-remarkable-linux"

echo "Installed chiappa SDK $SDK_VERSION in Docker volume $SDK_VOLUME"
