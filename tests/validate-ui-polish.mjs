import fs from 'node:fs';

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const helpers = read('apps/weread-move/lib/view_helpers.lua');
const detail = read('apps/weread-move/views/book_detail_view.lua');
const shelf = read('apps/weread-move/views/shelf_grid_view.lua');
const downloads = read('apps/weread-move/views/download_queue_view.lua');

assert(helpers.includes('function ViewHelpers.draw_button'), 'shared polished button helper must exist');
assert(helpers.includes('function ViewHelpers.draw_input_box'), 'shared centered input-box helper must exist');
assert(helpers.includes('draw_centered_text(bb'), 'shared controls must use centered label rendering');
assert(helpers.includes('variant == "primary"'), 'button helper must support a primary action style');
assert(helpers.includes('variant == "ghost"'), 'button helper must support a subtle/ghost action style');

for (const [name, source] of [
  ['book detail', detail],
  ['shelf grid', shelf],
  ['downloads list', downloads],
]) {
  assert(source.includes('ViewHelpers.draw_button'), `${name} must use shared centered buttons`);
}

assert(!detail.includes('function BookDetailView:drawButton'), 'book detail must not keep bespoke button drawing');
assert(!detail.includes('function BookDetailView:drawSmallButton'), 'book detail must not keep bespoke small-button drawing');

console.log('ui polish ok');
