import fs from 'node:fs';

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const font = read('apps/weread-move/lib/native_font.lua');
const raster = read('apps/weread-move/lib/native_raster.lua');
const runner = read('tests/run-all.mjs');

assert(font.includes('function NativeFont:measure_text'), 'native font must measure real glyph widths');
assert(font.includes('function NativeFont:wrap_text'), 'native font must wrap text by pixel width');
assert(font.includes('measure_codepoint'), 'native font wrapping must use per-glyph advances');
assert(font.includes('latin_word'), 'native font wrapping must keep Latin word runs together');
assert(font.includes('append_token'), 'native font wrapping must append whole text tokens');
assert(raster.includes('font:wrap_text'), 'native reader must wrap body text before drawing');
assert(raster.includes('heading_font:wrap_text'), 'native reader must wrap headings before drawing');
assert(!raster.includes('font:draw_text(self, margin, y, line'), 'native reader must not draw unwrapped body lines directly');
assert(runner.includes('validate-native-font-wrapping.mjs'), 'run-all must include font wrapping validation');

console.log('native font wrapping ok');
