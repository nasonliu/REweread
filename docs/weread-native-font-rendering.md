# WeRead Move Native Font Rendering Notes

> Historical note: this document describes the early Lua framebuffer prototype. The current product UI is `apps/weread-qt/`; use this file only for font-rendering background.

## Device Constraints

- reMarkable Paper Pro Move uses a 7.3" Canvas Color display based on E Ink Gallery 3.
- The Move display is 1696 x 954 at 264 PPI and can render about 20,000 colors.
- The Move shell currently exposes no normal `/dev/fb0`; rendering must go through AppLoad/qtfb or a bundled display target.
- Color E Ink should be treated as a reflective, low-refresh display with limited color precision. Text must be high contrast and stable between refreshes.

## Rendering Recommendation

Use this stack for the independent reader:

1. HarfBuzz for shaping Unicode text into positioned glyphs.
2. FreeType for glyph rasterization.
3. Grayscale anti-aliasing, not RGB subpixel rendering.
4. E-ink controls on top of glyph output:
   - font weight / synthetic embolden,
   - alpha gamma or contrast curve,
   - optional threshold mode for small UI labels,
   - full black text by default.

Do not use ClearType-style RGB subpixel rendering as the default. FreeType documents that LCD subpixel rendering depends on a fixed color-striped pixel structure and can create color fringes when thin features are not filtered correctly. That is the wrong default for Gallery-style color paper.

For Move specifically, tune the native reader like a high-PPI grayscale reader first, then add restrained color accents. Color should identify covers, highlights, ratings, and progress states; body text remains pure black because color pigments and light gray strokes lose contrast on reflective color e-paper.

## Font Choices

Default reading font candidates:

- WenQuanYi Micro Hei for a high-contrast sans-serif default on the color e-paper panel.
- WenQuanYi Zen Hei as a broader sans-serif fallback.
- LXGW WenKai Screen / LXGW WenKai as a warmer reading mode when present on the device.
- Noto Serif CJK / Source Han Serif SC for long-form Chinese reading.
- Noto Sans CJK / Source Han Sans for UI labels.

`scripts/download-reader-fonts.sh` downloads WenQuanYi Micro Hei and WenQuanYi Zen Hei to `downloads/fonts/`. Run it with `INSTALL_TO_MOVE=1` when the device is awake to copy the fonts to `/home/root/.local/share/fonts/`.

Implementation note: ship one compact default CJK font first, then add font selection after the renderer is stable. Full CJK font files can be large, so subsetting may matter later.

## Reader Defaults

Initial native reader defaults:

- Body text: 18-22 px equivalent on current canvas scale.
- Line height: 1.55-1.75.
- Text color: pure black.
- Background: pure white.
- Synthetic embolden: on by default for native reader text.
- Alpha gamma: below 1.0 by default to darken anti-aliased edge pixels without switching to jagged 1-bit text.
- Paragraph spacing: modest, no light gray body text.
- Highlight colors: avoid low-contrast pastel-only colors; pair color fills with black underline or border on e-ink.
- UI labels: pure black, medium weight; avoid thin gray secondary text.
- Cover/title grid: preserve color covers, but render book titles and action labels separately in black instead of overlaying gray text on cover art.
- Refresh policy: page text should prefer stable full-page updates; animated transitions and opacity fades should be avoided.

## Sources Checked

- reMarkable Paper Pro Move support page: https://support.remarkable.com/s/article/About-reMarkable-Paper-Pro-Move
- reMarkable Paper Pro Move comparison page: https://remarkable.com/products/remarkable-paper/pro-move/details/compare
- FreeType subpixel rendering reference: https://freetype.org/freetype2/docs/reference/ft2-lcd_rendering.html
- HarfBuzz manual: https://harfbuzz.github.io/
- Noto CJK fonts: https://github.com/notofonts/noto-cjk
- WenQuanYi Micro Hei: https://sourceforge.net/projects/wqy/files/wqy-microhei/0.2.0-beta/
- WenQuanYi Zen Hei: https://sourceforge.net/projects/wqy/files/wqy-zenhei/
- LXGW WenKai Screen: https://github.com/lxgw/LxgwWenKai-Screen
- Source Han Sans / Serif: https://github.com/adobe-fonts/source-han-sans and https://github.com/adobe-fonts/source-han-serif
- ChillKai / ChillHuoSong: https://github.com/Warren2060/Chillkai and https://github.com/Warren2060/ChillMovableType
- KOReader user guide font weight / contrast notes: https://koreader.rocks/user_guide/
