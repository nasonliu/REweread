#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN_DIR="$ROOT_DIR/third_party/weread.koplugin"
OUT_DIR="$ROOT_DIR/packages"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT_FILE="$OUT_DIR/weread.koplugin-$STAMP.tar.gz"

if [[ ! -d "$PLUGIN_DIR" ]]; then
  echo "Missing plugin directory: $PLUGIN_DIR" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

tar \
  --exclude='.git*' \
  --exclude='config.lua' \
  -C "$PLUGIN_DIR/.." \
  -czf "$OUT_FILE" \
  "weread.koplugin"

echo "$OUT_FILE"
