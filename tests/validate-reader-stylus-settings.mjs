import fs from 'node:fs';
import path from 'node:path';

const root = process.cwd();

function read(relativePath) {
  return fs.readFileSync(path.join(root, relativePath), 'utf8');
}

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

const cmake = read('apps/weread-qt/CMakeLists.txt');
assert(cmake.includes('stylus_store.cpp'), 'Qt app must compile the stylus event bridge');
assert(cmake.includes('stylus_store.h'), 'Qt app must include the stylus event bridge header');

const main = read('apps/weread-qt/main.cpp');
assert(main.includes('#include "stylus_store.h"'), 'main.cpp must include StylusStore');
assert(main.includes('StylusStore stylusStore'), 'main.cpp must create StylusStore');
assert(main.includes('setContextProperty("stylusStore"'), 'main.cpp must expose StylusStore to QML');

const header = read('apps/weread-qt/stylus_store.h');
assert(header.includes('bool eventFilter'), 'StylusStore must filter native Qt input events');
assert(header.includes('stylusPressed') && header.includes('stylusMoved') && header.includes('stylusReleased'), 'StylusStore must expose press/move/release signals');
assert(header.includes('QSocketNotifier'), 'StylusStore must listen to the raw marker fd with QSocketNotifier');
assert(header.includes('openMarkerDevice') && header.includes('handleMarkerInput'), 'StylusStore must expose raw marker-device helpers');
assert(header.includes('QElapsedTimer'), 'StylusStore must track time to throttle raw move events');
assert(header.includes('m_moveThrottleMs') && header.includes('m_minMoveDistance'), 'StylusStore must coalesce high-frequency marker moves before QML');

const cpp = read('apps/weread-qt/stylus_store.cpp');
assert(cpp.includes('linux/input.h'), 'StylusStore must read Linux input events directly on Move');
assert(cpp.includes('Elan marker input'), 'StylusStore must discover the Move marker input device by name');
assert(cpp.includes('/proc/bus/input/devices'), 'StylusStore must discover marker event nodes from proc input metadata');
assert(cpp.includes('readAbsRange(ABS_X') && cpp.includes('readAbsRange(ABS_Y') && cpp.includes('EVIOCGABS(code)'), 'StylusStore must read raw coordinate ranges for screen mapping');
assert(cpp.includes('EV_ABS') && cpp.includes('EV_KEY') && cpp.includes('EV_SYN'), 'StylusStore must parse raw absolute/key/sync events');
assert(cpp.includes('BTN_TOUCH') && cpp.includes('BTN_TOOL_PEN'), 'StylusStore must distinguish pen contact from hover');
assert(cpp.includes('emit stylusPressed') && cpp.includes('emit stylusMoved') && cpp.includes('emit stylusReleased'), 'StylusStore must emit stroke phases from raw marker reports');
assert(cpp.includes('shouldEmitMove'), 'StylusStore must centralize raw move throttling');
assert(cpp.includes('m_moveThrottleMs') && cpp.includes('m_minMoveDistance'), 'StylusStore raw move throttling must use both time and distance');
assert(cpp.includes('synthesizeTapAsMouseClick'), 'short pen taps must be converted into normal Qt mouse clicks so existing buttons can be operated with the stylus');
assert(cpp.includes('m_tapMaxDistance'), 'stylus tap synthesis must distinguish button taps from drawing strokes by movement distance');
assert(header.includes('stylusTapped'), 'StylusStore must expose short pen taps directly to QML for controls that do not receive synthesized mouse events');

