#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MOVE_HOST="${MOVE_HOST:-root@10.11.99.1}"
REMOTE_DIR="${REMOTE_DIR:-/home/root/weread-qt}"
RUN_SECONDS="${RUN_SECONDS:-0}"
SELFTEST_MODE="${SELFTEST_MODE:-}"
POWER_DRY_RUN="${POWER_DRY_RUN:-0}"
REMOTE_RUN_LOG="${REMOTE_RUN_LOG:-/tmp/rm-weread-qt-run.log}"
REMOTE_DONE="${REMOTE_DONE:-/tmp/rm-weread-qt-run.done}"
LOCAL_BIN="$ROOT_DIR/apps/weread-qt/build/rm_weread_qt"
SCP=(scp -O)
DEPLOY_LOCK_NAME="rm-weread-deploy"
DEPLOY_LOCK_ACQUIRED=0

release_deploy_lock_on_error() {
  if [[ "$DEPLOY_LOCK_ACQUIRED" == "1" ]]; then
    ssh -o ConnectTimeout=3 "$MOVE_HOST" "printf '%s' '$DEPLOY_LOCK_NAME' > /sys/power/wake_unlock" >/dev/null 2>&1 || true
  fi
}

trap release_deploy_lock_on_error ERR INT TERM

copy_if_size_differs() {
  local source="$1"
  local destination="$2"
  local local_size remote_size
  local_size="$(wc -c < "$source" | tr -d ' ')"
  remote_size="$(ssh "$MOVE_HOST" "wc -c < '$destination' 2>/dev/null || true" | tr -d ' ')"
  if [[ "$local_size" == "$remote_size" ]]; then
    return 0
  fi
  "${SCP[@]}" "$source" "$MOVE_HOST:$destination"
}

if [[ ! -x "$LOCAL_BIN" ]]; then
  echo "Missing built app: $LOCAL_BIN" >&2
  echo "Run scripts/build-weread-qt.sh first." >&2
  exit 1
fi

ssh "$MOVE_HOST" "printf '%s' '$DEPLOY_LOCK_NAME' > /sys/power/wake_lock; mkdir -p '$REMOTE_DIR'; systemctl stop rm-weread-qt.service rm-weread-smoke.service >/dev/null 2>&1 || true; pids=\"\$(pidof rm_weread_qt 2>/dev/null || true)\"; [ -z \"\$pids\" ] || kill \$pids 2>/dev/null || true; for _ in 1 2 3 4 5; do pidof rm_weread_qt >/dev/null 2>&1 || break; sleep 1; done; pids=\"\$(pidof rm_weread_qt 2>/dev/null || true)\"; [ -z \"\$pids\" ] || kill -9 \$pids 2>/dev/null || true; printf '%s' rm-were > /sys/power/wake_unlock 2>/dev/null || true; printf '%s' rm-weread-qt > /sys/power/wake_unlock 2>/dev/null || true"
DEPLOY_LOCK_ACQUIRED=1
"${SCP[@]}" "$LOCAL_BIN" "$MOVE_HOST:$REMOTE_DIR/rm_weread_qt"
"${SCP[@]}" "$ROOT_DIR/scripts/weread-qt-session.sh" "$MOVE_HOST:$REMOTE_DIR/weread-qt-session.sh"
ssh "$MOVE_HOST" "mkdir -p '$REMOTE_DIR/fonts'"
copy_if_size_differs "$ROOT_DIR/downloads/fonts/stage/wqy-microhei/wqy-microhei.ttc" "$REMOTE_DIR/fonts/wqy-microhei.ttc"
copy_if_size_differs "$ROOT_DIR/downloads/fonts/stage/wqy-zenhei/wqy-zenhei.ttc" "$REMOTE_DIR/fonts/wqy-zenhei.ttc"
copy_if_size_differs "$ROOT_DIR/downloads/fonts/stage/lxgw-wenkai/lxgw-wenkai.ttf" "$REMOTE_DIR/fonts/lxgw-wenkai.ttf"
ssh "$MOVE_HOST" "rm -rf '$REMOTE_DIR/helper' && mkdir -p '$REMOTE_DIR/helper'"
"${SCP[@]}" -r "$ROOT_DIR/apps/weread-move/lib" "$MOVE_HOST:$REMOTE_DIR/helper/lib"
ssh "$MOVE_HOST" "mkdir -p '$REMOTE_DIR/helper/tools'"
"${SCP[@]}" "$ROOT_DIR/apps/weread-move/tools/account-status.lua" "$MOVE_HOST:$REMOTE_DIR/helper/tools/account-status.lua"
"${SCP[@]}" "$ROOT_DIR/apps/weread-move/tools/redownload-book.lua" "$MOVE_HOST:$REMOTE_DIR/helper/tools/redownload-book.lua"
"${SCP[@]}" "$ROOT_DIR/apps/weread-move/tools/discover-books.lua" "$MOVE_HOST:$REMOTE_DIR/helper/tools/discover-books.lua"
"${SCP[@]}" "$ROOT_DIR/apps/weread-move/tools/fetch-catalog.lua" "$MOVE_HOST:$REMOTE_DIR/helper/tools/fetch-catalog.lua"
"${SCP[@]}" "$ROOT_DIR/apps/weread-move/tools/fetch-notes.lua" "$MOVE_HOST:$REMOTE_DIR/helper/tools/fetch-notes.lua"
"${SCP[@]}" "$ROOT_DIR/apps/weread-move/tools/fetch-progress.lua" "$MOVE_HOST:$REMOTE_DIR/helper/tools/fetch-progress.lua"
"${SCP[@]}" "$ROOT_DIR/apps/weread-move/tools/refresh-detail.lua" "$MOVE_HOST:$REMOTE_DIR/helper/tools/refresh-detail.lua"
"${SCP[@]}" "$ROOT_DIR/apps/weread-move/tools/refresh-shelf.lua" "$MOVE_HOST:$REMOTE_DIR/helper/tools/refresh-shelf.lua"
"${SCP[@]}" "$ROOT_DIR/apps/weread-move/tools/login-qr.lua" "$MOVE_HOST:$REMOTE_DIR/helper/tools/login-qr.lua"
"${SCP[@]}" "$ROOT_DIR/apps/weread-move/tools/logout.lua" "$MOVE_HOST:$REMOTE_DIR/helper/tools/logout.lua"
"${SCP[@]}" "$ROOT_DIR/apps/weread-move/tools/renew-cookie.lua" "$MOVE_HOST:$REMOTE_DIR/helper/tools/renew-cookie.lua"
"${SCP[@]}" "$ROOT_DIR/apps/weread-move/tools/sync-progress.lua" "$MOVE_HOST:$REMOTE_DIR/helper/tools/sync-progress.lua"

