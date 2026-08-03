import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';

const source = fs.readFileSync(path.join(process.cwd(), 'apps/weread-qt/FreeNoteAnchor.js'), 'utf8');
const engine = {};
vm.createContext(engine);
vm.runInContext(source.replace('.pragma library', ''), engine, { filename: 'FreeNoteAnchor.js' });

const body = '第一段第一句。\n\n第二段内容在这里。\n\n第三段。';
const boxes = [
  { xStart: 80, xEnd: 820, yStart: 200, yEnd: 250, textStart: 0, textEnd: 7 },
  { xStart: 80, xEnd: 820, yStart: 320, yEnd: 370, textStart: 9, textEnd: 18 },
];
const paragraph = engine.anchor([{ x: 850, y: 334 }, { x: 910, y: 348 }], boxes, body, 3, 1404, 1872);
if (paragraph.anchor.kind !== 'paragraph' || paragraph.anchor.textStart !== 9 || !paragraph.anchor.quote.startsWith('第二段')) {
  throw new Error('near-margin handwriting must anchor to the closest paragraph');
}
const pageFree = engine.anchor([{ x: 1100, y: 1600 }, { x: 1200, y: 1640 }], boxes, body, 3, 1404, 1872);
if (pageFree.anchor.kind !== 'page-free' || pageFree.fallback.pageIndex !== 3) {
  throw new Error('distant handwriting must remain a page-free note');
}
const normalized = engine.normalize([{ x: 100, y: 200, pressure: 0.5 }], { left: 100, top: 200, width: 40, height: 40 });
if (normalized[0].x !== 0 || normalized[0].y !== 0) {
  throw new Error('stored ink must be normalized to its note bounds');
}

const qml = [
  'Main.qml',
  'ReaderPage.qml',
].map((name) => fs.readFileSync(path.join(process.cwd(), 'apps/weread-qt', name), 'utf8')).join('\n');
const readerStore = fs.readFileSync(path.join(process.cwd(), 'apps/weread-qt/reader_store.cpp'), 'utf8');
if (!qml.includes('"tool": "free"') || !qml.includes('"tool": "notes"') || !qml.includes('readerParagraphNotePlacements')) {
  throw new Error('reader capsule must expose free handwriting and handwritten-note display modes');
}
if (!qml.includes('saveCurrentFreeInkStroke') || !qml.includes('pendingFreeInkStrokes') || qml.includes('readerFreeNoteCommitTimer')) {
  throw new Error('free handwriting must stay as page ink and must not auto-convert after an idle timeout');
}
if (!qml.includes('return Math.max(120, root.width - root.readerMargin * 2)')) {
  throw new Error('showing handwritten notes must not shrink or repaginate the book text');
}
if (!qml.includes('12, root.width - 12') || !qml.includes('root.readerTextTopMargin, root.readerContentBottom')) {
  throw new Error('free handwriting must cover the safe page area, including blank margins outside the body text');
}
if (!readerStore.includes('addParagraphNote') || !readerStore.includes('reader-paragraph-notes.json') || !readerStore.includes('"strokes"')) {
  throw new Error('explicit OCR-backed paragraph notes must remain available separately from page ink');
}
console.log('free note anchor ok');
