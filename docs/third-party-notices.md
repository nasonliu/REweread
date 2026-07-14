# Third-party notices

## Rime pinyin-simp lexicon

`apps/weread-qt/PinyinLexicon.js` is a mechanically generated lookup table derived from `pinyin_simp.dict.yaml` in [rime/rime-pinyin-simp](https://github.com/rime/rime-pinyin-simp), commit `0c6861ef7420ee780270ca6d993d18d4101049d0`, SHA-256 `e341598343a0f0f2035bb1aafc34a7f3bb7887deeecb3f60796262aaa2983e6b`.

The upstream repository licenses this dictionary under Apache License 2.0 and attributes its dictionary data to Android Pinyin IME under the same license. The generated file keeps its SPDX identifier and source notice. Any source or binary distribution that includes it must also provide [the complete Apache License 2.0 text](../THIRD_PARTY_LICENSES/Apache-2.0.txt) and preserve those notices.

This attribution does not change the repository's PolyForm Noncommercial license for project-owned code, nor does it resolve the separate WeRead, upstream-plugin or public-release blockers.

## Quill direct framebuffer adapter

`apps/weread-qt/direct_ink_framebuffer.*` adapts the independently authored
framebuffer-discovery and partial-refresh boundary from
[MaximeRivest/quill](https://github.com/MaximeRivest/quill), commit
`39262ee0bef69915e3ead3ac218d5973916f422a`, under the MIT License. The complete
license text is included in
[`THIRD_PARTY_LICENSES/Quill-MIT.txt`](../THIRD_PARTY_LICENSES/Quill-MIT.txt).

The proprietary device library `libqsgepaper.so` is loaded only from the user's
reMarkable system. It is not copied into this repository or a source release.
