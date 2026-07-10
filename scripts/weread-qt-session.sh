#!/bin/sh
set -eu

REMOTE_DIR="${REMOTE_DIR:-/home/root/weread-qt}"
RUN_SECONDS="${RUN_SECONDS:-0}"
SELFTEST_MODE="${SELFTEST_MODE:-}"
POWER_DRY_RUN="${POWER_DRY_RUN:-0}"
APP_BIN="$REMOTE_DIR/rm_weread_qt"
OUT_LOG="${OUT_LOG:-/tmp/rm-weread-qt.out}"
ERR_LOG="${ERR_LOG:-/tmp/rm-weread-qt.err}"
SESSION_LOG="${SESSION_LOG:-/tmp/rm-weread-qt-session.log}"
APP_STARTED=0
DEPLOY_LOCK_NAME="rm-weread-deploy"

timestamp() {
  date '+%Y-%m-%dT%H:%M:%S%z'
}

wait_for_exit() {
  seconds="${1:-2}"
  while [ "$seconds" -gt 0 ] 2>/dev/null; do
    if ! process_is_running; then
      return 0
    fi
    sleep 1
    seconds=$((seconds - 1))
  done
  return 1
}

process_is_running() {
  if [ -z "${APP_PID:-}" ] || [ ! -r "/proc/$APP_PID/stat" ]; then
    return 1
  fi
  state="$(awk '{print $3}' "/proc/$APP_PID/stat" 2>/dev/null || true)"
  [ "$state" != "Z" ]
}

release_deploy_lock() {
  if grep -q "$DEPLOY_LOCK_NAME" /sys/power/wake_lock 2>/dev/null; then
    printf '%s' "$DEPLOY_LOCK_NAME" > /sys/power/wake_unlock 2>/dev/null || true
  fi
}

release_app_wake_locks() {
  printf '%s' 'rm-were' > /sys/power/wake_unlock 2>/dev/null || true
  printf '%s' 'rm-weread-qt' > /sys/power/wake_unlock 2>/dev/null || true
}

cleanup() {
    if [ -n "${APP_PID:-}" ]; then
        if process_is_running; then
      kill -TERM "$APP_PID" 2>/dev/null || true
      wait_for_exit 2 || kill -KILL "$APP_PID" 2>/dev/null || true
        fi
        wait "$APP_PID" 2>/dev/null || true
    fi
  if [ "${APP_STARTED:-0}" != "1" ]; then
    return 0
  fi
  release_app_wake_locks
  systemctl reset-failed xochitl 2>/dev/null || true
  if [ -x /home/root/xovi/start ]; then
    printf '%s Restoring xochitl through XOVI\n' "$(timestamp)" >>"$SESSION_LOG"
    /home/root/xovi/start >>"$SESSION_LOG" 2>&1 || systemctl start xochitl 2>/dev/null || true
  else
    printf '%s Restoring xochitl through systemctl\n' "$(timestamp)" >>"$SESSION_LOG"
    systemctl start xochitl 2>/dev/null || true
  fi
  release_deploy_lock
}

trap cleanup EXIT INT TERM

cd "$REMOTE_DIR"
chmod +x "$APP_BIN"
if [ -f /home/root/.local/share/rm-weread/session.json ]; then
  chmod 0600 /home/root/.local/share/rm-weread/session.json
fi
if [ -w /etc/pm/sleep.wakesrc ] && ! grep -qx 'gpio-hall-sensors' /etc/pm/sleep.wakesrc 2>/dev/null; then
  printf '%s\n' 'gpio-hall-sensors' >> /etc/pm/sleep.wakesrc
fi
rm -f "$OUT_LOG" "$ERR_LOG"
{
  printf '%s start remote_dir=%s run_seconds=%s selftest=%s\n' "$(timestamp)" "$REMOTE_DIR" "$RUN_SECONDS" "$SELFTEST_MODE"
} >>"$SESSION_LOG"

systemctl stop --no-block xochitl 2>>"$SESSION_LOG" || systemctl stop xochitl 2>>"$SESSION_LOG" || true
for _ in 1 2 3 4 5 6 7 8 9 10 11 12; do
  state="$(systemctl is-active xochitl 2>/dev/null || true)"
  [ "$state" != "active" ] && [ "$state" != "activating" ] && [ "$state" != "deactivating" ] && break
  sleep 1
done
printf '%s xochitl-state-before-app=%s\n' "$(timestamp)" "$(systemctl is-active xochitl 2>/dev/null || true)" >>"$SESSION_LOG"
pids="$(pidof rm_weread_qt 2>/dev/null || true)"
if [ -n "$pids" ]; then
  kill $pids 2>/dev/null || true
  sleep 1
fi
QT_QUICK_BACKEND=epaper RM_WEREAD_QT_SELFTEST="$SELFTEST_MODE" RM_WEREAD_POWER_DRY_RUN="$POWER_DRY_RUN" "$APP_BIN" -platform epaper >"$OUT_LOG" 2>"$ERR_LOG" &
APP_PID="$!"
APP_STARTED=1

if [ "$POWER_DRY_RUN" != "1" ]; then
  for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
    grep -q 'rm-weread-qt' /sys/power/wake_lock 2>/dev/null && break
    process_is_running || break
    sleep 0.1
  done
  release_deploy_lock
fi

if [ "$RUN_SECONDS" -gt 0 ] 2>/dev/null; then
  elapsed=0
  while [ "$elapsed" -lt "$RUN_SECONDS" ]; do
    if ! process_is_running; then
      APP_STATUS=0
      wait "$APP_PID" || APP_STATUS="$?"
      APP_PID=""
      printf '%s timed-run app-exit status=%s elapsed=%s\n' "$(timestamp)" "$APP_STATUS" "$elapsed" >>"$SESSION_LOG"
      exit "$APP_STATUS"
    fi
    sleep 1
    elapsed=$((elapsed + 1))
  done
  printf '%s timed-run elapsed seconds=%s\n' "$(timestamp)" "$RUN_SECONDS" >>"$SESSION_LOG"
else
  APP_STATUS=0
  wait "$APP_PID" || APP_STATUS="$?"
  printf '%s app-exit status=%s\n' "$(timestamp)" "$APP_STATUS" >>"$SESSION_LOG"
fi
