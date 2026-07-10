import fs from 'node:fs';

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

const image = read('apps/weread-move/lib/native_cover_image.lua');
const raster = read('apps/weread-move/lib/native_raster.lua');
const runner = read('tests/run-all.mjs');

assert(image.includes('NativeImage'), 'native image loader should be a generic image decoder');
assert(image.includes('function NativeImage.open'), 'native image loader must expose generic open');
assert(image.includes('is_png'), 'native image loader must detect PNG assets');
assert(image.includes('load_png'), 'native image loader must load libpng when needed');
assert(image.includes('png_image_begin_read_from_memory'), 'native image loader must use libpng simplified memory API');
assert(image.includes('png_image_finish_read'), 'native image loader must decode PNG pixels');
assert(image.includes('PNG_FORMAT_RGBA'), 'native image loader must request RGBA pixels for PNG alpha handling');
assert(image.includes('flatten_rgba_to_rgb'), 'native image loader must flatten PNG alpha onto white for e-ink pages');
assert(image.includes('function NativeImage.open_png'), 'native image loader must expose PNG decode path');
assert(image.includes('function NativeImage.open_jpeg'), 'native image loader must keep JPEG decode path');
assert(raster.includes('local NativeImage = require("native_cover_image")'), 'native raster must use the generic image decoder alias');
assert(runner.includes('validate-native-image-decoders.mjs'), 'run-all must include native image decoder validation');

console.log('native image decoders ok');
