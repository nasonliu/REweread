import fs from 'node:fs';

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const cover = read('apps/weread-move/lib/native_cover_image.lua');
const raster = read('apps/weread-move/lib/native_raster.lua');
const app = read('apps/weread-move/native_app.lua');
const runner = read('tests/run-all.mjs');

assert(cover.includes('function NativeImage.open'), 'native cover image must expose open');
assert(cover.includes('ffi/loadlib'), 'native cover image must install KOReader ffi loadlib compatibility');
assert(cover.includes('tj3Decompress8'), 'native cover image must decode cached JPEG covers through TurboJPEG');
assert(!cover.includes('ffi/jpeg'), 'native cover image must not require KOReader JPEG wrapper');
assert(cover.includes('function NativeImage.sample'), 'native cover image must expose RGB sampling');
assert(!cover.includes('require("runtime")'), 'native cover image must not require KOReader runtime');
assert(!cover.includes('require("device")'), 'native cover image must not require KOReader device');
assert(!cover.includes('ui/'), 'native cover image must not use KOReader UI widgets');
assert(raster.includes('NativeImage'), 'native raster must use native cover image loader');
assert(raster.includes('draw_cover_image'), 'native raster must draw decoded cover pixels');
assert(app.includes('coverImages='), 'native app must report decoded cover image count');
assert(app.includes('coverError='), 'native app must report cover decode errors');
assert(runner.includes('validate-native-cover-image.mjs'), 'run-all must include native cover image validation');

console.log('native cover image ok');
