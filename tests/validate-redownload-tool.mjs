import fs from 'node:fs';

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const tool = read('apps/weread-move/tools/redownload-book.lua');
const manager = read('apps/weread-move/lib/download_manager.lua');
const downloadStore = read('apps/weread-qt/download_store.cpp');
const shelfStore = read('apps/weread-qt/shelf_store.cpp');
const readerStore = read('apps/weread-qt/reader_store.cpp');
const runner = read('tests/run-all.mjs');

assert(tool.includes('DownloadManager'), 'redownload tool must call the standalone download manager');
assert(tool.includes('ConfigBridge'), 'redownload tool must reuse the app config bridge');
assert(tool.includes('BookStatusStore'), 'redownload tool must update the app book status store');
assert(tool.includes('manager:step_full_download'), 'redownload tool must use incremental full-book download steps');
assert(tool.includes('RM_WEREAD_FORCE'), 'redownload tool must support forced repair downloads');
assert(tool.includes('RM_WEREAD_STOP_AFTER'), 'redownload tool must support short diagnostic chapter-cache probes');
assert(tool.includes('RM_WEREAD_OPENING_PROGRESS'), 'opening-chapter downloads must consult remote progress before choosing which chapter to package');
assert(manager.includes('function DownloadManager:opening_start_index'), 'download manager must choose a useful opening chapter for partial reader entry');
assert(manager.includes('/book/getprogress'), 'download manager must use WeRead remote progress when opening a not-yet-cached book');
assert(manager.includes('first_substantive_chapter_index'), 'download manager must skip copyright/catalog front matter when there is no remote progress');
assert(manager.includes('版权信息') || manager.includes('前言'), 'opening chapter skip list must avoid generic front matter, not only literal copyright/catalog titles');
assert(downloadStore.includes('findOpeningEpub'), 'download store must distinguish stale opening EPUBs from full EPUBs');
assert(downloadStore.includes('openingChapter && !findFullEpub(bookId).isEmpty()'), 'opening-chapter flow may only short-circuit on a full EPUB, not stale opening EPUBs');
assert(!downloadStore.includes('openingChapter && !findReadableEpub(bookId).isEmpty()'), 'opening-chapter flow must not reuse stale partial EPUBs that may start at copyright');
assert(shelfStore.includes('QStringList() << QStringLiteral("*full.epub")') && !shelfStore.includes('QStringLiteral("*full.epub") << QStringLiteral("*.epub")'), 'shelf full-cache detection must not mark opening EPUBs as fully downloaded');
assert(readerStore.includes('findReadableEpub'), 'reader store may still open partial EPUBs after the download/opening flow chooses them');
assert(tool.includes('snapshot_status'), 'redownload tool must snapshot status before diagnostic probes mutate it');
assert(tool.includes('job.state == "done"'), 'redownload tool must handle already-complete cached books');
assert(tool.includes('require("koreader_paths")'), 'redownload tool must use shared KOReader path setup without runtime init');
assert(!tool.includes('require("runtime")'), 'redownload tool must not initialize KOReader runtime');
assert(!tool.includes('UIManager'), 'redownload tool must not depend on KOReader UIManager');
assert(!manager.includes('Open the KOReader WeRead plugin'), 'download errors must not send standalone-app users back to the KOReader plugin');
assert(manager.includes('请在微信读书 App 的账号页使用扫码登录'), 'download errors must point users to the app-owned QR login flow');
assert(runner.includes('validate-redownload-tool.mjs'), 'run-all must include redownload tool validation');

console.log('redownload tool ok');
