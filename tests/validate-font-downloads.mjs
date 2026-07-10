import fs from 'node:fs';

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

assert(fs.existsSync('scripts/download-reader-fonts.sh'), 'reader font download script must exist');

const script = read('scripts/download-reader-fonts.sh');
const font = read('apps/weread-move/lib/native_font.lua');
const runner = read('tests/run-all.mjs');

assert(script.includes('downloads/fonts'), 'font download script must keep font binaries out of the app tree');
assert(script.includes('wqy-microhei-0.2.0-beta.tar.gz'), 'font download script must fetch WenQuanYi Micro Hei');
assert(script.includes('wqy-zenhei-0.9.45.tar.gz'), 'font download script must fetch WenQuanYi Zen Hei');
assert(script.includes('raw.githubusercontent.com/lxgw/LxgwWenKai'), 'font download script must fetch LXGW WenKai from the official GitHub project');
assert(script.includes('LXGW_WENKAI_COMMIT'), 'font download script must pin LXGW WenKai to a commit');
assert(script.includes('LXGWWenKai-Regular.ttf'), 'font download script must stage LXGW WenKai regular TTF');
assert(script.includes('lxgw-wenkai/lxgw-wenkai.ttf'), 'font download script must normalize LXGW WenKai to a stable staged filename');
assert(script.includes('/home/root/.local/share/fonts'), 'font download script must install to the Move user font directory');
assert(script.includes('MOVE_HOST="${MOVE_HOST:-root@10.11.99.1}"'), 'font download script must default to the official USB Move host');
assert(script.includes('rsync'), 'font download script must copy fonts with rsync');
assert(script.includes('sha256sum'), 'font download script must print device-side font checksums');
assert(script.includes('verify_sha256'), 'font download script must verify downloaded font checksums locally');
assert(!script.includes('xargs -0'), 'font download script must avoid xargs -0 for BusyBox compatibility');
assert(font.includes('wqy-microhei.ttc'), 'native font candidates must include WenQuanYi Micro Hei');
assert(font.includes('wqy-zenhei.ttc'), 'native font candidates must include WenQuanYi Zen Hei');
assert(font.includes('lxgw-wenkai.ttf'), 'native font candidates must include the normalized LXGW WenKai font');
assert(runner.includes('validate-font-downloads.mjs'), 'run-all must include font download validation');

console.log('font downloads ok');
