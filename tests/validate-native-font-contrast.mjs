import fs from 'node:fs';

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

const font = read('apps/weread-move/lib/native_font.lua');
const raster = read('apps/weread-move/lib/native_raster.lua');
const notes = read('docs/weread-native-font-rendering.md');
const runner = read('tests/run-all.mjs');

assert(font.includes('FT_GlyphSlot_Embolden'), 'native font renderer must expose FreeType synthetic emboldening');
assert(font.includes('function NativeFont:apply_embolden'), 'native font renderer must wrap emboldening behind a safe helper');
assert(font.includes('function NativeFont:adjust_alpha'), 'native font renderer must remap glyph alpha for e-ink contrast');
assert(font.includes('alpha_floor'), 'native font renderer must support an alpha floor for faint antialiasing');
assert(font.includes('alpha_gamma'), 'native font renderer must support an alpha gamma curve');
assert(font.includes('embolden = opts.embolden ~= false'), 'native font renderer must enable e-ink emboldening by default');
assert(raster.includes('eink_contrast'), 'native raster must pass e-ink contrast options into reader fonts');
assert(raster.includes('embolden = opts.embolden'), 'native raster must allow reader emboldening override');
assert(raster.includes('alpha_gamma = opts.alpha_gamma'), 'native raster must allow reader alpha gamma override');
assert(notes.includes('synthetic embolden'), 'font rendering notes must document synthetic embolden');
assert(notes.includes('alpha gamma'), 'font rendering notes must document alpha gamma tuning');
assert(runner.includes('validate-native-font-contrast.mjs'), 'run-all must include native font contrast validation');

console.log('native font contrast ok');
