import fs from 'node:fs';

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const paginator = read('apps/weread-move/lib/native_paginator.lua');
const app = read('apps/weread-move/native_app.lua');
const smoke = read('apps/weread-move/tools/native-font-smoke.lua');
const runner = read('tests/run-all.mjs');

assert(paginator.includes('NativeFont'), 'native paginator must use the native FreeType font');
assert(paginator.includes('font:wrap_text'), 'native paginator must wrap body text by real glyph width');
assert(paginator.includes('heading_font:wrap_text'), 'native paginator must wrap headings by real glyph width');
assert(paginator.includes('body_line_height'), 'native paginator must account for body line height');
assert(paginator.includes('page_height'), 'native paginator must account for page height');
assert(app.includes('NativePaginator.paginate'), 'native app must paginate with native paginator');
assert(!app.includes('ReaderDocument.paginate(document'), 'native app must not use fixed-character pagination');
assert(smoke.includes('NativePaginator.paginate'), 'font smoke must use native paginator');
assert(runner.includes('validate-native-paginator.mjs'), 'run-all must include native paginator validation');

console.log('native paginator ok');
