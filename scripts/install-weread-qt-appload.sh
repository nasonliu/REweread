#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MOVE_HOST="${MOVE_HOST:-root@10.11.99.1}"
REMOTE_DIR="${REMOTE_DIR:-/home/root/weread-qt}"
APPLOAD_DIR="${APPLOAD_DIR:-/home/root/xovi/exthome/appload/weread-move}"
LOCAL_BIN="$ROOT_DIR/apps/weread-qt/build/rm_weread_qt"
SCP=(scp -O)

if [[ ! -x "$LOCAL_BIN" ]]; then
  echo "Missing built app: $LOCAL_BIN" >&2
  echo "Run scripts/build-weread-qt.sh first." >&2
  exit 1
fi

for font in \
  "$ROOT_DIR/downloads/fonts/stage/wqy-microhei/wqy-microhei.ttc" \
  "$ROOT_DIR/downloads/fonts/stage/wqy-zenhei/wqy-zenhei.ttc" \
  "$ROOT_DIR/downloads/fonts/stage/lxgw-wenkai/lxgw-wenkai.ttf"; do
  if [[ ! -s "$font" ]]; then
    echo "Missing font dependency: $font" >&2
    echo "Run scripts/download-reader-fonts.sh first." >&2
    exit 1
  fi
done

ssh "$MOVE_HOST" 'set -eu
  test "$(uname -m)" = aarch64
  test -x /home/root/xovi/xovi.so
  test -d /home/root/xovi/services/xochitl.service
  test -d /home/root/xovi/exthome/appload
  test -x /home/root/xovi/exthome/appload/koreader/luajit
  test -f /home/root/xovi/exthome/appload/koreader/plugins/weread.koplugin/lib/client.lua
  test -f /home/root/xovi/exthome/appload/koreader/plugins/weread.koplugin/lib/content.lua
  test -f /home/root/xovi/exthome/appload/koreader/plugins/weread.koplugin/lib/cookie.lua
'

ssh "$MOVE_HOST" "mkdir -p '$REMOTE_DIR'"
"${SCP[@]}" "$LOCAL_BIN" "$MOVE_HOST:$REMOTE_DIR/rm_weread_qt"
"${SCP[@]}" "$ROOT_DIR/scripts/weread-qt-session.sh" "$MOVE_HOST:$REMOTE_DIR/weread-qt-session.sh"
ssh "$MOVE_HOST" "mkdir -p '$REMOTE_DIR/fonts'"
"${SCP[@]}" "$ROOT_DIR/downloads/fonts/stage/wqy-microhei/wqy-microhei.ttc" "$MOVE_HOST:$REMOTE_DIR/fonts/wqy-microhei.ttc"
"${SCP[@]}" "$ROOT_DIR/downloads/fonts/stage/wqy-zenhei/wqy-zenhei.ttc" "$MOVE_HOST:$REMOTE_DIR/fonts/wqy-zenhei.ttc"
"${SCP[@]}" "$ROOT_DIR/downloads/fonts/stage/lxgw-wenkai/lxgw-wenkai.ttf" "$MOVE_HOST:$REMOTE_DIR/fonts/lxgw-wenkai.ttf"
ssh "$MOVE_HOST" "rm -rf '$REMOTE_DIR/helper' && mkdir -p '$REMOTE_DIR/helper'"
"${SCP[@]}" -r "$ROOT_DIR/apps/weread-move/lib" "$MOVE_HOST:$REMOTE_DIR/helper/lib"
ssh "$MOVE_HOST" "mkdir -p '$REMOTE_DIR/helper/tools'"
"${SCP[@]}" "$ROOT_DIR/apps/weread-move/tools/account-status.lua" "$MOVE_HOST:$REMOTE_DIR/helper/tools/account-status.lua"
"${SCP[@]}" "$ROOT_DIR/apps/weread-move/tools/fetch-catalog.lua" "$MOVE_HOST:$REMOTE_DIR/helper/tools/fetch-catalog.lua"
"${SCP[@]}" "$ROOT_DIR/apps/weread-move/tools/redownload-book.lua" "$MOVE_HOST:$REMOTE_DIR/helper/tools/redownload-book.lua"
"${SCP[@]}" "$ROOT_DIR/apps/weread-move/tools/discover-books.lua" "$MOVE_HOST:$REMOTE_DIR/helper/tools/discover-books.lua"
"${SCP[@]}" "$ROOT_DIR/apps/weread-move/tools/fetch-notes.lua" "$MOVE_HOST:$REMOTE_DIR/helper/tools/fetch-notes.lua"
"${SCP[@]}" "$ROOT_DIR/apps/weread-move/tools/fetch-progress.lua" "$MOVE_HOST:$REMOTE_DIR/helper/tools/fetch-progress.lua"
"${SCP[@]}" "$ROOT_DIR/apps/weread-move/tools/refresh-detail.lua" "$MOVE_HOST:$REMOTE_DIR/helper/tools/refresh-detail.lua"
"${SCP[@]}" "$ROOT_DIR/apps/weread-move/tools/refresh-shelf.lua" "$MOVE_HOST:$REMOTE_DIR/helper/tools/refresh-shelf.lua"
"${SCP[@]}" "$ROOT_DIR/apps/weread-move/tools/login-qr.lua" "$MOVE_HOST:$REMOTE_DIR/helper/tools/login-qr.lua"
"${SCP[@]}" "$ROOT_DIR/apps/weread-move/tools/logout.lua" "$MOVE_HOST:$REMOTE_DIR/helper/tools/logout.lua"
"${SCP[@]}" "$ROOT_DIR/apps/weread-move/tools/renew-cookie.lua" "$MOVE_HOST:$REMOTE_DIR/helper/tools/renew-cookie.lua"
"${SCP[@]}" "$ROOT_DIR/apps/weread-move/tools/sync-progress.lua" "$MOVE_HOST:$REMOTE_DIR/helper/tools/sync-progress.lua"

