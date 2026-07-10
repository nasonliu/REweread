import fs from 'node:fs';

const manifestPath = 'apps/weread-move/external.manifest.json';
const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

assert(manifest.name === 'WeRead', 'manifest.name must be WeRead');
assert(manifest.application === 'rm-weread-native.sh', 'manifest.application must launch the native WeRead app');
assert(manifest.qtfb === true, 'manifest.qtfb must be true');
assert(manifest.environment?.LD_PRELOAD === '/home/root/shims/qtfb-shim.so', 'manifest must use qtfb shim');
assert(manifest.environment?.QTFB_SHIM_INPUT_MODE === 'NATIVE', 'manifest must use native input mode');
assert(manifest.environment?.KO_DONT_GRAB_INPUT === '1', 'manifest must not grab input globally');
assert(manifest.environment?.KO_DONT_SET_DEPTH === '1', 'manifest must preserve screen depth');

const applicationPath = `apps/weread-move/${manifest.application}`;
assert(fs.statSync(applicationPath).isFile(), 'manifest application file must exist');
fs.accessSync(applicationPath, fs.constants.X_OK);

console.log('manifest ok');
