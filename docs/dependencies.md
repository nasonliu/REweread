# External dependencies

Dependencies are downloaded at build/install time or installed on the device. They are not committed to this repository.

## Build dependencies

| Dependency | Tested version | Source | Local location |
| --- | --- | --- | --- |
| Docker | 29.2.0 | https://www.docker.com/ | host installation |
| reMarkable chiappa SDK | 5.7.119, aarch64 host | https://developer.remarkable.com/links | Docker volume `rm_chiappa_sdk` |
| Qt | 6.8.2 from SDK/device | included by reMarkable SDK | SDK sysroot |
| QR Code Generator | v1.8.0 | https://github.com/nayuki/QR-Code-generator | ignored `downloads/sources/` |
| Node.js | 18+ | https://nodejs.org/ | host installation |

The official SDK URL used by `scripts/bootstrap-remarkable-sdk.sh` is:

```text
https://storage.googleapis.com/remarkable-codex-toolchain/remarkable-production-image-5.7.119-chiappa-public-aarch64-toolchain.sh
```

If reMarkable changes the link, use the official links page and update the URL and SHA-256 together. Never bypass a checksum mismatch.

## Device dependencies

| Dependency | Tested version | Source | Purpose |
| --- | --- | --- | --- |
| Developer Mode | device feature | https://developer.remarkable.com/documentation/developer-mode | SSH and custom software |
| XOVI | v19-23052026 | https://github.com/asivery/xovi | injects AppLoad into Xochitl |
| rm-xovi-extensions | v19-23052026 | https://github.com/asivery/rm-xovi-extensions | XOVI service layout |
| AppLoad | v0.5.3 | https://github.com/asivery/rm-appload/releases/tag/v0.5.3 | launcher entry |
| KOReader | v2025.10 tested | https://github.com/koreader/koreader | current LuaJIT/runtime provider |
| weread.koplugin | metadata v0.2.0 tested | https://github.com/QiuYukang/weread.koplugin | WeRead client/content/cookie modules |

AppLoad can also be installed through Vellum where compatible:

```text
https://remarkable.guide/guide/software/vellum/index.html
```

Do not blindly install the newest XOVI/AppLoad on an older device image. Their hooks track Xochitl internals and require a compatibility check after every reMarkable OS update.

## Fonts

| Font | Source | License note |
| --- | --- | --- |
| LXGW WenKai | https://github.com/lxgw/LxgwWenKai | SIL Open Font License; include license in a release package |
| WenQuanYi Micro Hei | https://sourceforge.net/projects/wqy/files/wqy-microhei/ | Apache-2.0 or GPL option; document the selected terms |
| WenQuanYi Zen Hei | https://sourceforge.net/projects/wqy/files/wqy-zenhei/ | GPL with font embedding exception; include notices |

Fonts are downloaded by `scripts/download-reader-fonts.sh` to `downloads/fonts/`. Public binary distribution must include the applicable font licenses even though font binaries are not stored in this source repository.

## WeRead API dependency

The app currently uses two service surfaces:

- WeRead Skill/gateway API with a user-bound `wrk-...` API Key for shelf, search, metadata and progress.
- Cookie-authenticated Web API for QR login, chapter content, comments, Cookie renewal and related reader data.

The API Key is obtained by the user from the WeRead mobile app's WeRead Skill settings. It is user data and must never be committed.

The Web endpoints are not a stable public SDK. Agents must expect response fields, authentication and anti-abuse controls to change. Validate an endpoint with a redacted helper before changing production code.

## Licensing boundary

The repository's own source code is released under the root MIT license. That license does not grant rights to WeRead services, book content, third-party runtimes, fonts or trademarks. Do not publish a binary release until the following are resolved:

- `weread.koplugin` redistribution permission and any derived-code review.
- QR Code Generator MIT notice in binary distributions.
- Font license notices.
- XOVI/AppLoad GPL obligations if any component is redistributed rather than installed separately.
- WeRead terms, account risk, content caching and trademark/branding review.
