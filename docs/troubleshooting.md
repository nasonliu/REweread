# Troubleshooting for agents

Use this guide after reading `AGENTS.md` and `docs/agent-handoff.md`. Commands must redact credentials and user content. The handoff records the current release baseline and known device-specific traps; this page is the shorter symptom-to-action index.

## Safe status snapshot

```bash
export MOVE_HOST=root@10.11.99.1
ssh -o ConnectTimeout=8 "$MOVE_HOST" '
  printf "os="; sed -n "s/^VERSION=//p" /etc/os-release
  printf "xochitl="; systemctl is-active xochitl 2>/dev/null || true
  printf "weread="; pidof rm_weread_qt 2>/dev/null || true
  printf "appload="; test -f /home/root/xovi/exthome/appload/weread-move/external.manifest.json && echo yes || echo no
  printf "dropin="; test -f /usr/lib/systemd/system/xochitl.service.d/99-xovi-appload.conf && echo yes || echo no
  df -h / /home
'
```

Do not read `session.json`, `config.lua` or raw network logs into the terminal.

## AppLoad icon is missing

Check the entry and injection state:

```bash
ssh "$MOVE_HOST" '
  test -f /home/root/xovi/exthome/appload/weread-move/external.manifest.json
  systemctl cat xochitl.service | sed -n "/99-xovi-appload.conf/,$p"
  pid=$(pidof xochitl 2>/dev/null | cut -d" " -f1)
  test -n "$pid" && tr "\0" "\n" </proc/$pid/environ | grep -E "LD_PRELOAD|XOVI_ROOT|QML_"
'
```

Expected Xochitl environment includes `LD_PRELOAD=/home/root/xovi/xovi.so`. If the OS was upgraded, re-check XOVI/AppLoad compatibility before reinstalling the drop-in.

## Icon needs two taps

Likely causes:

- A previous `rm_weread_qt` process is still alive.
- A transient `rm-weread-qt` systemd unit has not completed.
- The launcher exits before the application process is visible.
- Xochitl is still stopping while AppLoad tries to update its state.

Inspect:

```bash
ssh "$MOVE_HOST" 'pidof rm_weread_qt; systemctl status rm-weread-qt.service --no-pager 2>/dev/null || true; tail -80 /tmp/rm-weread-qt-launcher.log 2>/dev/null'
```

Fix the launcher lifecycle rather than adding another delay or asking the user to tap twice.

## White screen or immediate exit

```bash
ssh "$MOVE_HOST" 'tail -120 /tmp/rm-weread-qt.err 2>/dev/null; tail -120 /tmp/rm-weread-qt-session.log 2>/dev/null'
```

Check, in order:

1. Binary architecture is aarch64.
2. Device OS and SDK are compatible.
3. `/usr/lib/plugins/platforms/libepaper.so` and `/usr/lib/plugins/scenegraph/libqsgepaper.so` exist.
4. Xochitl stopped before the direct epaper process started.
5. `Main.qml` loaded successfully.
6. The session wrapper restored Xochitl after exit.

## QR scan succeeds on phone but device keeps waiting

The active flow must use:

```text
/api/auth/getLoginUid
/api/auth/getLoginInfo?uid=...&otp=
https://weread.qq.com/web/confirm?uid=...
```

Successful login may return the VID through `Set-Cookie` rather than JSON. Merge response cookies before testing for `wr_vid`. Do not log `accessToken`, `wr_skey`, Cookie headers or the actual QR UID.

After success, verify only redacted status:

```bash
ssh "$MOVE_HOST" 'cd /home/root/weread-qt && RM_WEREAD_APP_DIR=/home/root/weread-qt/helper /home/root/xovi/exthome/appload/koreader/luajit /home/root/weread-qt/helper/tools/account-status.lua'
```

Expected output says configured/done, not raw values.

## Shelf is empty or refresh never finishes

Verify that the user configured the WeRead Skill API Key and that login Cookie status is configured. Then run the shelf helper with output limited to status lines. Never dump `shelf.json` publicly because it contains the user's library.

If a QProcess helper exits neither success nor failure, add a bounded timeout and cancellation path. Do not block the QML thread waiting for network I/O.

## A new book opens at copyright instead of the first real chapter

- Fetch remote progress first when available.
- If there is no progress, choose the first readable preface/prologue/chapter, not copyright metadata.
- Download the current chapter first so the reader opens quickly.
- When the user reaches the end, enqueue and open the next chapter automatically.
- Key every cache operation by the canonical WeRead `bookId`.

## Pagination leaves large blank space

Use body chapters and test the supported matrix of font size, font weight, line spacing, paragraph spacing and margins. A normal page should fill at least about 95% of its available text rows unless it is a chapter end or image boundary.

