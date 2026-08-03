import fs from 'node:fs';

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const mainQml = fs.readFileSync('apps/weread-qt/Main.qml', 'utf8');
const readerQml = fs.readFileSync('apps/weread-qt/ReaderPage.qml', 'utf8');

assert(mainQml.includes('function readerTextViewportHeight(topY)'), 'reader must distinguish the safe viewport from line-snapped pagination');
assert(mainQml.includes('function readerMeasuredPageHeight(start, end, image)'), 'reader must measure the exact rich-text page payload');
assert(mainQml.includes('function readerMeasuredPageFits(start, end, topY, image)'), 'reader must compare measured text with the footer-safe viewport');
assert(mainQml.includes('function readerMeasuredPageEnd(start, candidateEnd, topY, image)'), 'reader must refine estimated page ends through measured layout');
assert(mainQml.includes('readerPage.pageMeasure.paintedHeight'), 'reader must use Qt painted height instead of only width estimates');
assert(!mainQml.includes('safeEnd >= text.length || root.readerMeasuredPageFits'), 'the final page must also be measured for footer overflow');
assert(readerQml.includes('height: appRoot.readerTextViewportHeight(appRoot.currentReaderTextTopY)'), 'visible text must use the complete footer-safe viewport');
assert(mainQml.includes('measurement-drift page='), 'layout self-test must reject measurement drift');
assert(mainQml.includes('var fonts = ["微米黑", "正黑", "霞鹜文楷", "思源黑体", "思源宋体", "寒蝉正楷", "寒蝉活宋"]'), 'layout self-test must cover all bundled fonts');
assert(mainQml.includes('var lineHeights = [1.16, 1.26, 1.36, 1.46]'), 'layout self-test must cover all selectable line heights');

console.log('reader measured pagination ok');
