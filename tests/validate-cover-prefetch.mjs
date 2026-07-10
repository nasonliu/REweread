import fs from 'node:fs';

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const app = read('apps/weread-move/app.lua');

assert(app.includes('local function screenshot_requested'), 'app must detect screenshot smoke mode');
assert(app.includes('if screenshot_requested() then'), 'cover prefetch must be skipped during screenshot smoke runs');
assert(app.includes('local chunk_size = 1'), 'cover prefetch must process one cover per UI step');
assert(!app.includes('local chunk_size = 4'), 'cover prefetch must not block the UI with multi-cover chunks');
assert(app.includes('UIManager:scheduleIn(2'), 'cover prefetch must start after the first screen has time to render');
assert(app.includes('UIManager:scheduleIn(1'), 'cover prefetch follow-up steps must be throttled');

console.log('cover prefetch ok');
