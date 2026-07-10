#!/usr/bin/env bash
set -euo pipefail

MOVE_HOST="${MOVE_HOST:-root@10.11.99.1}"
REMOTE_DIR="${REMOTE_DIR:-/home/root/weread-qt}"
DATA_DIR="${DATA_DIR:-/home/root/.local/share/rm-weread}"
KO_DIR="${KO_DIR:-/home/root/xovi/exthome/appload/koreader}"
BOOK_ID="${BOOK_ID:-}"
BOOK_TITLE="${BOOK_TITLE:-}"

ssh_common=(
  -o ConnectTimeout=8
  -o ServerAliveInterval=10
  -o ServerAliveCountMax=3
)

ssh "${ssh_common[@]}" "$MOVE_HOST" \
  "REMOTE_DIR='$REMOTE_DIR' DATA_DIR='$DATA_DIR' KO_DIR='$KO_DIR' BOOK_ID='$BOOK_ID' BOOK_TITLE='$BOOK_TITLE' sh -s" <<'REMOTE'
set -eu

LUA="$KO_DIR/luajit"
APP="$REMOTE_DIR/helper"

ok() {
  printf 'ok %s\n' "$1"
}

warn() {
  printf 'warn %s\n' "$1"
}

fail() {
  printf 'fail %s\n' "$1"
  exit 1
}

require_file() {
  test -e "$1" || fail "missing $1"
}

redact_account_status() {
  sed \
    -e 's/"api_key":"[^"]*"/"api_key":"<redacted>"/g' \
    -e 's/"cookies":"[^"]*"/"cookies":"<redacted>"/g' \
    -e 's/"session_path":"[^"]*"/"session_path":"<path>"/g' \
    -e 's/"config_path":"[^"]*"/"config_path":"<path>"/g'
}

json_value() {
  "$LUA" - "$1" "$2" <<'LUA'
package.path = "/home/root/weread-qt/helper/lib/?.lua;" .. package.path
local Json = require("json_util")
local path, key = arg[1], arg[2]
local file = io.open(path, "r")
if not file then os.exit(1) end
local data = Json.decode(file:read("*a"))
file:close()
local value = data
for part in string.gmatch(key, "[^.]+") do
  if type(value) ~= "table" then os.exit(1) end
  value = value[part]
end
if value ~= nil then print(tostring(value)) end
LUA
}