ssh "$MOVE_HOST" "REMOTE_DIR='$REMOTE_DIR' APPLOAD_DIR='$APPLOAD_DIR' sh -s" <<'REMOTE'
set -eu

chmod +x "$REMOTE_DIR/weread-qt-session.sh"
rm -rf /home/root/xovi/exthome/appload/weread-qt
rm -rf "$APPLOAD_DIR"
mkdir -p "$APPLOAD_DIR"

cat >"$APPLOAD_DIR/external.manifest.json" <<EOF
{
  "name": "微信读书",
  "desc": "微信读书",
  "author": "Codex",
  "version": "0.1.0",
  "entry": "launch-weread-qt.sh",
  "application": "launch-weread-qt.sh",
  "environment": {
    "QTFB_SHIM_MODEL": "false"
  },
  "qtfb": true
}
EOF

cat >"$APPLOAD_DIR/launch-weread-qt.sh" <<EOF
#!/bin/sh
set -eu
LOG=/tmp/rm-weread-qt-launcher.log
systemctl stop rm-weread-qt.service rm-weread-smoke.service >/dev/null 2>&1 || true
systemctl reset-failed rm-weread-qt.service rm-weread-smoke.service >/dev/null 2>&1 || true
pids="\$(pidof rm_weread_qt 2>/dev/null || true)"
[ -z "\$pids" ] || kill \$pids 2>/dev/null || true
for _ in 1 2 3 4 5; do
  pidof rm_weread_qt >/dev/null 2>&1 || break
  sleep 1
done
pids="\$(pidof rm_weread_qt 2>/dev/null || true)"
[ -z "\$pids" ] || kill -9 \$pids 2>/dev/null || true
systemd-run --unit=rm-weread-qt --collect --property=Restart=no \\
  env REMOTE_DIR="$REMOTE_DIR" "$REMOTE_DIR/weread-qt-session.sh" >>"\$LOG" 2>&1 || true
for _ in 1 2 3 4 5 6 7 8 9 10; do
  pidof rm_weread_qt >/dev/null 2>&1 && exit 0
  sleep 1
done
exit 0
EOF

chmod +x "$APPLOAD_DIR/launch-weread-qt.sh"
REMOTE

"${SCP[@]}" "$ROOT_DIR/apps/weread-qt/icon.png" "$MOVE_HOST:$APPLOAD_DIR/icon.png"
ssh "$MOVE_HOST" "rm -rf /home/root/xovi/exthome/appload/weread-move-system"
ssh "$MOVE_HOST" "systemctl disable xovi-appload.service >/dev/null 2>&1 || true; rm -f /etc/systemd/system/xovi-appload.service /etc/systemd/system/multi-user.target.wants/xovi-appload.service /home/root/xovi/xovi-appload.service; systemctl daemon-reload >/dev/null 2>&1 || true"
ssh "$MOVE_HOST" "nohup /home/root/xovi/start >/tmp/rm-weread-qt-appload-refresh.log 2>&1 </dev/null &"
"$ROOT_DIR/scripts/install-xovi-autostart.sh"

echo "Installed AppLoad entry at $APPLOAD_DIR"
echo "Installed persistent XOVI AppLoad startup through xochitl.service drop-in."
