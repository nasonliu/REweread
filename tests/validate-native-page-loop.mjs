import fs from 'node:fs';

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const app = read('apps/weread-move/native_app.lua');
const raster = read('apps/weread-move/lib/native_raster.lua');
const runner = read('tests/run-all.mjs');

assert(app.includes('RM_WEREAD_NATIVE_LOOP_SECONDS'), 'native app must expose bounded input loop duration');
assert(app.includes('input:read_event'), 'native app must read native input events');
assert(app.includes('event.type == "release"'), 'native app must turn pages on completed taps');
assert(app.includes('page_index = page_index + 1'), 'native app must support next page');
assert(app.includes('page_index = page_index - 1'), 'native app must support previous page');
assert(app.includes('render_page'), 'native app must re-render after page changes');
assert(raster.includes('page_number'), 'native raster must be able to render a page number marker');
assert(runner.includes('validate-native-page-loop.mjs'), 'run-all must include native page loop validation');

console.log('native page loop ok');
