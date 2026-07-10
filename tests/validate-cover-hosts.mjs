import fs from 'node:fs';

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const coverCache = read('apps/weread-move/lib/cover_cache.lua');
const runner = read('tests/run-all.mjs');

assert(coverCache.includes('image%.myqcloud%.com'), 'cover cache must allow WeRead image.myqcloud.com cover hosts');
assert(coverCache.includes('file%.myqcloud%.com'), 'cover cache must allow WeRead file.myqcloud.com cover hosts');
assert(runner.includes('validate-cover-hosts.mjs'), 'run-all must include cover host validation');

console.log('cover hosts ok');