ssh "$MOVE_HOST" "chmod +x '$REMOTE_DIR/weread-qt-session.sh'"
if [[ "$RUN_SECONDS" == "0" ]]; then
  ssh -n "$MOVE_HOST" "rm -f '$REMOTE_RUN_LOG'; nohup sh -c 'SELFTEST_MODE=\"$SELFTEST_MODE\" POWER_DRY_RUN=\"$POWER_DRY_RUN\" REMOTE_DIR=\"$REMOTE_DIR\" \"$REMOTE_DIR/weread-qt-session.sh\" >\"$REMOTE_RUN_LOG\" 2>&1' >/dev/null 2>&1 </dev/null &"
  echo "Started WeRead Qt on $MOVE_HOST; remote log: $REMOTE_RUN_LOG"
else
  ssh -n "$MOVE_HOST" "rm -f '$REMOTE_RUN_LOG' '$REMOTE_DONE'; nohup sh -c 'SELFTEST_MODE=\"$SELFTEST_MODE\" POWER_DRY_RUN=\"$POWER_DRY_RUN\" RUN_SECONDS=\"$RUN_SECONDS\" REMOTE_DIR=\"$REMOTE_DIR\" \"$REMOTE_DIR/weread-qt-session.sh\" >\"$REMOTE_RUN_LOG\" 2>&1; printf \"%s\" \"\$?\" >\"$REMOTE_DONE\"' >/dev/null 2>&1 </dev/null &"
  deadline=$((RUN_SECONDS + 20))
  for _ in $(seq 1 "$deadline"); do
    if ssh -n "$MOVE_HOST" "test -f '$REMOTE_DONE'"; then
      break
    fi
    sleep 1
  done
  if ! ssh -n "$MOVE_HOST" "test -f '$REMOTE_DONE'"; then
    ssh -n "$MOVE_HOST" "pids=\"\$(pidof rm_weread_qt 2>/dev/null || true)\"; [ -z \"\$pids\" ] || kill \$pids 2>/dev/null || true; systemctl start xochitl 2>/dev/null || true; cat '$REMOTE_RUN_LOG' 2>/dev/null || true"
    echo "Timed out waiting for remote smoke session." >&2
    exit 1
  fi
  ssh -n "$MOVE_HOST" "cat '$REMOTE_RUN_LOG' 2>/dev/null || true; exit \"\$(cat '$REMOTE_DONE')\""
fi

DEPLOY_LOCK_ACQUIRED=0
trap - ERR INT TERM
