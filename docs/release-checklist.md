# Release checklist

The project is not releasable until every blocking item is complete.

## Repository

- [ ] `node scripts/check-repository.mjs` passes.
- [ ] `git status --short` contains only intentional source/docs changes.
- [ ] No SDK, dependency checkout, font, archive, build output or local device data is tracked.
- [ ] Root README matches the current Qt application and install path.
- [ ] The MIT license is preserved and all required third-party notices are included.
- [ ] Version and changelog are updated.
- [ ] Public history starts from a sanitized root commit; old local refs are not pushed with `--all` or `--mirror`.

## Build

- [ ] Fresh SDK bootstrap succeeds from documented URLs and checksums.
- [ ] Fresh build succeeds without relying on an existing `build/` directory.
- [ ] `node tests/run-all.mjs` passes.
- [ ] All shell scripts pass `bash -n`.
- [ ] Release binary is stripped if debug symbols are not intentionally shipped.
- [ ] Release archive has SHA-256 and a machine-readable manifest.

## Install and upgrade

- [ ] Preflight rejects the wrong architecture or unsupported OS.
- [ ] Missing XOVI, AppLoad, KOReader, plugin or fonts produces a clear message before mutation.
- [ ] Install is atomic or has rollback.
- [ ] Upgrade preserves account, cache, progress, bookmarks, highlights and settings.
- [ ] Uninstall restores stock Xochitl and removes the root drop-in.
- [ ] Data removal is a separate explicit command.
- [ ] System update recovery is documented and tested.

## Device behavior

- [ ] App launches on first tap after cold boot.
- [ ] AppLoad remains visible after a real reboot.
- [ ] Exit reliably restores the stock system.
- [ ] Wi-Fi status, connection and reconnect work.
- [ ] Frontlight levels including off work without exiting or suspending.
- [ ] Power button and magnetic cover sleep/wake work.
- [ ] Battery drain is measured during reading and sleep.
- [ ] Crash recovery leaves the device usable.

## Account and data

- [ ] New QR login completes on device after phone confirmation.
- [ ] Session file permissions are `0600`.
- [ ] Logout removes active credentials but preserves cache as documented.
- [ ] Account switching cannot expose another account's private shelf/progress/comments.
- [ ] Cookie renewal failure has a clear re-login path.
- [ ] Logs and diagnostics are redacted.

## Reading

- [ ] A new book opens at the first readable chapter.
- [ ] Existing remote and local progress restore to the same semantic text position.
- [ ] Changing font/layout preserves `textOffset`.
- [ ] Supported typography combinations fill normal body pages.
- [ ] Images turn with the page and captions stay attached.
- [ ] Table, note and backlink behavior is tested.
- [ ] Directory opens/closes by gesture and can navigate chapters.
- [ ] Next chapter downloads automatically at the boundary.
- [ ] Whole-book download reports progress and resumes safely.

## Comments and annotation

- [ ] Current-page comments load after a 3 second dwell and use cache first.
- [ ] Leaving the page cancels/deprioritizes its request.
- [ ] Dashed social underlines align with text at all supported settings.
- [ ] Comment click opens a large readable popup and never turns the page.
- [ ] Repeated comment click/wait/close cycles do not freeze.
- [ ] Stylus highlights align, survive repagination and reject finger drawing.
- [ ] Pen palette actions never turn the page.

## Public distribution

- [ ] WeRead terms/API/content/privacy risk has been reviewed.
- [ ] Branding clearly says unofficial and does not impersonate Tencent.
- [ ] reMarkable Developer Mode and warranty/security warnings are prominent.
- [ ] Support policy and compatible version matrix are published.
- [ ] No paid or broad public release occurs without the required permissions.
