import fs from 'node:fs';

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const manager = read('apps/weread-move/lib/download_manager.lua');
const detail = read('apps/weread-move/views/book_detail_view.lua');
const app = read('apps/weread-move/app.lua');

assert(manager.includes('download_book_images = true'), 'full-book downloads must enable WeRead book illustrations');
assert(!manager.includes('cache.download_book_images = false'), 'download manager must not force book images off');
assert(manager.includes('imageAssets = true'), 'download status must record that EPUB images were packaged');
assert(manager.includes('status.imageAssets == true'), 'existing full EPUBs should only be reused when image assets are known packaged');
assert(manager.includes('opts.force'), 'download manager must allow explicit forced repair downloads');
assert(app.includes('status.imageAssets == true'), 'download action must re-download old no-image EPUBs');
assert(detail.includes('补下载图片'), 'book detail must offer to repair old image-less full downloads');

console.log('book images ok');
