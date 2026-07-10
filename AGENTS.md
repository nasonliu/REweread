# Agent Guide

This repository is operated primarily by AI coding agents. Follow this file before changing code or touching a device.

## Mission

Build and maintain an unofficial WeRead reading client for reMarkable Paper Pro Move. The product should feel like a native Chinese e-reader while preserving the device's safety, battery behavior, account data and ability to return to the stock system.

The current product is the Qt application under `apps/weread-qt/`. The Lua code under `apps/weread-move/` is both a helper layer and a legacy prototype. Do not accidentally ship or test the legacy UI as the current app.

## Non-negotiable safety rules

- Never print, copy, commit or attach API keys, Cookie values, access tokens, QR login identifiers, SSH passwords or private keys.
- Never commit a user's shelf, book files, covers, progress, comments, annotations or device logs.
- Do not put SDKs, fonts, KOReader, XOVI, AppLoad or cloned third-party repositories in Git.
- Do not delete `/home/root/.local/share/rm-weread/` unless the user explicitly requests data deletion.
- Do not log out, switch accounts, clear caches, reinstall XOVI or modify the root filesystem unless the task requires it.
- Treat `mount -o remount,rw /`, Xochitl systemd changes and device reboot as high-impact actions. Explain them before executing.
- Preserve unrelated working-tree changes.

Run `node scripts/check-repository.mjs` before and after every repository-wide task.

## Developer Mode and first SSH access

There is no separate developer account to create for this project. The user enables Developer Mode on a supported Paper Pro device. Before giving any activation or SSH instructions, the Agent must tell the user all of the following and wait for explicit confirmation:

- Enabling Developer Mode for the first time performs a factory reset and destroys unsynced local data.
- It weakens the Secure Boot trust chain and device security, and adds an unavoidable warning during boot.
- Damage caused by custom modifications may fall outside official warranty or Protection Plan support.
- The user must finish cloud sync or another backup and enable Developer Mode personally.
- The Agent will not request, echo, store or commit the device password or any private SSH key.

Official activation path:

```text
Settings -> General -> Paper Tablet -> Software -> Advanced -> Developer Mode
```

Official SSH credential path after activation:

```text
Settings -> General -> Help -> About -> Copyrights and Licenses -> General Information
```

That screen provides the current SSH username (`root` in the official documentation) and a randomly generated password. It does not provide an SSH private key. The user should enter the password directly into an interactive terminal for the first USB connection:

```bash
ssh root@10.11.99.1
```

For unattended follow-up work, ask the user to install a host-generated public key in `/home/root/.ssh/authorized_keys`; never ask them to paste the password or private key into chat. Do not use `sshpass`, password-bearing environment variables, `StrictHostKeyChecking=no`, or password-bearing command lines.

Wi-Fi SSH is off by default. Enable it only after explicit user approval with `rm-ssh-over-wlan on`, starting from the USB connection. Full user-facing instructions and official links are in the root `README.md`.

## Source of truth

| Area | Source |
| --- | --- |
| Application UI and interaction | `apps/weread-qt/Main.qml` |
| Page/comment range mapping | `apps/weread-qt/SocialAnchor.js` |
| Reader state and pagination inputs | `apps/weread-qt/reader_store.*` |
| Downloads and chapter opening | `apps/weread-qt/download_store.*` |
| Social comments and cache | `apps/weread-qt/notes_store.*` |
| Login and account lifecycle | `apps/weread-qt/account_store.*`, `apps/weread-move/tools/login-qr.lua` |
| Power/cover/frontlight/network | matching `*_store.*` files |
| WeRead API/content helpers | `apps/weread-move/lib/`, `apps/weread-move/tools/` |
| Build | `scripts/build-weread-qt.sh` |
| Install | `scripts/install-weread-qt-appload.sh` |
| Device session lifecycle | `scripts/weread-qt-session.sh` |
| Device regression checks | `scripts/verify-weread-qt-device.sh` |

`Main.qml` is currently large. Keep fixes scoped and covered by a focused validation. A future refactor may split it into components, but do not combine a behavior fix with a broad visual refactor unless requested.

## Standard workflow

1. Read the relevant source and existing tests.
2. Reproduce locally or in Docker when possible.
3. Add or update a focused validation before risky behavior changes.
4. Implement the smallest coherent fix.
5. Run `node tests/run-all.mjs` and shell syntax checks.
6. Build with the official chiappa SDK.
7. Only then deploy to a device, if the user authorized device changes.
8. Verify on a real body-text page, not a cover, copyright or title page.
9. Report exactly what was tested locally and what was tested on-device.

