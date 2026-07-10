# WeRead Move Native Runtime Proof

> Historical note: this proof belongs to the early Lua framebuffer prototype. The current product UI is the Qt application under `apps/weread-qt/`.

## Result

The app can render a cached WeRead shelf and a cached chapter to the AppLoad/qtfb framebuffer without calling KOReader `Runtime:init()`.

Default shelf command:

```sh
RM_WEREAD_NATIVE_SLEEP=0 /home/root/xovi/exthome/appload/weread-move/rm-weread-native.sh
cat /home/root/xovi/exthome/appload/weread-move/logs/rm-weread-native.log
```

Observed output:

```text
native_app=ok
screen=shelf
books=115
coverImages=8
coverError=missing cover
selectedBookId=<book-id>
framebuffer=954x1696x16
touchscreen=Elan touch input
```

Reader command:

```sh
RM_WEREAD_NATIVE_SCREEN=reader RM_WEREAD_NATIVE_BOOK_ID=<book-id> RM_WEREAD_NATIVE_SLEEP=0 /home/root/xovi/exthome/appload/weread-move/rm-weread-native.sh
cat /home/root/xovi/exthome/appload/weread-move/logs/rm-weread-native.log
```

Observed output:

```text
native_app=ok
screen=reader
bookId=<book-id>
chapter=/home/root/.local/share/rm-weread/books/<book-id>/chapters/<chapter>.xhtml
pages=2
page=1
fontGlyphs=197
framebuffer=954x1696x16
touchscreen=Elan touch input
```

## What This Proves

- `native_app.lua` does not require KOReader `runtime`, `device`, or `ui/*`.
- `native_framebuffer.lua` opens `/dev/fb0` under AppLoad's `qtfb-shim.so`.
- `native_input.lua` opens `/dev/input/touchscreen0` directly and identifies it as `Elan touch input`.
- `native_shelf.lua` loads the cached shelf through a pure Lua JSON fallback when KOReader JSON modules are not initialized.
- `native_cover_image.lua` decodes cached JPEG covers through TurboJPEG without requiring KOReader UI/runtime modules.
- `native_font.lua` renders real Chinese text through FreeType, preferring installed WenQuanYi fonts and falling back to LXGW/Noto candidates.
- Native reader text now wraps by measured FreeType glyph width and keeps Latin word runs together.
- Native reader page numbers are drawn as real high-contrast FreeType text instead of a black placeholder bar, and the app now reports `footerGlyphs` in its reader log.
- `native_paginator.lua` paginates with the same measured glyph widths and page-height limits used by the renderer.
- qtfb presents a 16-bit RGB565 framebuffer at 954 x 1696.
- The rendering path is:

```text
cached WeRead shelf.json
-> NativeShelf
-> NativeRaster shelf grid
-> NativeCoverImage/TurboJPEG for cached covers
-> NativeFramebuffer
-> qtfb-shim/AppLoad

cached WeRead XHTML
-> ReaderDocument
-> NativePaginator
-> NativeRaster
-> NativeFont/FreeType for real glyphs
-> NativeFramebuffer
-> qtfb-shim/AppLoad
```

The bounded input loop can run without hanging:

```sh
RM_WEREAD_NATIVE_SLEEP=0 RM_WEREAD_NATIVE_LOOP_SECONDS=2 /home/root/xovi/exthome/appload/weread-move/rm-weread-native.sh
```

## Remaining Work

- Add HarfBuzz shaping on top of the current FreeType glyph renderer for punctuation, mixed scripts, and better line layout.
- Add a font chooser. `scripts/download-reader-fonts.sh` can download WenQuanYi Micro Hei and WenQuanYi Zen Hei into `downloads/fonts/` and install them to `/home/root/.local/share/fonts/` when the Move is reachable.
- Cache missing shelf covers before rendering so every visible card uses a real cover.
- Calibrate native tap coordinates and add marker input handling for colored annotations.
- Move shelf/detail/download screens from KOReader UI widgets to the native renderer.
- Bundle or replace the KOReader-provided LuaJIT binary so the launcher no longer depends on the KOReader app directory for execution.
