import fs from 'node:fs';

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const app = read('apps/weread-move/app.lua');

assert(fs.statSync('apps/weread-move/views/shelf_grid_view.lua').isFile(), 'shelf_grid_view.lua must exist');
assert(fs.statSync('apps/weread-move/views/book_detail_view.lua').isFile(), 'book_detail_view.lua must exist');
assert(fs.statSync('apps/weread-move/views/download_queue_view.lua').isFile(), 'download_queue_view.lua must exist');
assert(fs.statSync('apps/weread-move/lib/book_status_store.lua').isFile(), 'book_status_store.lua must exist');
assert(fs.statSync('apps/weread-move/lib/download_manager.lua').isFile(), 'download_manager.lua must exist');
assert(app.includes('require("shelf_grid_view")'), 'app.lua must load ShelfGridView');
assert(app.includes('ShelfGridView:new'), 'app.lua must construct ShelfGridView');
assert(app.includes('RM_WEREAD_SHELF_PAGE'), 'app.lua must expose a shelf-page smoke hook');
assert(app.includes('local limit = #(books or {})'), 'cover prefetch must eventually cover the full paged shelf');
assert(!app.includes('local limit = 24'), 'cover prefetch must not stop at the first two pages');
assert(!app.includes('ShelfView:new'), 'app.lua must not boot the old row-based ShelfView in C1');
assert(!app.includes('require("shelf_view")'), 'app.lua must not require the old row-based shelf view in C1');

const shelfGrid = read('apps/weread-move/views/shelf_grid_view.lua');
assert(shelfGrid.includes('InputContainer:extend'), 'ShelfGridView must be a custom full-screen widget');
assert(shelfGrid.includes('onTap'), 'ShelfGridView must handle cover taps');
assert(shelfGrid.includes('drawCoverGrid'), 'ShelfGridView must draw a cover grid');
assert(shelfGrid.includes('drawHeader'), 'ShelfGridView must draw a header');
assert(shelfGrid.includes('drawBookCard'), 'ShelfGridView must draw individual book cards');
assert(shelfGrid.includes('drawFooter'), 'ShelfGridView must draw page navigation');
assert(shelfGrid.includes('nextPage'), 'ShelfGridView must page forward through the shelf');
assert(shelfGrid.includes('prevPage'), 'ShelfGridView must page backward through the shelf');
assert(shelfGrid.includes('pageOffset'), 'ShelfGridView must translate visible cards to real shelf indexes');
assert(shelfGrid.includes('Ready'), 'ShelfGridView must know Ready status');
assert(shelfGrid.includes('Partial'), 'ShelfGridView must know Partial status');
assert(shelfGrid.includes('Downloaded'), 'ShelfGridView must know downloaded status');
assert(shelfGrid.includes('Special'), 'ShelfGridView must know Special status');

const detail = read('apps/weread-move/views/book_detail_view.lua');
for (const label of ['Continue', 'Open', 'Download full book', 'Chapters', 'Reviews', 'Recommended', 'Newest', 'Clear cache']) {
  assert(detail.includes(label), `Book detail must expose ${label}`);
}
assert(detail.includes('probeCatalog'), 'Book detail must probe catalog');
assert(detail.includes('showSpecialState'), 'Book detail must show special state');
assert(detail.includes('loadReviews'), 'Book detail must load public reviews');
assert(detail.includes('renderReviews'), 'Book detail must render public reviews');
assert(detail.includes('on_open'), 'Book detail must expose open action');
assert(detail.includes('on_download_full'), 'Book detail must expose download full action');

const reviewService = read('apps/weread-move/lib/review_service.lua');
assert(reviewService.includes('/review/list'), 'ReviewService must use the official public review endpoint');
assert(reviewService.includes('reviewListType'), 'ReviewService must support reviewListType');
assert(reviewService.includes('Recommended'), 'ReviewService must expose Recommended reviews');
assert(reviewService.includes('Newest'), 'ReviewService must expose Newest reviews');

const downloadManager = read('apps/weread-move/lib/download_manager.lua');
assert(downloadManager.includes('download_full'), 'DownloadManager must expose full-book download');
assert(downloadManager.includes('fetch_chapters_epub'), 'DownloadManager must save all chapters as one EPUB');
assert(downloadManager.includes('start_full_download'), 'DownloadManager must expose a non-blocking full-book job');
assert(downloadManager.includes('step_full_download'), 'DownloadManager must advance full-book downloads one chapter at a time');
assert(downloadManager.includes('fetch_single_chapter_content'), 'DownloadManager must fetch one chapter per scheduled step');
assert(downloadManager.includes('save_book_epub'), 'DownloadManager must finalize step downloads into one EPUB');

assert(app.includes('step_full_download'), 'app.lua must schedule full-book download steps');
assert(!app.includes('return download_manager:download_full(book)'), 'app.lua must not run full-book download synchronously from the UI');

console.log('c1 shell ok');
