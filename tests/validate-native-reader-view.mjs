import fs from 'node:fs';

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const opener = read('apps/weread-move/lib/book_opener.lua');
const manager = read('apps/weread-move/lib/download_manager.lua');
const view = read('apps/weread-move/views/reader_view.lua');
const app = read('apps/weread-move/app.lua');
const runner = read('tests/run-all.mjs');

assert(!opener.includes('apps/reader/readerui'), 'book opener must not depend on KOReader ReaderUI');
assert(opener.includes('open_native_chapter'), 'book opener must open cached/native chapter content');
assert(opener.includes('on_open_reader'), 'book opener must delegate display to native reader callback');
assert(manager.includes('function DownloadManager:open_native_chapter'), 'download manager must expose native chapter opening');
assert(manager.includes('first_cached_chapter_path'), 'native open must reuse cached chapter XHTML');
assert(manager.includes('chapter_cache:write_chapter'), 'native open must cache fetched chapter XHTML');
assert(view.includes('ReaderDocument.paginate'), 'reader view must paginate via native reader document');
assert(view.includes('function ReaderView:nextPage'), 'reader view must support next page');
assert(view.includes('function ReaderView:prevPage'), 'reader view must support previous page');
assert(view.includes('type == "image"'), 'reader view must account for image blocks');
assert(app.includes('ReaderView:new'), 'app must create the native reader view');
assert(runner.includes('validate-native-reader-view.mjs'), 'run-all must include native reader view validation');

console.log('native reader view ok');
