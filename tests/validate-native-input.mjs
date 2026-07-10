import fs from 'node:fs';

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const input = read('apps/weread-move/lib/native_input.lua');
const probe = read('apps/weread-move/tools/native-input-probe.lua');
const app = read('apps/weread-move/native_app.lua');
const runner = read('tests/run-all.mjs');

assert(input.includes('function NativeInput.device_info'), 'native input must expose device info probing');
assert(input.includes('function NativeInput.parse_event'), 'native input must parse Linux input_event records');
assert(input.includes('function NativeInput:open'), 'native input must open input devices directly');
assert(!input.includes('struct timeval'), 'native input must not define struct timeval globally');
assert(input.includes('/dev/input/touchscreen0'), 'native input must default to touchscreen0');
assert(input.includes('readlink -f'), 'native input must resolve touchscreen symlinks for sysfs probing');
assert(input.includes('EV_ABS'), 'native input must understand absolute touch events');
assert(input.includes('ABS_MT_POSITION_X'), 'native input must track multitouch x');
assert(input.includes('ABS_MT_POSITION_Y'), 'native input must track multitouch y');
assert(input.includes('BTN_TOUCH'), 'native input must track touch press state');
assert(input.includes('SYN_REPORT'), 'native input must emit complete tap samples on sync');
assert(!input.includes('require("runtime")'), 'native input must not require KOReader runtime');
assert(!input.includes('require("device")'), 'native input must not require KOReader device');
assert(!input.includes('ui/'), 'native input must not use KOReader UI widgets');
assert(probe.includes('NativeInput.device_info'), 'input probe must report real device info');
assert(app.includes('NativeInput'), 'native app must use native input module');
assert(runner.includes('validate-native-input.mjs'), 'run-all must include native input validation');

console.log('native input ok');
