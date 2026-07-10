import fs from 'node:fs';

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

assert(fs.statSync('tests/run-all.mjs').isFile(), 'tests/run-all.mjs must exist');
const runner = fs.readFileSync('tests/run-all.mjs', 'utf8');

for (const script of [
  'validate-app-manifest.mjs',
  'validate-book-id-canonical.mjs',
  'validate-book-info-service.mjs',
  'validate-book-opening.mjs',
  'validate-c1-shell.mjs',
  'validate-downloads-view.mjs',
  'validate-ui-polish.mjs',
  'validate-shelf-swipe.mjs',
  'validate-status-refresh.mjs',
  'validate-partial-downloads.mjs',
  'validate-cover-prefetch.mjs',
  'validate-cover-hosts.mjs',
  'validate-detail-network-deferral.mjs',
  'validate-detail-rating.mjs',
  'validate-eink-contrast.mjs',
  'validate-launcher-cleanup.mjs',
  'validate-book-images.mjs',
  'validate-redownload-tool.mjs',
  'validate-koreader-paths.mjs',
  'validate-chapter-cache.mjs',
  'validate-reader-document.mjs',
  'validate-reader-word-wrap.mjs',
  'validate-native-reader-view.mjs',
  'validate-native-raster.mjs',
  'validate-native-framebuffer.mjs',
  'validate-native-launcher.mjs',
  'validate-native-input.mjs',
  'validate-native-page-loop.mjs',
  'validate-native-shelf.mjs',
  'validate-native-shelf-visual-polish.mjs',
  'validate-native-json-fallback.mjs',
  'validate-native-cover-image.mjs',
  'validate-native-image-decoders.mjs',
  'validate-native-font-renderer.mjs',
  'validate-native-font-wrapping.mjs',
  'validate-native-font-contrast.mjs',
  'validate-native-paginator.mjs',
  'validate-native-reader-typography.mjs',
  'validate-native-reader-images.mjs',
  'validate-native-reader-footer.mjs',
  'validate-native-font-rendering-notes.mjs',
  'validate-weread-qt-power-sleep.mjs',
  'validate-weread-qt-qr-login.mjs',
  'validate-font-downloads.mjs',
  'validate-sync-script.mjs',
]) {
  assert(runner.includes(script), `run-all must include ${script}`);
}

console.log('runner ok');
