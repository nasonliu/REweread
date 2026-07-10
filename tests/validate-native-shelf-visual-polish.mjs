import fs from 'node:fs';

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const raster = read('apps/weread-move/lib/native_raster.lua');
const runner = read('tests/run-all.mjs');

assert(raster.includes('local max_books = math.min(9, #books)'), 'native shelf must use a 3x3 cover grid on the Move display');
assert(raster.includes('local cover_h = 136'), 'native shelf covers must keep a book-like portrait ratio');
assert(!raster.includes('line_bar(x, y + cover_h'), 'native shelf must not render placeholder title bars below covers');
assert(!raster.includes('line_bar(x + 14, y + 48'), 'native shelf must not render placeholder title bars over covers');
assert(runner.includes('validate-native-shelf-visual-polish.mjs'), 'run-all must include shelf visual polish validation');

console.log('native shelf visual polish ok');
