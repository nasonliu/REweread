import fs from 'node:fs';

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const cache = read('apps/weread-move/lib/chapter_cache.lua');
const manager = read('apps/weread-move/lib/download_manager.lua');
const runner = read('tests/run-all.mjs');

assert(cache.includes('function ChapterCache:write_chapter'), 'chapter cache must write individual chapter XHTML');
assert(cache.includes('function ChapterCache:chapters_dir'), 'chapter cache must expose a per-book chapters directory');
assert(cache.includes('"chapters"'), 'chapter cache must store chapters under a chapters directory');
assert(cache.includes('os.rename'), 'chapter cache writes must be atomic');
assert(manager.includes('require("chapter_cache")'), 'download manager must depend on chapter cache');
assert(manager.includes('chapter_cache:write_chapter'), 'download manager must persist chapter XHTML after successful fetch');
assert(runner.includes('validate-chapter-cache.mjs'), 'run-all must include chapter cache validation');

console.log('chapter cache ok');
