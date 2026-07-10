import fs from 'node:fs';

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

const app = read('apps/weread-move/native_app.lua');
const raster = read('apps/weread-move/lib/native_raster.lua');
const smoke = read('apps/weread-move/tools/native-font-smoke.lua');
const runner = read('tests/run-all.mjs');

assert(app.includes('function reader_typography'), 'native app must centralize reader typography settings');
assert(app.includes('RM_WEREAD_FONT_SIZE'), 'native app must allow font size override');
assert(app.includes('RM_WEREAD_LINE_HEIGHT'), 'native app must allow body line height override');
assert(app.includes('RM_WEREAD_MARGIN'), 'native app must allow margin override');
assert(app.includes('body_line_height = typography.line_height'), 'native paginator must receive shared line height');
assert(app.includes('font_size = typography.font_size'), 'native paginator and renderer must receive shared font size');
assert(app.includes('margin = typography.margin'), 'native paginator and renderer must receive shared margin');
assert(app.includes('typography='), 'native app reader log must print typography settings');
assert(raster.includes('local body_line_height = opts.body_line_height or opts.line_height or 24'), 'native raster body text must use configurable line height');
assert(raster.includes('local heading_line_height = opts.heading_line_height or 26'), 'native raster headings must use configurable line height');
assert(!raster.includes('y = y + 24'), 'native raster must not hardcode body line advance');
assert(smoke.includes('reader_typography') || smoke.includes('RM_WEREAD_FONT_SIZE'), 'native smoke must exercise typography settings');
assert(runner.includes('validate-native-reader-typography.mjs'), 'run-all must include native reader typography validation');

console.log('native reader typography ok');
