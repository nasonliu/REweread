#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_VERSION="$(tr -d '[:space:]' <"$ROOT_DIR/VERSION")"
MOVE_HOST="${MOVE_HOST:-root@10.11.99.1}"
REMOTE_DIR="${REMOTE_DIR:-/home/root/weread-qt}"
APPLOAD_DIR="${APPLOAD_DIR:-/home/root/xovi/exthome/appload/weread-move}"
REMOTE_STAGE="${REMOTE_DIR}.installing"
REMOTE_BACKUP="${REMOTE_DIR}.previous"
APPLOAD_BACKUP="${APPLOAD_DIR}.previous"
LOCAL_BIN="$ROOT_DIR/apps/weread-qt/build/rm_weread_qt"
SCP=(scp -O)
SWAPPED=0

rollback_on_error() {
  local status=$?
  if [[ "$status" -ne 0 && "$SWAPPED" == "1" ]]; then
    echo "Install failed; restoring the previous application." >&2
    ssh "$MOVE_HOST" \
      "REMOTE_DIR='$REMOTE_DIR' REMOTE_BACKUP='$REMOTE_BACKUP' APPLOAD_DIR='$APPLOAD_DIR' APPLOAD_BACKUP='$APPLOAD_BACKUP' sh -s" <<'REMOTE' || true
set -eu
systemctl stop rm-weread-qt.service rm-weread-smoke.service 2>/dev/null || true
pids="$(pidof rm_weread_qt 2>/dev/null || true)"
[ -z "$pids" ] || kill $pids 2>/dev/null || true
rm -rf "$REMOTE_DIR" "$APPLOAD_DIR"
[ ! -d "$REMOTE_BACKUP" ] || mv "$REMOTE_BACKUP" "$REMOTE_DIR"
[ ! -d "$APPLOAD_BACKUP" ] || mv "$APPLOAD_BACKUP" "$APPLOAD_DIR"
systemctl reset-failed xochitl 2>/dev/null || true
if [ -x /home/root/xovi/start ]; then
  /home/root/xovi/start >/tmp/rm-weread-install-rollback.log 2>&1 || systemctl start xochitl 2>/dev/null || true
else
  systemctl start xochitl 2>/dev/null || true
fi
REMOTE
  fi
  exit "$status"
}
trap rollback_on_error EXIT

if [[ ! -x "$LOCAL_BIN" ]]; then
  echo "Missing built app: $LOCAL_BIN" >&2
  echo "Run scripts/build-weread-qt.sh first." >&2
  exit 1
fi

for font in \
  "$ROOT_DIR/downloads/fonts/stage/wqy-microhei/wqy-microhei.ttc" \
  "$ROOT_DIR/downloads/fonts/stage/wqy-zenhei/wqy-zenhei.ttc" \
  "$ROOT_DIR/downloads/fonts/stage/lxgw-wenkai/lxgw-wenkai.ttf" \
  "$ROOT_DIR/downloads/fonts/stage/source-han-sans-sc/source-han-sans-sc.otf" \
  "$ROOT_DIR/downloads/fonts/stage/source-han-serif-sc/source-han-serif-sc.otf" \
  "$ROOT_DIR/downloads/fonts/stage/chill-kai/chill-kai.ttf" \
  "$ROOT_DIR/downloads/fonts/stage/chill-huosong/chill-huosong.otf"; do
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

