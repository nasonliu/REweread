import fs from 'node:fs';
import path from 'node:path';

const root = process.cwd();
const read = (relativePath) => fs.readFileSync(path.join(root, relativePath), 'utf8');
const assert = (condition, message) => {
  if (!condition) throw new Error(message);
};

const qml = read('apps/weread-qt/Main.qml');
const inkHeader = read('apps/weread-qt/ink_canvas_item.h');
const inkCpp = read('apps/weread-qt/ink_canvas_item.cpp');
const directInkHeader = read('apps/weread-qt/direct_ink_framebuffer.h');
const directInkCpp = read('apps/weread-qt/direct_ink_framebuffer.cpp');
const main = read('apps/weread-qt/main.cpp');
const cmake = read('apps/weread-qt/CMakeLists.txt');
const stylusHeader = read('apps/weread-qt/stylus_store.h');
const readerHeader = read('apps/weread-qt/reader_store.h');
const readerCpp = read('apps/weread-qt/reader_store.cpp');

assert(qml.includes('InkCanvas {') && qml.includes('id: readerInkCanvas'), 'reader must use the native ink item');
assert(!qml.includes('id: readerMarkerPreviewCanvas'), 'reader must not full-redraw a QML Canvas for every pen sample');
assert(qml.includes('readerInkCanvas.beginStroke') && qml.includes('readerInkCanvas.appendPoint'), 'pen samples must append only the newest segment');
assert(qml.includes('readerInkCanvas.finishStroke()'), 'pen-up must finish the temporary ink layer');
const appendSnippet = qml.slice(qml.indexOf('function appendStylusStroke'), qml.indexOf('function endStylusStroke'));
assert(!appendSnippet.includes('points.slice()'), 'live pen input must not copy the complete stroke on every point');

assert(inkHeader.includes('QQuickPaintedItem') && inkHeader.includes('QML_NAMED_ELEMENT(InkCanvas)'), 'native ink item must be a registered painted QML item');
assert(inkCpp.includes('update(dirty.intersected(boundingRect()).toAlignedRect())'), 'live ink must dirty only the newest segment rectangle');
assert(inkCpp.includes('kColorChaseDelayMs = 105') && inkCpp.includes('Qt::black'), 'live colored ink must begin as low-latency black ink');
assert(inkCpp.includes('m_dryingImage') && inkCpp.includes('advanceDryingInk'), 'target color must chase the black pen head while the stroke is still active');
assert(inkCpp.includes('kFinalRefreshDelayMs = 280') && inkCpp.includes('finalizeInkSession'), 'complete pen idle must coalesce into one final colored refresh');
assert(inkCpp.includes('EPScreenModeItem') && inkCpp.includes('EPScreenModeItem::Pen'), 'device builds must request the private local Pen waveform region with a safe fallback');
assert(main.includes('DirectInkFramebuffer::instance().initialize()'), 'direct ink must capture the device framebuffer before the Qt Quick engine starts');
assert(cmake.includes('direct_ink_framebuffer.cpp') && cmake.includes('--export-dynamic'), 'the executable must build and export the direct framebuffer observer');
assert(directInkHeader.includes('drawBlackLine') && directInkHeader.includes('refreshMonoFast'), 'direct ink must separate pixel writes from coalesced panel refreshes');
assert(directInkCpp.includes('EPFramebuffer8instance') && directInkCpp.includes('EPFramebuffer11swapBuffers'), 'direct ink must use the device vendor singleton without private object offsets');
assert(directInkCpp.includes('m_swap(m_vendorInstance, clipped, 0, 0, 0)'), 'live ink must use mono content, pen mode, and partial refresh');
assert(inkCpp.includes('kDirectSwapIntervalMs = 8') && inkCpp.includes('m_directDirty.united(dirty)'), 'live samples must coalesce dirty rectangles at the validated fast-ink cadence');
const directBranch = inkCpp.slice(inkCpp.indexOf('if (m_directInkActiveForStroke) {'), inkCpp.indexOf('void InkCanvasItem::clearLive'));
assert(directBranch.includes('drawDirectSegment(segment)') && !directBranch.includes('drawDirectSegment(segment);\n        update('), 'direct pen points must not also schedule per-point Qt scene redraws');
assert(stylusHeader.includes('m_moveThrottleMs = 8') && stylusHeader.includes('m_minMoveDistance = 1.0'), 'raw stylus sampling must not double-throttle Chinese handwriting');
assert(appendSnippet.includes('< 1'), 'QML must reject duplicate coordinates only, not six-pixel pen movements');

