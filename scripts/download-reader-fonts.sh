#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOWNLOAD_DIR="${DOWNLOAD_DIR:-$ROOT_DIR/downloads/fonts}"
STAGE_DIR="$DOWNLOAD_DIR/stage"
MOVE_HOST="${MOVE_HOST:-root@10.11.99.1}"
REMOTE_FONT_DIR="${REMOTE_FONT_DIR:-/home/root/.local/share/fonts}"

MICROHEI_URL="https://downloads.sourceforge.net/project/wqy/wqy-microhei/0.2.0-beta/wqy-microhei-0.2.0-beta.tar.gz"
ZENHEI_URL="https://downloads.sourceforge.net/project/wqy/wqy-zenhei/0.9.45%20%28Fighting-state%20RC1%29/wqy-zenhei-0.9.45.tar.gz"
LXGW_WENKAI_COMMIT="061398910b550e1c68a302b4641aaf0e20bbf3ae"
LXGW_WENKAI_URL="https://raw.githubusercontent.com/lxgw/LxgwWenKai/$LXGW_WENKAI_COMMIT/fonts/TTF/LXGWWenKai-Regular.ttf"
MICROHEI_SHA256="2802ac8023aa36a66ea6e7445854e3a078d377ffff42169341bd237871f7213e"
ZENHEI_SHA256="e4b7e306475bf9427d1757578f0e4528930c84c44eaa3f167d4c42f110ee75d6"
LXGW_WENKAI_SHA256="39ad71264b588165b469e35e6afb162a378dacd1f95348160240ba9038ac3009"

mkdir -p "$DOWNLOAD_DIR" "$STAGE_DIR"

download_font() {
  local url="$1"
  local archive="$DOWNLOAD_DIR/${url##*/}"
  if [[ ! -s "$archive" ]]; then
    curl -fL --retry 3 --retry-delay 2 "$url" -o "$archive"
  fi
  tar -xzf "$archive" -C "$STAGE_DIR"
}

download_file_font() {
  local url="$1"
  local target="$2"
  mkdir -p "$(dirname "$target")"
  if [[ ! -s "$target" ]]; then
    curl -fL --retry 3 --retry-delay 2 "$url" -o "$target"
  fi
}

verify_sha256() {
  local file="$1"
  local expected="$2"
  local actual
  actual="$(shasum -a 256 "$file" | awk '{print $1}')"
  if [[ "$actual" != "$expected" ]]; then
    echo "Checksum mismatch for $file" >&2
    echo "Expected: $expected" >&2
    echo "Actual:   $actual" >&2
    exit 1
  fi
}

microhei_archive="$DOWNLOAD_DIR/${MICROHEI_URL##*/}"
zenhei_archive="$DOWNLOAD_DIR/${ZENHEI_URL##*/}"
wenkai_file="$STAGE_DIR/lxgw-wenkai/lxgw-wenkai.ttf"

download_font "$MICROHEI_URL"
download_font "$ZENHEI_URL"
download_file_font "$LXGW_WENKAI_URL" "$wenkai_file"

verify_sha256 "$microhei_archive" "$MICROHEI_SHA256"
verify_sha256 "$zenhei_archive" "$ZENHEI_SHA256"
verify_sha256 "$wenkai_file" "$LXGW_WENKAI_SHA256"

find "$STAGE_DIR" -type f \( -name '*.ttf' -o -name '*.ttc' -o -name '*.otf' \) -print | sort

if [[ "${INSTALL_TO_MOVE:-0}" == "1" ]]; then
  ssh "$MOVE_HOST" "mkdir -p '$REMOTE_FONT_DIR'"
  rsync -az \
    --include='*/' \
    --include='*.ttf' \
    --include='*.ttc' \
    --include='*.otf' \
    --exclude='*' \
    "$STAGE_DIR/" \
    "$MOVE_HOST:$REMOTE_FONT_DIR/"
  ssh "$MOVE_HOST" "find '$REMOTE_FONT_DIR' -maxdepth 2 -type f \( -name '*.ttf' -o -name '*.ttc' -o -name '*.otf' \) | while IFS= read -r font_path; do sha256sum \"\$font_path\"; done"
fi