ssh "$MOVE_HOST" "rm -rf '$REMOTE_STAGE' && mkdir -p '$REMOTE_STAGE/fonts' '$REMOTE_STAGE/helper/tools'"
"${SCP[@]}" "$LOCAL_BIN" "$MOVE_HOST:$REMOTE_STAGE/rm_weread_qt"
"${SCP[@]}" "$ROOT_DIR/scripts/weread-qt-session.sh" "$MOVE_HOST:$REMOTE_STAGE/weread-qt-session.sh"
"${SCP[@]}" "$ROOT_DIR/downloads/fonts/stage/wqy-microhei/wqy-microhei.ttc" "$MOVE_HOST:$REMOTE_STAGE/fonts/wqy-microhei.ttc"
"${SCP[@]}" "$ROOT_DIR/downloads/fonts/stage/wqy-zenhei/wqy-zenhei.ttc" "$MOVE_HOST:$REMOTE_STAGE/fonts/wqy-zenhei.ttc"
"${SCP[@]}" "$ROOT_DIR/downloads/fonts/stage/lxgw-wenkai/lxgw-wenkai.ttf" "$MOVE_HOST:$REMOTE_STAGE/fonts/lxgw-wenkai.ttf"
"${SCP[@]}" "$ROOT_DIR/downloads/fonts/stage/source-han-sans-sc/source-han-sans-sc.otf" "$MOVE_HOST:$REMOTE_STAGE/fonts/source-han-sans-sc.otf"
"${SCP[@]}" "$ROOT_DIR/downloads/fonts/stage/source-han-serif-sc/source-han-serif-sc.otf" "$MOVE_HOST:$REMOTE_STAGE/fonts/source-han-serif-sc.otf"
"${SCP[@]}" "$ROOT_DIR/downloads/fonts/stage/chill-kai/chill-kai.ttf" "$MOVE_HOST:$REMOTE_STAGE/fonts/chill-kai.ttf"
"${SCP[@]}" "$ROOT_DIR/downloads/fonts/stage/chill-huosong/chill-huosong.otf" "$MOVE_HOST:$REMOTE_STAGE/fonts/chill-huosong.otf"
"${SCP[@]}" -r "$ROOT_DIR/apps/weread-move/lib" "$MOVE_HOST:$REMOTE_STAGE/helper/lib"
for tool in \
  account-status.lua \
  fetch-catalog.lua \
  redownload-book.lua \
  discover-books.lua \
  fetch-notes.lua \
  fetch-progress.lua \
  refresh-detail.lua \
  refresh-shelf.lua \
  login-qr.lua \
  logout.lua \
  renew-cookie.lua \
  sync-progress.lua; do
  "${SCP[@]}" "$ROOT_DIR/apps/weread-move/tools/$tool" "$MOVE_HOST:$REMOTE_STAGE/helper/tools/$tool"
done

SWAPPED=1
ssh "$MOVE_HOST" \
  "REMOTE_DIR='$REMOTE_DIR' REMOTE_STAGE='$REMOTE_STAGE' REMOTE_BACKUP='$REMOTE_BACKUP' APPLOAD_DIR='$APPLOAD_DIR' APPLOAD_BACKUP='$APPLOAD_BACKUP' APP_VERSION='$APP_VERSION' sh -s" <<'REMOTE'
set -eu

chmod +x "$REMOTE_STAGE/rm_weread_qt" "$REMOTE_STAGE/weread-qt-session.sh"
systemctl stop rm-weread-qt.service rm-weread-smoke.service 2>/dev/null || true
pids="$(pidof rm_weread_qt 2>/dev/null || true)"
[ -z "$pids" ] || kill $pids 2>/dev/null || true

rm -rf "$REMOTE_BACKUP"
[ ! -d "$REMOTE_DIR" ] || mv "$REMOTE_DIR" "$REMOTE_BACKUP"
mv "$REMOTE_STAGE" "$REMOTE_DIR"

rm -rf /home/root/xovi/exthome/appload/weread-qt
rm -rf "$APPLOAD_BACKUP"
[ ! -d "$APPLOAD_DIR" ] || mv "$APPLOAD_DIR" "$APPLOAD_BACKUP"
mkdir -p "$APPLOAD_DIR"

cat >"$APPLOAD_DIR/external.manifest.json" <<EOF
{
  "name": "微信读书",
  "desc": "微信读书",
  "author": "Codex",
  "version": "$APP_VERSION",
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

SWAPPED=0
trap - EXIT
echo "Installed AppLoad entry at $APPLOAD_DIR"
echo "Installed persistent XOVI AppLoad startup through xochitl.service drop-in."