assert(qml.includes('{"id": "green", "tool": "color"') && qml.includes('{"id": "marker", "tool": "marker"'), 'color choice and marker/free mode must be independent tools');
assert(qml.includes('if (tool.tool === "color")') && qml.includes('root.readerMarkerTool = tool.tool || "marker"'), 'choosing a color must not implicitly switch writing mode');
assert(qml.includes('{"id": "ocr", "tool": "ocr"') && qml.includes('beginReaderInkBlockOcrSelection'), 'capsule must enter explicit OCR block selection');
assert(qml.includes('readerInkBlockAt') && qml.includes('recognizeReaderInkBlock'), 'OCR must load only the selected nearby-stroke block');
assert(qml.includes('selectReaderInkBlock') && qml.includes('id: readerInkBlockActions'), 'a finger tap on an ink block must open contextual OCR and delete actions');
assert(qml.includes('{"id": "clear", "tool": "clear"') && qml.includes('readerClearArmed'), 'capsule must require a confirmed clear action');
assert(readerHeader.includes('Q_PROPERTY(QVariantList pageInkBlocks') && readerCpp.includes('buildPageInkBlocks'), 'ReaderStore must expose spatially and temporally grouped ink blocks');
assert(readerHeader.includes('addPageStrokesBatch') && readerCpp.includes('void ReaderStore::addPageStrokesBatch'), 'ReaderStore must support one persisted write for a settled group of pen strokes');
const freeStrokeSaveSnippet = qml.slice(qml.indexOf('function saveCurrentFreeInkStroke'), qml.indexOf('function readerParagraphNotePlacements'));
assert(freeStrokeSaveSnippet.includes('pendingFreeInkStrokes') && freeStrokeSaveSnippet.includes('readerInkPersistTimer.restart()'), 'freehand pen-up must queue persistence until the user pauses');
assert(!freeStrokeSaveSnippet.includes('readerStore.addPageStroke('), 'freehand pen-up must not synchronously serialize the complete strokes file');
assert(qml.includes('id: readerInkPersistTimer') && qml.includes('function flushPendingFreeInkStrokes'), 'queued ink must persist after a short idle period and before a page turn');
assert(qml.includes('strokes: root.readerVisibleInkStrokes()'), 'queued strokes must remain visible before disk persistence finishes');
assert(qml.includes('readerInkPersistTimer.stop()') && qml.includes('currentFreeNotePoints || []).length > 0'), 'page persistence must never run while a freehand stroke is active');
assert(qml.includes('clientStrokeId') && readerCpp.includes('clientStrokeId'), 'pending and persisted forms of one stroke must be deduplicated during the save handoff');
assert(inkCpp.includes('sameStoredStrokeVisual') && inkCpp.includes('!sameStoredStrokeVisual(m_strokes.at(index), strokes.at(index))'), 'metadata-only persistence changes must not rebuild and refresh the ink canvas');
assert(readerCpp.includes('strokeAtMs - blockLastAtMs > 3200') && readerCpp.includes('nearBlock.intersects(strokeBounds)'), 'ink grouping must require recent, spatially nearby strokes');
assert(readerHeader.includes('setPageInkBlockOcrText') && readerCpp.includes('void ReaderStore::setPageInkBlockOcrText'), 'accepted OCR text must persist only with the selected ink block');
assert(readerHeader.includes('removePageInkBlock') && readerCpp.includes('void ReaderStore::removePageInkBlock'), 'contextual delete must remove only the selected ink block');
assert(stylusHeader.includes('Q_PROPERTY(bool palmRejectionActive') && stylusHeader.includes('m_palmReleaseTimer'), 'StylusStore must expose pen-proximity palm rejection with a short release tail');
assert(qml.includes('id: readerPalmRejectionLayer') && qml.includes('stylusStore.palmRejectionActive'), 'reader must consume all finger gestures while the pen is in range');
assert(qml.includes('id: keyboardHandwritingInk') && qml.includes('keyboardHandwritingInk.beginStroke'), 'handwriting IME must reuse the validated native fast-ink path');
assert(qml.includes('beginKeyboardHandwritingStroke(x, y)') && qml.includes('appendKeyboardHandwritingStroke(x, y)'), 'raw stylus samples must be routed directly into the handwriting keyboard');
assert(qml.includes('|| root.showSoftKeyboard)'), 'raw stylus capture must already be active before switching keyboard modes');
const finishStrokeSnippet = inkCpp.slice(inkCpp.indexOf('void InkCanvasItem::finishStroke()'), inkCpp.indexOf('void InkCanvasItem::paint'));
assert(finishStrokeSnippet.includes('flushDirectInk()') && !finishStrokeSnippet.includes('m_dryTimer.start()'), 'pen-up must flush direct ink without starting a competing Qt refresh before the next stroke');

console.log('fast ink validation ok');
