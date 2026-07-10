import fs from 'node:fs';

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const raster = read('apps/weread-move/lib/native_raster.lua');
const smoke = read('apps/weread-move/tools/native-raster-smoke.lua');
const runner = read('tests/run-all.mjs');

assert(raster.includes('function NativeRaster:new'), 'native raster must expose a renderer constructor');
assert(raster.includes('function NativeRaster:write_ppm'), 'native raster must write a raster file without KOReader UI');
assert(raster.includes('function NativeRaster:draw_reader_page'), 'native raster must render reader pages');
assert(!raster.includes('require("runtime")'), 'native raster must not require KOReader runtime');
assert(!raster.includes('require("device")'), 'native raster must not require KOReader device');
assert(!raster.includes('ui/'), 'native raster must not use KOReader UI widgets');
assert(smoke.includes('NativeRaster'), 'native raster smoke must use the renderer');
assert(smoke.includes('ReaderDocument.paginate'), 'native raster smoke must render the native reader document model');
assert(runner.includes('validate-native-raster.mjs'), 'run-all must include native raster validation');

console.log('native raster ok');
