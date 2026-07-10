#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/apps/weread-move"
MOVE_HOST="${MOVE_HOST:-root@10.11.99.1}"
APPLOAD_DIR="${APPLOAD_DIR:-/home/root/xovi/exthome/appload}"

if [[ ! "$APPLOAD_DIR" =~ ^/[A-Za-z0-9._/-]+$ || "$APPLOAD_DIR" == *..* ]]; then
  echo "Invalid APPLOAD_DIR: $APPLOAD_DIR" >&2
  exit 1
fi

REMOTE_APP_DIR="${APPLOAD_DIR%/}/weread-move"

if [[ ! -f "$APP_DIR/external.manifest.json" ]]; then
  echo "Missing app manifest: $APP_DIR/external.manifest.json" >&2
  exit 1
fi

ssh "$MOVE_HOST" "mkdir -p '$REMOTE_APP_DIR'"

rsync -az --delete \
  --exclude='.git*' \
  --exclude='logs/' \
  --exclude='state/' \
  --exclude='cache/' \
  --exclude='*.key' \
  --exclude='config.lua' \
  "$APP_DIR/" \
  "$MOVE_HOST:$REMOTE_APP_DIR/"

ssh "$MOVE_HOST" "chmod +x '$REMOTE_APP_DIR/rm-weread.sh' && chown -R root:root '$REMOTE_APP_DIR'"

echo "Synced WeRead app to $MOVE_HOST:$REMOTE_APP_DIR"
