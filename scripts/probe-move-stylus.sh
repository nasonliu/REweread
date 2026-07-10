#!/usr/bin/env bash
set -euo pipefail

MOVE_HOST="${MOVE_HOST:-root@10.11.99.1}"
DURATION="${DURATION:-20}"
PRINT_INTERVAL="${PRINT_INTERVAL:-0.08}"
EVENT_NAME="${EVENT_NAME:-Elan marker input}"

EVENT_PATTERN="${EVENT_NAME//\"/}"

REMOTE_DEV="$(
  ssh "$MOVE_HOST" "awk '
    /^N: Name=/ { active = index(\$0, \"$EVENT_PATTERN\") > 0 }
    active && /^H: Handlers=/ {
      for (i = 1; i <= NF; i++) {
        if (\$i ~ /^event[0-9]+$/) {
          print \"/dev/input/\" \$i
          exit
        } else if (\$i ~ /^Handlers=event[0-9]+$/) {
          sub(/^Handlers=/, \"\", \$i)
          print \"/dev/input/\" \$i
          exit
        }
      }
    }
  ' /proc/bus/input/devices"
)"

if [[ -z "$REMOTE_DEV" ]]; then
  echo "Could not find marker input device named: $EVENT_NAME" >&2
  ssh "$MOVE_HOST" "cat /proc/bus/input/devices" >&2
  exit 1
fi

echo "host=$MOVE_HOST"
echo "marker_device=$REMOTE_DEV"
echo "duration=${DURATION}s"
echo "print_interval=${PRINT_INTERVAL}s"
echo "请现在用笔尖在设备屏幕上划几下；如果底层笔输入正常，这里会打印 x/y/pressure。"

set +e
ssh "$MOVE_HOST" "cat '$REMOTE_DEV' & reader_pid=\$!; sleep '$DURATION'; kill \$reader_pid 2>/dev/null || true; wait \$reader_pid 2>/dev/null || true" | DURATION="$DURATION" PRINT_INTERVAL="$PRINT_INTERVAL" DEVICE="$REMOTE_DEV" python3 -c '
import os
import select
import struct
import sys
import time

duration = float(os.environ.get("DURATION", "20"))
print_interval = float(os.environ.get("PRINT_INTERVAL", "0.08"))
device = os.environ.get("DEVICE", "")
event_struct = struct.Struct("<qqHHi")
deadline = time.monotonic() + duration + 2.0
buf = b""
state = {
    "x": None,
    "y": None,
    "pressure": 0,
    "touch": 0,
    "tool_pen": 0,
    "distance": None,
}
dirty = False
events = 0
reports = 0
printed = 0
first_report = None
last_print = 0.0
last_touch = None
last_tool_pen = None

KEY_NAMES = {
    320: "BTN_TOOL_PEN",
    321: "BTN_TOOL_RUBBER",
    330: "BTN_TOUCH",
    331: "BTN_STYLUS",
    332: "BTN_STYLUS2",
}
ABS_NAMES = {
    0: "ABS_X",
    1: "ABS_Y",
    24: "ABS_PRESSURE",
    25: "ABS_DISTANCE",
}

print(f"listening device={device}", flush=True)

while time.monotonic() < deadline:
    timeout = max(0.0, min(0.25, deadline - time.monotonic()))
    readable, _, _ = select.select([sys.stdin.buffer], [], [], timeout)
    if not readable:
        continue

    chunk = os.read(sys.stdin.fileno(), event_struct.size * 64)
    if not chunk:
        break
    buf += chunk

    while len(buf) >= event_struct.size:
        raw = buf[:event_struct.size]
        buf = buf[event_struct.size:]
        sec, usec, typ, code, value = event_struct.unpack(raw)
        events += 1

        if typ == 1:
            if code == 320:
                state["tool_pen"] = value
                dirty = True
            elif code == 330:
                state["touch"] = value
                dirty = True
            elif code in KEY_NAMES:
                print(f"key {KEY_NAMES[code]}={value}", flush=True)
                dirty = True
        elif typ == 3:
            if code == 0:
                state["x"] = value
                dirty = True
            elif code == 1:
                state["y"] = value
                dirty = True
            elif code == 24:
                state["pressure"] = value
                dirty = True
            elif code == 25:
                state["distance"] = value
                dirty = True
            elif code in ABS_NAMES:
                print(f"abs {ABS_NAMES[code]}={value}", flush=True)
                dirty = True
        elif typ == 0 and code == 0 and dirty:
            now = time.monotonic()
            if first_report is None:
                first_report = now
            reports += 1
            elapsed = now - first_report
            x = state.get("x")
            y = state.get("y")
            pressure = state.get("pressure")
            touch = state.get("touch")
            tool_pen = state.get("tool_pen")
            distance = state.get("distance")
            should_print = (
                printed == 0
                or now - last_print >= print_interval
                or touch != last_touch
                or tool_pen != last_tool_pen
            )
            if should_print:
                print(
                    "report "
                    f"t={elapsed:6.3f}s "
                    f"x={x} y={y} "
                    f"pressure={pressure} "
                    f"touch={touch} tool_pen={tool_pen} "
                    f"distance={distance}",
                    flush=True,
                )
                printed += 1
                last_print = now
                last_touch = touch
                last_tool_pen = tool_pen
            dirty = False

print(f"summary events={events} reports={reports} printed={printed}", flush=True)
if reports == 0:
    print("NO_STYLUS_REPORTS: no marker reports were received during the probe window.", flush=True)
    sys.exit(2)
'
status=${PIPESTATUS[1]}
set -e

exit "$status"
