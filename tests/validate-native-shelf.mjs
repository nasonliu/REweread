import fs from 'node:fs';

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const shelf = read('apps/weread-move/lib/native_shelf.lua');
const raster = read('apps/weread-move/lib/native_raster.lua');
const app = read('apps/weread-move/native_app.lua');
const smoke = read('apps/weread-move/tools/native-shelf-smoke.lua');
const runner = read('tests/run-all.mjs');

assert(shelf.includes('function NativeShelf:load'), 'native shelf must load cached shelf data');
assert(shelf.includes('ShelfCache'), 'native shelf must reuse the shared shelf cache');
assert(shelf.includes('bookId'), 'native shelf must preserve book ids for opening');
assert(shelf.includes('localCover') || shelf.includes('cover'), 'native shelf must keep cover metadata');
assert(!shelf.includes('require("runtime")'), 'native shelf must not require KOReader runtime');
assert(!shelf.includes('require("device")'), 'native shelf must not require KOReader device');
assert(!shelf.includes('ui/'), 'native shelf must not use KOReader UI widgets');
assert(raster.includes('function NativeRaster:draw_shelf'), 'native raster must render a native shelf grid');
assert(raster.includes('cover_color'), 'native raster shelf must use color cover cards');
assert(smoke.includes('NativeShelf'), 'native shelf smoke must load the cached shelf');
assert(smoke.includes('draw_shelf'), 'native shelf smoke must render the native shelf grid');
assert(smoke.includes('weread-native-shelf.ppm'), 'native shelf smoke must write a visual shelf proof');
assert(app.includes('RM_WEREAD_NATIVE_SCREEN'), 'native app must expose a native screen selector');
assert(app.includes('render_shelf'), 'native app must render shelf mode');
assert(app.includes('selectedBookId='), 'native app must report the selected shelf book id');
assert(runner.includes('validate-native-shelf.mjs'), 'run-all must include native shelf validation');

console.log('native shelf ok');
