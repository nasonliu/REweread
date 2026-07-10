import fs from 'node:fs';

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const app = read('apps/weread-move/app.lua');

assert(app.includes('if screenshot_requested() then return end'), 'detail auto network loads must be skipped in screenshot mode');
assert(app.includes('UIManager:scheduleIn(2, function()'), 'detail auto network loads must be delayed until after the page renders');
assert(!app.includes('UIManager:scheduleIn(0.1, function()\n        if book_detail_view.book == book then'), 'detail auto network loads must not run immediately after showing detail');

console.log('detail network deferral ok');
