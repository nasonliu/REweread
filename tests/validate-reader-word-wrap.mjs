import fs from 'node:fs';

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const doc = read('apps/weread-move/lib/reader_document.lua');
const runner = read('tests/run-all.mjs');

assert(doc.includes('latin_word'), 'reader document wrapper must identify Latin word runs');
assert(doc.includes('append_token'), 'reader document wrapper must append whole tokens');
assert(!doc.includes('count >= max_chars'), 'reader document wrapper must not hard-split solely before reading the next character');
assert(runner.includes('validate-reader-word-wrap.mjs'), 'run-all must include reader word wrap validation');

console.log('reader word wrap ok');