shelf_book_count() {
  "$LUA" - "$DATA_DIR/shelf.json" <<'LUA'
package.path = "/home/root/weread-qt/helper/lib/?.lua;" .. package.path
local Json = require("json_util")
local file = io.open(arg[1], "r")
if not file then os.exit(1) end
local data = Json.decode(file:read("*a"))
file:close()
local books = type(data) == "table" and (data.books or data) or {}
print(#books)
LUA
}

pick_book() {
  "$LUA" - "$DATA_DIR/shelf.json" "$BOOK_ID" "$BOOK_TITLE" <<'LUA'
package.path = "/home/root/weread-qt/helper/lib/?.lua;" .. package.path
local Json = require("json_util")
local shelf_path, wanted_id, wanted_title = arg[1], arg[2], arg[3]
local file = io.open(shelf_path, "r")
if not file then os.exit(1) end
local data = Json.decode(file:read("*a"))
file:close()
local books = type(data) == "table" and (data.books or data) or {}
for _, book in ipairs(books) do
  local id = tostring(book.bookId or "")
  local title = tostring(book.title or "")
  if wanted_id ~= "" and id == wanted_id then
    print(id .. "\t" .. title)
    os.exit(0)
  end
  if wanted_title ~= "" and title == wanted_title then
    print(id .. "\t" .. title)
    os.exit(0)
  end
end
for _, book in ipairs(books) do
  if book.bookId then
    print(tostring(book.bookId) .. "\t" .. tostring(book.title or ""))
    os.exit(0)
  end
end
os.exit(1)
LUA
}

require_file "$LUA"
require_file "$APP/tools/account-status.lua"
require_file "$APP/tools/refresh-detail.lua"
require_file "$APP/tools/fetch-catalog.lua"
require_file "$APP/tools/discover-books.lua"
require_file "$APP/tools/logout.lua"
require_file "$APP/tools/fetch-notes.lua"
require_file "$APP/tools/fetch-progress.lua"
require_file "$APP/tools/redownload-book.lua"
require_file "$APP/tools/renew-cookie.lua"
require_file "$APP/tools/login-qr.lua"
require_file "$DATA_DIR/shelf.json"
require_file "$REMOTE_DIR/weread-qt-session.sh"

printf 'settings-panel-selftest\n'
rm -f /tmp/rm-weread-qt-selftest.out /tmp/rm-weread-qt-selftest.err /tmp/rm-weread-qt-selftest-session.log
SELFTEST_MODE=settings-panel \
  RUN_SECONDS=12 \
  REMOTE_DIR="$REMOTE_DIR" \
  OUT_LOG=/tmp/rm-weread-qt-selftest.out \
  ERR_LOG=/tmp/rm-weread-qt-selftest.err \
  SESSION_LOG=/tmp/rm-weread-qt-selftest-session.log \
  "$REMOTE_DIR/weread-qt-session.sh" >/tmp/rm-weread-qt-selftest-run.log 2>&1 || true
cat /tmp/rm-weread-qt-selftest.out 2>/dev/null || true
cat /tmp/rm-weread-qt-selftest.err 2>/dev/null || true
if grep -q 'settings-panel-selftest=ok' /tmp/rm-weread-qt-selftest.out /tmp/rm-weread-qt-selftest.err 2>/dev/null; then
  ok "settings-panel-selftest"
else
  cat /tmp/rm-weread-qt-selftest-session.log 2>/dev/null || true
  fail "settings-panel-selftest-missing"
fi

printf 'reader-open-selftest\n'
rm -f /tmp/rm-weread-qt-reader-open.out /tmp/rm-weread-qt-reader-open.err /tmp/rm-weread-qt-reader-open-session.log
SELFTEST_MODE=reader-open \
  RUN_SECONDS=35 \
  REMOTE_DIR="$REMOTE_DIR" \
  OUT_LOG=/tmp/rm-weread-qt-reader-open.out \
  ERR_LOG=/tmp/rm-weread-qt-reader-open.err \
  SESSION_LOG=/tmp/rm-weread-qt-reader-open-session.log \
  "$REMOTE_DIR/weread-qt-session.sh" >/tmp/rm-weread-qt-reader-open-run.log 2>&1 || true
cat /tmp/rm-weread-qt-reader-open.out 2>/dev/null || true
cat /tmp/rm-weread-qt-reader-open.err 2>/dev/null || true
if grep -q 'reader-open-selftest=ok' /tmp/rm-weread-qt-reader-open.out /tmp/rm-weread-qt-reader-open.err 2>/dev/null; then
  ok "reader-open-selftest"
else
  cat /tmp/rm-weread-qt-reader-open-session.log 2>/dev/null || true
  fail "reader-open-selftest-missing"
fi

printf 'reader-defaults-selftest\n'
rm -f /tmp/rm-weread-qt-reader-defaults.out /tmp/rm-weread-qt-reader-defaults.err /tmp/rm-weread-qt-reader-defaults-session.log
SELFTEST_MODE=reader-defaults \
  RUN_SECONDS=12 \
  REMOTE_DIR="$REMOTE_DIR" \
  OUT_LOG=/tmp/rm-weread-qt-reader-defaults.out \
  ERR_LOG=/tmp/rm-weread-qt-reader-defaults.err \
  SESSION_LOG=/tmp/rm-weread-qt-reader-defaults-session.log \
  "$REMOTE_DIR/weread-qt-session.sh" >/tmp/rm-weread-qt-reader-defaults-run.log 2>&1 || true
cat /tmp/rm-weread-qt-reader-defaults.out 2>/dev/null || true
cat /tmp/rm-weread-qt-reader-defaults.err 2>/dev/null || true
if grep -q 'reader-defaults-selftest=ok' /tmp/rm-weread-qt-reader-defaults.out /tmp/rm-weread-qt-reader-defaults.err 2>/dev/null; then
  ok "reader-defaults-selftest"
else
  cat /tmp/rm-weread-qt-reader-defaults-session.log 2>/dev/null || true
  fail "reader-defaults-selftest-missing"
fi

printf 'reader-layout-selftest\n'
rm -f /tmp/rm-weread-qt-reader-layout.out /tmp/rm-weread-qt-reader-layout.err /tmp/rm-weread-qt-reader-layout-session.log
SELFTEST_MODE=reader-layout \
  RUN_SECONDS=35 \
  REMOTE_DIR="$REMOTE_DIR" \
  OUT_LOG=/tmp/rm-weread-qt-reader-layout.out \
  ERR_LOG=/tmp/rm-weread-qt-reader-layout.err \
  SESSION_LOG=/tmp/rm-weread-qt-reader-layout-session.log \
  "$REMOTE_DIR/weread-qt-session.sh" >/tmp/rm-weread-qt-reader-layout-run.log 2>&1 || true
cat /tmp/rm-weread-qt-reader-layout.out 2>/dev/null || true
cat /tmp/rm-weread-qt-reader-layout.err 2>/dev/null || true
if grep -q 'reader-layout-selftest=ok' /tmp/rm-weread-qt-reader-layout.out /tmp/rm-weread-qt-reader-layout.err 2>/dev/null; then
  ok "reader-layout-selftest"
else
  cat /tmp/rm-weread-qt-reader-layout-session.log 2>/dev/null || true
  fail "reader-layout-selftest-missing"
fi

printf 'device=%s\n' "$(date -Iseconds 2>/dev/null || date)"
printf 'xochitl=%s\n' "$(systemctl is-active xochitl 2>/dev/null || true)"
printf 'weread_qt=%s\n' "$(systemctl is-active rm-weread-qt.service 2>/dev/null || true)"
printf 'appload='
ls -1 /home/root/xovi/exthome/appload 2>/dev/null | tr '\n' ' '
printf '\n'
printf 'xovi-env\n'
pid="$(pidof xochitl 2>/dev/null || true)"
if [ -n "$pid" ]; then
  tr '\0' '\n' <"/proc/$pid/environ" | grep -E 'LD_PRELOAD|XOVI_ROOT|QML_' || true
else
  warn "xochitl-not-running"
fi

export RM_WEREAD_APP_DIR="$APP"
export KO_DIR="$KO_DIR"

printf 'account\n'
"$LUA" "$APP/tools/account-status.lua" | redact_account_status
ok "account-status"

shelf_count="$(shelf_book_count)"
printf 'shelf.json books=%s bytes=' "$shelf_count"
wc -c <"$DATA_DIR/shelf.json"

cover_count="$(ls -1 "$DATA_DIR/covers" 2>/dev/null | wc -l | tr -d ' ')"
printf 'covers count=%s\n' "$cover_count"

book_row="$(pick_book)"
BOOK_ID="${book_row%%	*}"
BOOK_TITLE="${book_row#*	}"
printf 'book bookId=%s title=%s\n' "$BOOK_ID" "$BOOK_TITLE"

printf 'detail\n'
"$LUA" "$APP/tools/refresh-detail.lua" "$BOOK_ID" | sed -n '1,20p'
ok "detail"

printf 'catalog\n'
"$LUA" "$APP/tools/fetch-catalog.lua" "$BOOK_ID" "$BOOK_TITLE" | sed -n '1,12p'
ok "catalog"

printf 'discover\n'
"$LUA" "$APP/tools/discover-books.lua" recommend | sed -n '1,12p'
ok "discover"

printf 'notes\n'
"$LUA" "$APP/tools/fetch-notes.lua" book "$BOOK_ID" | sed -n '1,12p'
ok "notes"

printf 'progress\n'
"$LUA" "$APP/tools/fetch-progress.lua" "$BOOK_ID" | sed -n '1,12p'
ok "progress"

printf 'local-book\n'
if [ -d "$DATA_DIR/books/$BOOK_ID" ]; then
  find "$DATA_DIR/books/$BOOK_ID" -maxdepth 2 -type f | sed -n '1,12p'
  printf 'images-count='
  find "$DATA_DIR/books/$BOOK_ID" -type f \( -name '*.jpg' -o -name '*.jpeg' -o -name '*.png' -o -name '*.webp' \) | wc -l
else
  warn "book-cache-missing"
fi

printf 'download-helper\n'
full_epub="$(find "$DATA_DIR/books/$BOOK_ID" -maxdepth 1 -type f -name '* - full.epub' 2>/dev/null | sed -n '1p' || true)"
if [ -n "$full_epub" ]; then
  "$LUA" "$APP/tools/redownload-book.lua" "$BOOK_ID" "$BOOK_TITLE" | sed -n '1,14p'
  ok "download-helper"
else
  warn "download-helper-skipped-no-full-epub"
fi

printf 'account-tools\n'
require_file "$APP/tools/renew-cookie.lua"
require_file "$APP/tools/login-qr.lua"
ok "account-tools-deployed"

printf 'wifi\n'
wpa_cli status 2>/dev/null | grep -E '^(wpa_state|ssid|ip_address)=' || warn "wpa-status-unavailable"

printf 'frontlight\n'
for path in /sys/class/backlight/rm_frontlight/brightness /sys/class/backlight/rm_frontlight/max_brightness /sys/class/backlight/rm_frontlight/bl_power; do
  printf '%s=' "$path"
  cat "$path" 2>/dev/null || true
done

ok "device-audit"
REMOTE
