# Changelog

All notable changes to REweread are documented here.

## [1.0.0-rc.1] - 2026-07-13

First source-only release candidate of the Qt application for reMarkable Paper Pro Move.

### Added

- Native-feeling Chinese shelf, book detail, reader, table of contents and settings flows.
- Device QR login, account renewal, progress sync, chapter-first and whole-book downloads.
- Chinese typography, images and captions, notes, cached social comments and stylus highlights.
- Wi-Fi, frontlight, battery, power-button and magnetic-folio integration.
- Agent-focused setup, safety, troubleshooting, legal and user documentation.

### Fixed

- Stable `textOffset` restoration across repagination and reading-setting changes.
- Page fill, image flow, social underline mapping and touch/pen event routing.
- Deep suspend through the official Move systemd hooks, including Wi-Fi teardown, VPDD wait and bounded retry.
- Wi-Fi reconnection after resume and stock-system restoration after application exit.

### Release boundary

- This is a source-only, noncommercial, unofficial release candidate.
- No application binary, SDK, font, KOReader, XOVI, AppLoad, `weread.koplugin`, user data or book content is distributed.
- Public binary distribution remains blocked by WeRead service/rights review and unresolved upstream licensing.

[1.0.0-rc.1]: https://github.com/nasonliu/REweread/releases/tag/v1.0.0-rc.1
