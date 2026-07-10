#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MOVE_HOST="${MOVE_HOST:-root@10.11.99.1}"
REMOTE_DIR="${REMOTE_DIR:-/home/root/weread-qt}"
CACHE_PATH="/home/root/.local/share/rm-weread/social-comments-cache.json"
BACKUP_PATH="${CACHE_PATH}.test-backup"
MISSING_MARKER="${BACKUP_PATH}.missing"
LOCAL_CACHE="$(mktemp)"
LOCAL_CLEAN="$(mktemp)"

restart_normal_app() {
  ssh "$MOVE_HOST" "pids=\"\$(pidof rm_weread_qt 2>/dev/null || true)\"; [ -z \"\$pids\" ] || kill \$pids 2>/dev/null || true; rm -f /tmp/rm-weread-qt-run.log; nohup env SELFTEST_MODE= RUN_SECONDS=0 REMOTE_DIR='$REMOTE_DIR' '$REMOTE_DIR/weread-qt-session.sh' >/tmp/rm-weread-qt-run.log 2>&1 </dev/null &"
}

restore_cache() {
  ssh "$MOVE_HOST" "if [ -f '$BACKUP_PATH' ]; then mv -f '$BACKUP_PATH' '$CACHE_PATH'; elif [ -f '$MISSING_MARKER' ]; then rm -f '$CACHE_PATH' '$MISSING_MARKER'; fi" || true
}

cleanup() {
  set +e
  restore_cache
  restart_normal_app
  rm -f "$LOCAL_CACHE" "$LOCAL_CLEAN"
}
trap cleanup EXIT

ssh "$MOVE_HOST" "rm -f '$BACKUP_PATH' '$MISSING_MARKER'; mkdir -p \"\$(dirname '$CACHE_PATH')\"; if [ -f '$CACHE_PATH' ]; then cp '$CACHE_PATH' '$BACKUP_PATH'; else touch '$MISSING_MARKER'; printf '%s' '{\"version\":1,\"contexts\":{},\"reviews\":{}}' >'$CACHE_PATH'; fi"
scp -O "$MOVE_HOST:$CACHE_PATH" "$LOCAL_CACHE" >/dev/null
jq '.reviews = {}' "$LOCAL_CACHE" >"$LOCAL_CLEAN"
scp -O "$LOCAL_CLEAN" "$MOVE_HOST:$CACHE_PATH" >/dev/null

RUN_SECONDS=90 SELFTEST_MODE=reader-social-clicks "$ROOT_DIR/scripts/run-weread-qt-on-move.sh"

SELFTEST_LOG="$(ssh "$MOVE_HOST" "cat /tmp/rm-weread-qt.err 2>/dev/null || true")"
printf '%s\n' "$SELFTEST_LOG"
if grep -q 'reader-social-clicks-selftest=fail' <<<"$SELFTEST_LOG"; then
  echo "Repeated social-comment self-test reported a failure." >&2
  exit 1
fi
if ! grep -q 'reader-social-clicks-selftest=ok' <<<"$SELFTEST_LOG"; then
  echo "Repeated social-comment self-test did not produce a success marker." >&2
  exit 1
fi

echo "Repeated social-comment device test passed."
