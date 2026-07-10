#!/usr/bin/env bash
set -euo pipefail

MOVE_HOST="${MOVE_HOST:-root@10.11.99.1}"
DROPIN_PATH="${DROPIN_PATH:-/usr/lib/systemd/system/xochitl.service.d/99-xovi-appload.conf}"

ssh "$MOVE_HOST" "DROPIN_PATH='$DROPIN_PATH' sh -s" <<'REMOTE'
set -eu

if [ ! -x /home/root/xovi/xovi.so ]; then
  echo "missing /home/root/xovi/xovi.so" >&2
  exit 1
fi

if [ ! -d /home/root/xovi/services/xochitl.service ]; then
  echo "missing /home/root/xovi/services/xochitl.service" >&2
  exit 1
fi

remounted_rw=0
cleanup() {
  if [ "$remounted_rw" = "1" ]; then
    sync
    mount -o remount,ro / >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

mount -o remount,rw /
remounted_rw=1

mkdir -p "$(dirname "$DROPIN_PATH")"
cat >"$DROPIN_PATH" <<'EOF'
[Unit]
RequiresMountsFor=/home/root/xovi

[Service]
Environment="LD_PRELOAD=/home/root/xovi/xovi.so"
Environment="XOVI_ROOT=/home/root/xovi/services/xochitl.service/"
Environment="QML_DISABLE_DISK_CACHE=1"
Environment="QML_XHR_ALLOW_FILE_WRITE=1"
Environment="QML_XHR_ALLOW_FILE_READ=1"
EOF
chmod 0644 "$DROPIN_PATH"
sync
mount -o remount,ro /
remounted_rw=0

systemctl daemon-reload
systemctl restart --no-block xochitl
sleep 4

printf 'dropin=%s\n' "$DROPIN_PATH"
systemctl cat xochitl.service | sed -n '/99-xovi-appload.conf/,$p' | sed -n '1,32p'
printf 'xochitl=%s\n' "$(systemctl is-active xochitl 2>/dev/null || true)"
pid="$(pidof xochitl 2>/dev/null | cut -d' ' -f1 || true)"
if [ -n "$pid" ]; then
  tr '\0' '\n' <"/proc/$pid/environ" | grep -E 'LD_PRELOAD|XOVI_ROOT|QML_'
else
  echo "xochitl pid missing" >&2
  exit 1
fi
REMOTE
