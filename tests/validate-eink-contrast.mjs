import fs from 'node:fs';

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const helpers = read('apps/weread-move/lib/view_helpers.lua');

assert(helpers.includes('muted = Blitbuffer.COLOR_BLACK'), 'readable muted text must be black on e-ink');
assert(!helpers.includes('muted = Blitbuffer.COLOR_DARK_GRAY'), 'readable text must not use dark gray on e-ink');

console.log('e-ink contrast ok');
