import fs from 'node:fs';

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const paths = read('apps/weread-move/lib/koreader_paths.lua');
const runtime = read('apps/weread-move/lib/runtime.lua');
const tool = read('apps/weread-move/tools/redownload-book.lua');
const runner = read('tests/run-all.mjs');

assert(paths.includes('function KoreaderPaths.append'), 'koreader paths module must expose append');
assert(paths.includes('koreader_dir .. "/?.lua;"'), 'koreader paths module must expose KOReader root Lua modules such as ffi/serpent');
assert(paths.includes('common/?.lua'), 'koreader paths module must expose KOReader common Lua modules');
assert(paths.includes('frontend/?.lua'), 'koreader paths module must expose KOReader frontend Lua modules');
assert(paths.includes('common/?.so'), 'koreader paths module must expose KOReader C modules');
assert(!paths.includes('UIManager'), 'koreader paths module must not initialize UIManager');
assert(!paths.includes('CanvasContext'), 'koreader paths module must not initialize canvas');
assert(runtime.includes('require("koreader_paths")'), 'runtime must reuse shared KOReader path setup');
assert(tool.includes('require("koreader_paths")'), 'redownload tool must reuse shared KOReader path setup');
assert(runner.includes('validate-koreader-paths.mjs'), 'run-all must include KOReader path boundary validation');

console.log('koreader paths ok');
