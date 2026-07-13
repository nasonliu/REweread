#!/usr/bin/env bash
set -euo pipefail

MOVE_HOST="${MOVE_HOST:-root@10.11.99.1}"
REMOTE_DIR="${REMOTE_DIR:-/home/root/weread-qt}"
APPLOAD_DIR="${APPLOAD_DIR:-/home/root/xovi/exthome/appload/weread-move}"
DATA_DIR="${DATA_DIR:-/home/root/.local/share/rm-weread}"
DROPIN_PATH="${DROPIN_PATH:-/usr/lib/systemd/system/xochitl.service.d/99-xovi-appload.conf}"
REMOVE_DATA="${REMOVE_DATA:-0}"
CONFIRM_REMOVE_DATA="${CONFIRM_REMOVE_DATA:-}"
DRY_RUN="${DRY_RUN:-0}"

if [[ "$REMOVE_DATA" == "1" && "$CONFIRM_REMOVE_DATA" != "DELETE-RM-WEREAD-DATA" ]]; then
  echo "Data removal requires CONFIRM_REMOVE_DATA=DELETE-RM-WEREAD-DATA." >&2
  exit 1
fi

ssh "$MOVE_HOST" \
  "REMOTE_DIR='$REMOTE_DIR' APPLOAD_DIR='$APPLOAD_DIR' DATA_DIR='$DATA_DIR' DROPIN_PATH='$DROPIN_PATH' REMOVE_DATA='$REMOVE_DATA' DRY_RUN='$DRY_RUN' sh -s" <<'REMOTE'
set -eu

show_action() {
  printf '%s\n' "$*"
}

show_action "stop rm-weread-qt.service and rm-weread-smoke.service"
show_action "remove $REMOTE_DIR and $APPLOAD_DIR"
show_action "remove $DROPIN_PATH and restore stock Xochitl startup"
if [ "$REMOVE_DATA" = "1" ]; then
  show_action "remove user data $DATA_DIR"
else
  show_action "preserve user data $DATA_DIR"
fi

if [ "$DRY_RUN" = "1" ]; then
  exit 0
fi

systemctl stop rm-weread-qt.service rm-weread-smoke.service 2>/dev/null || true
pids="$(pidof rm_weread_qt 2>/dev/null || true)"
[ -z "$pids" ] || kill $pids 2>/dev/null || true

rm -rf "$REMOTE_DIR" "$APPLOAD_DIR"
if [ "$REMOVE_DATA" = "1" ]; then
  rm -rf "$DATA_DIR"
fi

remounted_rw=0
cleanup() {
  if [ "$remounted_rw" = "1" ]; then
    sync
    mount -o remount,ro / >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

if [ -e "$DROPIN_PATH" ]; then
  mount -o remount,rw /
  remounted_rw=1
  rm -f "$DROPIN_PATH"
  sync
  mount -o remount,ro /
  remounted_rw=0
fi

systemctl daemon-reload
systemctl reset-failed xochitl 2>/dev/null || true
if [ -x /home/root/xovi/start ]; then
  /home/root/xovi/start >/tmp/rm-weread-uninstall-xochitl.log 2>&1 || systemctl start xochitl
else
  systemctl start xochitl
fi

printf 'uninstalled app=yes data_removed=%s\n' "$REMOVE_DATA"
REMOTE