When settings change:

1. Preserve the current `textOffset`.
2. Repaginate.
3. Locate the page containing that offset.
4. Restore the page without changing semantic reading progress.

Do not force a paragraph to stay whole if it leaves a large blank area. Split at line boundaries while preserving indentation and paragraph spacing.

## Social underline data exists but nothing is visible

Interpret WeRead offsets as chapter-relative. For each page:

1. Carry `pageStart` and `pageEnd` from pagination.
2. Intersect comment ranges with the page range.
3. Convert local text positions with `TextEdit.positionAt()` and `positionToRectangle()`.
4. Render a dashed underline.
5. Place a transparent hit area above page-turn gestures.

`count > 0, visible = 0` means data retrieval worked and range mapping is wrong. `visible > 0` with no popup means rendering or event interception is wrong.

## Comment clicks eventually freeze the app

- Load only the current page after it remains visible for 3 seconds.
- Cancel/deprioritize the previous page when the user turns.
- Reuse the on-disk cache before making a request.
- Do not start a second popup fetch while the first is unresolved.
- Bound the helper process with a timeout.
- Close the popup on outside tap and explicit close action.

Test repeated click/wait/close cycles with `scripts/test-weread-social-clicks-on-move.sh` before asking the user to repeat manual testing.

## Pen highlight is offset

Keep three coordinate spaces separate:

- raw stylus device coordinates;
- window/QML coordinates;
- text document positions and rendered rectangles.

Record the actual content rectangle after margins and overlays. Convert pen points into the text item's local coordinates, then derive text offsets using `TextEdit.positionAt()`. Persist text ranges, not only pixels, so highlights survive repagination.

Do not confuse this with social-comment underline offset; social comments start from server text ranges, not pen points.

## Page turns or buttons stop responding

Inspect QML `z` order and event acceptance. The intended priority is:

```text
modal/popup
-> settings and pen palette
-> note/comment hit regions
-> directory drawer
-> page-turn gesture area
```

Pen palette taps must consume stylus events. Page turning should use finger gestures only. Normal command buttons should support both finger and pen when the product requirement says so.

## Power button or magnetic cover does not sleep

Identify the current device input nodes before changing code:

```bash
ssh "$MOVE_HOST" 'cat /proc/bus/input/devices | sed -n "1,240p"'
```

Look for `KEY_POWER`, `SW_LID` and `SW_MACHINE_COVER`. Use dry-run logging before performing real suspend. On sleep, show the current book cover; on wake, restore the exact reader state and refresh only what is needed.

Do not write `/sys/power/state` directly. Use the official `systemctl suspend` path so the reMarkable sleep hooks can configure wake sources and tear down Wi-Fi safely. A successful `systemctl` exit only means systemd accepted the job; it does not prove the kernel entered deep sleep.

After an e-paper refresh, VPDD may remain protected for about 30 seconds. The application must locate the regulator whose `name` is `VPDD`, wait for its live `vpdd_timeout_ms` to reach zero, release its own wake lock, and then use bounded suspend retries. Do not hard-code a regulator number.

For a controlled test, unplug charging power, close the cover or tap the power key once, wait 45 to 60 seconds, and inspect the kernel journal for `PM: suspend entry (deep)` plus the final wake IRQ. A quick cover close/open during the VPDD window only cancels pending sleep; it is not evidence of deep suspend.

## Local Git or Docker becomes corrupted

If a build filled the disk, stop before retrying Git operations. Symptoms such as `bad tree object`, `packfile ... far too short`, a read-only Docker filesystem, or a build that cannot create files may share the same root cause.

1. Preserve uncommitted source files and user work.
2. Remove only known generated build output first.
3. Fully quit and restart Docker after free space is restored.
4. Re-clone the repository into a clean checkout instead of repairing a truncated Git pack in place.
5. Compare and migrate required uncommitted files individually.

Do not delete Git objects, run an aggressive prune, or replace a working directory's `.git` folder. Do not prune Docker volumes or unrelated images without explicit user approval.

## Frontlight level 0 powers off or exits

Do not treat `0` as a generic percentage write without checking the device backlight API. Verify `brightness`, `max_brightness` and `bl_power`. Keep screen power and frontlight power separate.

## Returning to stock system

The session wrapper should terminate the app, release wake locks, and restore Xochitl through XOVI. If Xochitl is not restored:

```bash
ssh "$MOVE_HOST" 'pidof rm_weread_qt >/dev/null && kill $(pidof rm_weread_qt) || true; /home/root/xovi/start || systemctl start xochitl'
```

Use this only as recovery. Fix the wrapper if normal exit does not restore the system.
