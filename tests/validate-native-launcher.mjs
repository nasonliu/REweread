import fs from 'node:fs';

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const app = read('apps/weread-move/native_app.lua');
const launcher = read('apps/weread-move/rm-weread-native.sh');
const runner = read('tests/run-all.mjs');

assert(app.includes('NativeFramebuffer'), 'native app must write through native framebuffer');
assert(app.includes('NativeRaster'), 'native app must use native raster renderer');
assert(app.includes('ReaderDocument.from_xhtml'), 'native app must parse WeRead chapter pages');
assert(app.includes('NativePaginator.paginate'), 'native app must paginate WeRead chapter pages with native font metrics');
assert(app.includes('RM_WEREAD_NATIVE_SLEEP'), 'native app must expose display hold duration');
assert(app.includes('or "3600"'), 'native app launched from AppLoad must stay visible instead of exiting immediately');
assert(app.includes('held_framebuffer'), 'native app must keep the qtfb framebuffer open while the AppLoad surface is visible');
assert(app.includes('held_framebuffer:close()'), 'native app must close the held framebuffer after the visible lifetime');
assert(app.includes('qtfbKey='), 'native app must log the AppLoad qtfb key for device launch diagnostics');
assert(!app.includes('require("runtime")'), 'native app must not initialize KOReader runtime');
assert(!app.includes('require("device")'), 'native app must not require KOReader device');
assert(!app.includes('ui/'), 'native app must not use KOReader UI widgets');
assert(launcher.includes('qtfb-shim.so'), 'native launcher must use AppLoad qtfb shim');
assert(launcher.includes('native_app.lua'), 'native launcher must run native_app.lua');
assert(!launcher.includes('"${APP_DIR}/app.lua"'), 'native launcher must not launch the KOReader-runtime app');
assert(runner.includes('validate-native-launcher.mjs'), 'run-all must include native launcher validation');

console.log('native launcher ok');