const qml = read('apps/weread-qt/Main.qml');
assert(qml.includes('function readerEstimatedLinePixels() {\n        return root.readerLinePixels()\n    }'), 'reader pagination must estimate the same line pixels that rich TextEdit actually renders');
assert(qml.includes('function readerPaginationHeightBudget(topY) {\n        return root.readerBodyHeight(topY)\n    }'), 'reader pagination must use the full body height instead of reserving a large blank bottom band');
assert(qml.includes('paintedHeight < bodyHeight * 0.97'), 'reader layout selftest must reject pages that leave more than three percent blank space');
assert(qml.includes('!root.isReaderChapterEnd(root.currentReaderTextEnd)'), 'reader layout selftest must allow natural blank space at chapter boundaries');
assert(qml.includes('!root.isReaderNearChapterEnd(root.currentReaderTextStart, root.currentReaderTextEnd)'), 'reader layout selftest must allow short tail whitespace near chapter boundaries');
assert(qml.includes('readerSettingsPanelHeight'), 'reader settings panel height must be stable and shared with its repaint backing');
assert(qml.includes('readerSettingsBackdrop'), 'reader settings must render an opaque repaint backing above body text');
assert(qml.includes('color: root.paperColor'), 'reader settings backing must use opaque white paper on e-ink');
assert(qml.includes('z: 11') && qml.includes('z: 12'), 'reader settings backing and panel must sit above the reader body');
assert(qml.includes('readerStylusTools'), 'reader must define a compact stylus tool palette');
assert(qml.includes('readerMarkerTool'), 'reader must track marker vs eraser mode');
assert(qml.includes('readerStylusToolBar'), 'reader must render a right-side stylus capsule toolbar');
assert(qml.includes('readerStylusToolsExpanded'), 'reader stylus toolbar must support a collapsed default state');
assert(qml.includes('readerStylusCollapsedHandle'), 'reader stylus toolbar must expose only a small collapsed pen handle by default');
assert(qml.includes('readerStylusToolAt'), 'reader must hit-test stylus presses against the capsule toolbar');
assert(qml.includes('selectReaderStylusTool'), 'reader must select marker tools from stylus coordinates');
assert(qml.includes('"eraser"'), 'reader stylus toolbar must include an eraser tool');
assert(qml.includes('TextEdit {') && qml.includes('id: readerBodyText'), 'reader body must use TextEdit so stylus hit-testing can use the real Qt text layout');
assert(qml.includes('readOnly: true') && qml.includes('selectByMouse: false'), 'reader TextEdit must behave like read-only reading text, not editable/selectable text');
assert(qml.includes('id: readerLeftPageTurnArea') && qml.includes('id: readerRightPageTurnArea'), 'reader must keep explicit page-turn touch areas above the TextEdit body');
assert(qml.includes('z: 6') && qml.includes('root.handleReaderPageTurnGesture'), 'page-turn touch areas must sit above TextEdit and support swipe gestures');
assert(!qml.includes('enabled: !root.annotationMode && !root.showReaderCatalog && !root.showReaderSettings'), 'left-edge catalog gesture must remain available after a marker tool has been selected');
assert(!qml.includes('enabled: !root.annotationMode\n            property real startX'), 'touch page turning must remain available after a marker tool has been selected');
assert(qml.includes('handleReaderSettingsStylusTap'), 'reader settings controls must be hittable from raw stylus tap coordinates');
assert(qml.includes('onStylusTapped'), 'reader must route short pen taps to QML controls, not rely only on synthesized mouse events');
assert(qml.includes('positionAt('), 'reader stylus hit-testing must use Qt TextEdit.positionAt instead of hand-estimated line boxes');
assert(qml.includes('getText(0, documentPosition)'), 'reader must translate TextEdit document positions through visible text, not rich-text markup');
assert(qml.includes('readerTextOffsetForVisibleText'), 'reader must map visible TextEdit text positions back to body text offsets');
assert(qml.includes('beginStylusStroke') && qml.includes('appendStylusStroke') && qml.includes('endStylusStroke'), 'reader must route marker drawing through stylus helpers');
assert(qml.includes('target: stylusStore'), 'reader must listen to StylusStore signals');
assert(qml.includes('onStylusPressed') && qml.includes('onStylusMoved') && qml.includes('onStylusReleased'), 'reader must handle stylus press/move/release in QML');
assert(qml.includes('root.screenName === "reader"') && qml.includes('|| root.showSoftKeyboard)'), 'raw stylus listener must cover both reader annotation and the full keyboard session');
assert(qml.includes('eraseCurrentMarkerSelection'), 'eraser strokes must clear text-attached highlights');
assert(!qml.includes('enabled: root.annotationMode\n            preventStealing: true\n            onPressed: function(mouse)'), 'reader must not use touch MouseArea as the marker input source');
assert(!qml.includes('id: readerMarkerColorPicker'), 'reader must not put marker color selection inside the catalog/settings menu');
assert(qml.includes('id: readerStylusToolBar'), 'reader must keep pen-only marker controls in the side toolbar');
assert(qml.includes('selectReaderStylusTool'), 'reader side toolbar must select marker colors without using the catalog drawer');
assert(qml.includes('readerSuppressPageTurnUntilMs'), 'reader must track a short pen-only page-turn suppression window');
assert(qml.includes('Date.now() < root.readerSuppressPageTurnUntilMs'), 'page-turn handlers must reject synthesized stylus taps');
assert(qml.includes('readerStylusCollapseTimer'), 'stylus palette must stay expanded until its synthesized click has been consumed');
assert(qml.includes('readerStylusCollapsePending'), 'stylus color selection must defer capsule collapse instead of exposing the page-turn layer');
assert(qml.includes('selfTestMode === "reader-stylus-toolbar"') && qml.includes('reader-stylus-toolbar-selftest=ok'), 'device self-test must prove pen color selection cannot turn a page');

const readerStoreHeader = read('apps/weread-qt/reader_store.h');
assert(readerStoreHeader.includes('clearTextHighlightsInRange'), 'ReaderStore must support erasing text-attached highlights by range');

const readerStoreCpp = read('apps/weread-qt/reader_store.cpp');
assert(readerStoreCpp.includes('void ReaderStore::clearTextHighlightsInRange'), 'ReaderStore must implement range erasing for pen eraser strokes');
assert(readerStoreCpp.includes('rowEnd <= safeStart || rowStart >= safeEnd'), 'range eraser must remove only overlapping text highlights');

const sessionScript = read('scripts/weread-qt-session.sh');
assert(sessionScript.includes('pidof rm_weread_qt'), 'AppLoad session must kill stale WeRead Qt instances before launch');
assert(sessionScript.includes('APP_STARTED=1'), 'AppLoad session must only restore xochitl after an app instance was actually started');

console.log('reader stylus and settings validation ok');
