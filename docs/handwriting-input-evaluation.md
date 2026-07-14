# Chinese handwriting input evaluation

## Recommendation

Use a separate handwriting pad only for text fields, collect fresh pen
strokes in memory, and show ranked candidates for explicit user selection.
Do not reuse reader annotation strokes or `reader-strokes.json`.

The best recognition technology evaluated is Google ML Kit Digital Ink: it
recognizes vector strokes directly, can use writing-area/context metadata, and
runs offline. It cannot run directly in the current Qt/Linux application,
because the supported client platforms are Android and iOS. Therefore it is a
good optional companion/LAN bridge, but not the first built-in Move feature.

For a Move-native first version, use a configurable HTTPS OCR adapter with no
provider enabled by default. Render only the temporary handwriting pad to a
high-resolution monochrome PNG when the user presses **Recognize**, then show
the response as uncommitted candidates. The first adapters worth testing are:

1. Azure Vision Read: explicitly supports Simplified Chinese handwriting.
2. Baidu OCR handwriting recognition: a China-focused dedicated handwriting
   endpoint.
3. A self-hosted PaddleOCR service on the user's LAN: Apache-2.0 source,
   suitable for a privacy-first option, but it is raster OCR and must be
   measured with actual Move handwriting before calling it high accuracy.

Tencent Cloud's dedicated general handwriting endpoint is not a default
choice: Tencent marks it as an older service and recommends another endpoint.

## Required boundaries

- Handwriting input is opt-in per text field. Password fields remain keyboard
  only and never enable cloud recognition.
- Strokes are held only for the active handwriting pad and cleared after
  cancel, commit, field change, app exit, or a short inactivity timeout.
- A request contains only pad pixels and optional writing-area dimensions; it
  must never contain book content, account state, annotations, logs, cookies,
  titles, or search history.
- The UI names the selected provider and states that the drawn text leaves the
  device before each cloud request. No automatic background upload.
- Provider credentials are user-supplied, stored outside Git with mode 0600,
  and never placed in command lines, logs, JSON status, screenshots, or error
  messages.
- The response is never auto-committed. Present at least the best candidates,
  plus clear/cancel/retry actions.

## Implementation seam

`StylusStore` already emits `stylusPressed`, `stylusMoved`, and
`stylusReleased` with coordinates and pressure. Add a new handwriting-pad
state object instead of extending `currentStrokePoints`, which belongs to the
reader annotation workflow. The pad should preserve ordered strokes and a
monotonic timestamp. This keeps a future ML Kit bridge compatible with its
vector Ink model, while the OCR adapters receive a rasterized copy.

The bridge protocol should be narrow and provider-neutral:

```text
POST /recognize
Content-Type: image/png
X-Writing-Area: width,height

{ "candidates": ["候选一", "候选二"], "provider": "..." }
```

Do not implement or enable an adapter until a user chooses a provider and its
privacy/cost trade-off. Before shipping, test at least 100 representative
single-line samples from multiple writers on a real Move, record top-1/top-3
accuracy and latency locally, and reject the adapter if it changes the
existing pen annotation or page-turn behavior.

## Sources

- Google ML Kit Digital Ink: <https://developers.google.com/ml-kit/vision/digital-ink-recognition>
- Google ML Kit writing-area/context guidance: <https://developers.google.com/ml-kit/vision/digital-ink-recognition/android>
- Azure Vision Read language support: <https://learn.microsoft.com/en-us/azure/ai-services/computer-vision/language-support>
- Baidu OCR product documentation: <https://ai.baidu.com/ai-doc/index/OCR>
- PaddleOCR: <https://github.com/PaddlePaddle/PaddleOCR>
- Tencent Cloud General Handwriting OCR: <https://cloud.tencent.com/document/api/866/36212>
