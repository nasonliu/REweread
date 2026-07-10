import fs from 'node:fs';

const app = fs.readFileSync('apps/weread-move/app.lua', 'utf8');

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

assert(app.includes('require("book_opener")'), 'app.lua must load book_opener');
assert(app.includes('BookOpener:new'), 'app.lua must construct BookOpener');
assert(app.includes('book_opener:open(book)'), 'open_book callback must open the tapped book');
assert(app.includes('require("download_manager")'), 'app.lua must load download_manager');
assert(app.includes('DownloadManager:new'), 'app.lua must construct DownloadManager');
assert(
  !/open_book\s*=\s*function\s*\([^)]*\)\s*end\s*,/.test(app),
  'open_book callback must not be an empty placeholder',
);
assert(fs.statSync('apps/weread-move/lib/book_opener.lua').isFile(), 'book_opener.lua must exist');
assert(
  fs.statSync('apps/weread-move/lib/download_manager.lua').isFile(),
  'download_manager.lua must exist',
);

const opener = fs.readFileSync('apps/weread-move/lib/book_opener.lua', 'utf8');
assert(
  opener.includes('download_manager:open_native_chapter(book)') || opener.includes('self.download_manager:open_native_chapter(book)'),
  'BookOpener must delegate regular open to DownloadManager native chapter opening',
);
assert(
  app.includes('RM_WEREAD_OPEN_INDEX'),
  'app.lua must expose a smoke hook for opening a shelf item',
);

console.log('book opening ok');
