import fs from 'node:fs';

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const downloadManager = read('apps/weread-move/lib/download_manager.lua');
const bookOpener = read('apps/weread-move/lib/book_opener.lua');
const app = read('apps/weread-move/app.lua');

assert(
  downloadManager.includes('canonical_book_id'),
  'DownloadManager must use a canonical shelf bookId helper',
);
assert(
  downloadManager.includes('book.bookId or book.book_id'),
  'DownloadManager must prefer shelf bookId over reader-state book_id',
);
assert(
  downloadManager.includes('copy.book_id = book_id'),
  'DownloadManager must pin the content worker copy to the canonical bookId',
);
assert(
  bookOpener.includes('book.bookId or book.book_id'),
  'BookOpener must validate/open by canonical shelf bookId',
);
assert(
  app.includes('book.bookId or book.book_id'),
  'app.lua status/review keys must prefer canonical shelf bookId',
);

console.log('book id canonical ok');
