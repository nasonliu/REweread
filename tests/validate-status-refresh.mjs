import fs from 'node:fs';

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const app = read('apps/weread-move/app.lua');

assert(app.includes('local function sync_book_status'), 'app must expose a per-book status sync helper');
assert(app.includes('local function refresh_shelf_statuses'), 'app must refresh existing shelf cards after status changes');
assert(app.includes('sync_book_status(book)'), 'detail refresh must update the current book object status');
assert(app.includes('refresh_shelf_statuses()'), 'status-changing actions must refresh the visible shelf status');

const refreshCalls = app.match(/refresh_shelf_statuses\(\)/g) || [];
assert(refreshCalls.length >= 5, 'download, failure, probe, clear-cache paths must refresh shelf status');

console.log('status refresh ok');
