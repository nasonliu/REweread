import fs from 'node:fs';

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const notes = read('docs/weread-native-font-rendering.md');
const runner = read('tests/run-all.mjs');

assert(notes.includes('reMarkable Paper Pro Move'), 'font notes must target the Move device');
assert(notes.includes('1696 x 954'), 'font notes must record Move display resolution');
assert(notes.includes('264 PPI'), 'font notes must record Move pixel density');
assert(notes.includes('20,000 colors'), 'font notes must account for color e-paper palette limits');
assert(notes.includes('HarfBuzz'), 'font notes must choose HarfBuzz for shaping');
assert(notes.includes('FreeType'), 'font notes must choose FreeType for rasterization');
assert(notes.includes('not RGB subpixel'), 'font notes must reject LCD subpixel rendering');
assert(notes.includes('Noto Serif CJK'), 'font notes must include CJK reading font candidates');
assert(notes.includes('pure black'), 'font notes must enforce black text for e-ink readability');
assert(runner.includes('validate-native-font-rendering-notes.mjs'), 'run-all must include font notes validation');

console.log('native font rendering notes ok');
