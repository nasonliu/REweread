import fs from 'node:fs';

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

const raster = read('apps/weread-move/lib/native_raster.lua');
const app = read('apps/weread-move/native_app.lua');
const runner = read('tests/run-all.mjs');

assert(raster.includes('function NativeRaster:draw_footer_text'), 'native raster must expose a footer text helper');
assert(raster.includes('footer_font:measure_text'), 'native reader footer must center page text with real font metrics');
assert(raster.includes('footer_font:draw_text'), 'native reader footer must draw page text through FreeType');
assert(raster.includes('footerGlyphs'), 'native reader must report footer glyph rendering count');
assert(app.includes('footer_glyphs = page_render.footerGlyphs'), 'native app must track footer glyph count');
assert(app.includes('print("footerGlyphs="'), 'native app must print footer glyph count');
assert(!raster.includes('marker_w'), 'native reader footer must not use the old black marker bar');
assert(!raster.includes('self.height - 16, marker_w, 5'), 'native reader footer must not draw a black rectangle as the page number');
assert(runner.includes('validate-native-reader-footer.mjs'), 'run-all must include native reader footer validation');

console.log('native reader footer ok');