Static tests in `tests/` often assert source contracts. Passing them does not prove rendering, touch routing, pen coordinates, sleep/wake or network behavior.

## Device conventions

- Default USB target: `root@10.11.99.1`.
- Wi-Fi SSH must be explicitly enabled by the user; pass the current address with `MOVE_HOST`.
- Application root: `/home/root/weread-qt`.
- AppLoad entry: `/home/root/xovi/exthome/appload/weread-move`.
- User data: `/home/root/.local/share/rm-weread`.
- KOReader dependency: `/home/root/xovi/exthome/appload/koreader`.
- XOVI persistence drop-in: `/usr/lib/systemd/system/xochitl.service.d/99-xovi-appload.conf`.

Do not assume an IP address survives network changes. Do not assume the XOVI drop-in survives a system update.

## Correctness rules learned on the device

- A cached book directory must use the real WeRead `bookId`; stale IDs can open the wrong book.
- Reader progress must use a stable `textOffset`; `pageIndex` changes after repagination.
- Comment underline ranges are chapter-relative. Map them through current `pageStart/pageEnd`, then use `TextEdit.positionAt()`/`positionToRectangle()` for rendered coordinates.
- The social hit layer must be above page-turn touch areas. A comment, note link, settings control or pen palette interaction must consume the event and never turn the page.
- Stylus and finger input are different. Pen-only annotation controls must reject touch while normal buttons should accept both when requested.
- A normal page should fill almost all available text rows. Large bottom gaps are allowed at chapter ends or around images, not on every page.
- Test Chinese paragraph indentation on body text. Copyright pages are not representative.
- Images and captions belong to page flow; they cannot stay pinned while only text turns.
- Social comments should load only after the current page remains visible for 3 seconds. Cancel or deprioritize requests for pages the user has left.
- Power button and magnetic cover events are system input events (`KEY_POWER`, `SW_LID`, `SW_MACHINE_COVER`), not ordinary QML gestures.

## When a device appears frozen

1. Do not repeatedly click controls; this can queue more comment requests.
2. Read process state and redacted logs only:

   ```bash
   ssh "$MOVE_HOST" 'pidof rm_weread_qt; tail -80 /tmp/rm-weread-qt.err; tail -80 /tmp/rm-weread-qt-session.log'
   ```

3. Check whether a Lua helper is still running.
4. Check whether QML is blocked on repeated model creation or event recursion.
5. Preserve account/cache data.
6. Restore Xochitl if the app process died and the session wrapper did not recover it.

Never paste raw helper output into a public issue until it has been checked for tokens, titles and user content.

## Login work

The current web QR flow is:

```text
GET /api/auth/getLoginUid
-> display https://weread.qq.com/web/confirm?uid=...
-> GET /api/auth/getLoginInfo?uid=...&otp=
-> merge Set-Cookie and access token
-> save session with mode 0600
```

Do not reintroduce the stale `/web/login/getuid`, `/web/login/getinfo` or `/web/login/session/init` flow. Never emit the access token or Cookie header in status JSON.

## Release discipline

This is a source-available, noncommercial project under PolyForm Noncommercial 1.0.0, not an OSI-defined open-source project. Do not describe it as MIT, commercially usable or officially authorized. Do not offer paid installation, support, hardware bundles, subscriptions, ads, internal business deployments or commercial licensing.

The repository license only covers code the repository owner can license. It does not authorize WeRead APIs, content, account data, comments, trademarks or third-party dependencies. The WeRead user agreement restricts unauthorized third-party access and distribution even when no money is charged. `weread.koplugin` currently has no explicit upstream LICENSE, so redistribution or derived-code use remains a release blocker.

If anyone asks about commercial use, the Agent must say no under the current license and direct them to `docs/legal-and-commercial-use.md`. A viable commercial product requires written Tencent permission, a resolved upstream rights chain, dependency compliance, privacy/content review and a separate written license from this project's rights holder. The project currently offers no commercial license.

Before calling a build releasable:

- No ignored dependency is tracked.
- No user data or secret pattern is present.
- The repository has a clean, reproducible source build.
- The release archive contains source-built app files only, not the SDK or upstream repositories.
- Install, upgrade and uninstall are tested on a clean compatible device.
- Account data survives an upgrade and is removed only by an explicit data-removal action.
- The supported OS/XOVI/AppLoad/KOReader matrix is documented.
- Legal and trademark review is complete for any public distribution.

See `docs/release-checklist.md`.
