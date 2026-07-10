import fs from 'node:fs';

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const manager = read('apps/weread-move/lib/download_manager.lua');
const detail = read('apps/weread-move/views/book_detail_view.lua');
const downloads = read('apps/weread-move/views/download_queue_view.lua');
const app = read('apps/weread-move/app.lua');

assert(manager.includes('#job.failed > 0'), 'full-download finalization must inspect failed chapters');
assert(manager.includes('failedChapterCount'), 'partial downloads must persist failed chapter count');
assert(manager.includes('downloadState = partial_state'), 'partial EPUBs must not be marked full');
assert(detail.includes('self.status.downloadState == "partial"'), 'book detail must label partial full-book files distinctly');
assert(downloads.includes('已下载部分'), 'downloads list must show partial full-book files distinctly');
assert(app.includes('status.downloadState == "full"'), 'app must only short-circuit full-download action for real full downloads');

console.log('partial downloads ok');
