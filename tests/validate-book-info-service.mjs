import fs from 'node:fs';

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

assert(fs.statSync('apps/weread-move/lib/book_info_service.lua').isFile(), 'book_info_service.lua must exist');

const service = read('apps/weread-move/lib/book_info_service.lua');
const app = read('apps/weread-move/app.lua');

assert(service.includes('/book/info'), 'BookInfoService must call the official book info endpoint');
assert(service.includes('publisher'), 'BookInfoService must normalize publisher metadata');
assert(service.includes('intro'), 'BookInfoService must normalize introduction text');
assert(service.includes('wordCount'), 'BookInfoService must normalize word count');

assert(app.includes('require("book_info_service")'), 'app.lua must load BookInfoService');
assert(app.includes('load_book_info'), 'app.lua must load full book metadata for detail pages');
assert(app.includes('hydrate_book'), 'app.lua must merge cached metadata into the detail book object');

console.log('book info service ok');
