#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN_DIR="$ROOT_DIR/third_party/weread.koplugin"
MOVE_HOST="${MOVE_HOST:-root@10.11.99.1}"
KO_PLUGIN_DIR="${KO_PLUGIN_DIR:-/home/root/xovi/exthome/appload/koreader/plugins}"

if [[ ! -d "$PLUGIN_DIR" ]]; then
  echo "Missing plugin directory: $PLUGIN_DIR" >&2
  exit 1
fi

ssh "$MOVE_HOST" "mkdir -p '$KO_PLUGIN_DIR'"

rsync -az --delete \
  --exclude='.git*' \
  --exclude='config.lua' \
  "$PLUGIN_DIR/" \
  "$MOVE_HOST:$KO_PLUGIN_DIR/weread.koplugin/"

ssh "$MOVE_HOST" "chown -R root:root '$KO_PLUGIN_DIR/weread.koplugin'"

echo "Synced weread.koplugin to $MOVE_HOST:$KO_PLUGIN_DIR/weread.koplugin"
