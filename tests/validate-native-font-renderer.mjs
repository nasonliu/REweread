import fs from 'node:fs';

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const font = read('apps/weread-move/lib/native_font.lua');
const raster = read('apps/weread-move/lib/native_raster.lua');
const smoke = read('apps/weread-move/tools/native-font-smoke.lua');
const runner = read('tests/run-all.mjs');

assert(font.includes('FT_Init_FreeType'), 'native font renderer must initialize FreeType directly');
assert(font.includes('FT_Select_Charmap'), 'native font renderer must select Unicode charmap');
assert(font.includes('FT_Get_Char_Index'), 'native font renderer must avoid rendering missing glyph boxes');
assert(font.includes('FT_Load_Char'), 'native font renderer must load Unicode glyphs');
assert(font.includes('FT_Set_Pixel_Sizes'), 'native font renderer must choose readable pixel sizes');
assert(font.includes('LXGWWenKai') || font.includes('NotoSansCJKsc'), 'native font renderer must prefer a CJK font');
assert(!font.includes('os.getenv("RM_WEREAD_NATIVE_FONT"),'), 'native font renderer must not put nil env values inside ipairs candidates');
assert(font.includes('function NativeFont:draw_text'), 'native font renderer must draw real text');
assert(!font.includes('require("runtime")'), 'native font renderer must not require KOReader runtime');
assert(!font.includes('require("device")'), 'native font renderer must not require KOReader device');
assert(!font.includes('ui/'), 'native font renderer must not use KOReader UI widgets');
assert(raster.includes('NativeFont'), 'native raster must use native font renderer');
assert(raster.includes('draw_text('), 'native raster must draw real text');
assert(raster.includes('fontGlyphs'), 'native raster must report glyph rendering count');
assert(smoke.includes('native-reader-font.ppm'), 'native font smoke must write a visual proof raster');
assert(smoke.includes('fontGlyphs='), 'native font smoke must report glyph count');
assert(runner.includes('validate-native-font-renderer.mjs'), 'run-all must include native font renderer validation');

console.log('native font renderer ok');
