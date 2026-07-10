import fs from 'node:fs';

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const app = read('apps/weread-move/app.lua');
const store = read('apps/weread-move/lib/book_status_store.lua');
const view = read('apps/weread-move/views/download_queue_view.lua');

assert(store.includes('list_downloads'), 'BookStatusStore must expose download records');
assert(store.includes('file_exists'), 'BookStatusStore must check cached file paths before listing downloads');
assert(store.includes('staleFile'), 'BookStatusStore must mark stale missing files for downloads');
assert(app.includes('list_downloads'), 'app.lua must populate the downloads view from status store');
assert(app.includes('on_download_open'), 'app.lua must wire download row open action');
assert(app.includes('RM_WEREAD_DOWNLOADS_VIEW'), 'app.lua must expose a downloads-view smoke hook');

assert(view.includes('ViewHelpers'), 'DownloadQueueView must use the shared drawing helpers');
assert(view.includes('setJobs'), 'DownloadQueueView must accept jobs');
assert(view.includes('drawHeader'), 'DownloadQueueView must draw a header');
assert(view.includes('drawJobRow'), 'DownloadQueueView must draw individual download rows');
assert(view.includes('jobs_per_page'), 'DownloadQueueView must limit visible rows per page');
assert(view.includes('pageCount'), 'DownloadQueueView must know download page count');
assert(view.includes('pageOffset'), 'DownloadQueueView must translate visible rows to real download indexes');
assert(view.includes('nextPage'), 'DownloadQueueView must page forward through downloads');
assert(view.includes('prevPage'), 'DownloadQueueView must page backward through downloads');
assert(view.includes('drawFooter'), 'DownloadQueueView must draw page navigation');
assert(view.includes('filePath'), 'DownloadQueueView must choose full or cached files with an explicit helper');
assert(view.includes('self:filePath(job)'), 'DownloadQueueView must use the file helper when rendering/opening rows');
assert(!view.includes('job.fullFile or job.cachedFile'), 'DownloadQueueView must not use Lua truthiness for file fallback');
assert(view.includes('statusLabel'), 'DownloadQueueView must show readable status text');
assert(view.includes('staleFile'), 'DownloadQueueView must show stale file state');
assert(view.includes('onTap'), 'DownloadQueueView must handle back/open taps');
assert(!/function\s+DownloadQueueView:paintTo\([^)]*\)\s*return\s+true\s*end/.test(view), 'DownloadQueueView paintTo must not be empty');

console.log('downloads view ok');
