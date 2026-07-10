import fs from 'node:fs';

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const detail = read('apps/weread-move/views/book_detail_view.lua');
const shelfStore = read('apps/weread-qt/shelf_store.cpp');
const readerStore = read('apps/weread-qt/reader_store.cpp');
const refreshDetail = read('apps/weread-move/tools/refresh-detail.lua');
const qml = read('apps/weread-qt/Main.qml');

assert(detail.includes('function BookDetailView:recommendationLabel'), 'book detail must normalize WeRead recommendation scores');
assert(detail.includes('rating = rating / 10'), 'three-digit WeRead recommendation scores must render as decimal percentages');
assert(!detail.includes('"推荐值 " .. tostring(rating) .. "%"'), 'book detail must not render raw recommendation scores as percentages');
assert(shelfStore.includes('textOffset') && shelfStore.includes('textLength'), 'detail progress must use stable text offsets and full text length');
assert(shelfStore.includes('remoteProgress'), 'detail progress must fall back to WeRead remote percentage');
assert(!shelfStore.includes('QStringLiteral("第 %1 / %2 页")'), 'detail progress must never expose pagination-dependent page counts');
assert(shelfStore.includes('QStringLiteral("%1%")'), 'detail progress label must be a percentage');
assert(readerStore.includes('row.insert(QStringLiteral("textLength")'), 'reader progress persistence must store the full text length');
assert(refreshDetail.includes('gateway("/book/getprogress"'), 'detail refresh must fetch the official WeRead percentage');
assert(refreshDetail.includes('remoteProgress'), 'detail refresh must cache the official WeRead percentage');
for (const id of ['detailHero', 'detailProgressPercent', 'detailPrimaryAction', 'detailReviewList']) {
  assert(qml.includes(`id: ${id}`), `redesigned detail page must include ${id}`);
}
assert(qml.includes('text: Math.round((detailPage.book.progressRatio || 0) * 100) + "%"'), 'detail hero must render the progress as an integer percentage');
assert(qml.includes('selfTestMode === "detail-ui"') && qml.includes('detail-ui-selftest=ready'), 'detail redesign must expose a device-rendered visual QA state');

console.log('detail rating ok');
