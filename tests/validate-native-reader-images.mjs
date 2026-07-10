import fs from 'node:fs';

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

const cache = read('apps/weread-move/lib/chapter_cache.lua');
const manager = read('apps/weread-move/lib/download_manager.lua');
const raster = read('apps/weread-move/lib/native_raster.lua');
const app = read('apps/weread-move/native_app.lua');
const runner = read('tests/run-all.mjs');

assert(cache.includes('function ChapterCache:images_dir'), 'chapter cache must expose a per-book image asset directory');
assert(cache.includes('function ChapterCache:write_chapter_assets'), 'chapter cache must persist downloaded chapter image assets');
assert(cache.includes('asset.href'), 'chapter cache must preserve Content asset href paths');
assert(cache.includes('"wb"'), 'chapter cache must write image assets as binary data');
assert(manager.includes('chapter_assets'), 'download manager must keep assets returned by fetch_single_chapter_content');
assert(manager.includes('write_chapter_assets'), 'download manager must persist chapter image assets next to cached XHTML');
assert(raster.includes('function NativeRaster:resolve_reader_image_path'), 'native raster must resolve reader image src values to cached files');
assert(raster.includes('draw_reader_image'), 'native raster must draw cached reader images');
assert(raster.includes('self:draw_cover_image(image_path'), 'native reader images must use native JPEG decoding when possible');
assert(!raster.includes('self:rect(margin + 28, y + 30, self.width - margin * 2 - 56, 8, BLACK)'), 'native reader must not only draw the old image placeholder bar');
assert(app.includes('image_root = cache:images_dir(book_id)'), 'native app must pass the cached image root into the reader renderer');
assert(runner.includes('validate-native-reader-images.mjs'), 'run-all must include native reader image validation');

console.log('native reader images ok');
