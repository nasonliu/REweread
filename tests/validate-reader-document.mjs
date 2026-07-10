import fs from 'node:fs';

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const doc = read('apps/weread-move/lib/reader_document.lua');
const cache = read('apps/weread-move/lib/chapter_cache.lua');
const smoke = read('apps/weread-move/tools/reader-document-smoke.lua');
const runner = read('tests/run-all.mjs');

assert(doc.includes('function ReaderDocument.from_xhtml'), 'reader document must parse chapter XHTML');
assert(doc.includes('function ReaderDocument.paginate'), 'reader document must paginate parsed blocks');
assert(doc.includes('type = "image"'), 'reader document must preserve inline image blocks');
assert(doc.includes('append_text_block(blocks, "heading"'), 'reader document must preserve heading blocks');
assert(doc.includes('html_unescape'), 'reader document must decode HTML entities');
assert(cache.includes('function ChapterCache:read_chapter'), 'chapter cache must read chapter XHTML for the native reader');
assert(cache.includes('function ChapterCache:first_cached_chapter_path'), 'chapter cache must find a cached chapter for quick native open');
assert(smoke.includes('ReaderDocument.from_xhtml'), 'device smoke must parse a cached chapter');
assert(smoke.includes('pages='), 'device smoke must print page count');
assert(runner.includes('validate-reader-document.mjs'), 'run-all must include reader document validation');

console.log('reader document ok');
