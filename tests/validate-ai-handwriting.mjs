import fs from 'node:fs';
import path from 'node:path';

const root = process.cwd();
const read = (relative) => fs.readFileSync(path.join(root, relative), 'utf8');
const assert = (condition, message) => {
  if (!condition) throw new Error(message);
};

const aiHeader = read('apps/weread-qt/ai_reply_store.h');
const aiStore = read('apps/weread-qt/ai_reply_store.cpp');
const setup = read('apps/weread-qt/ocr_setup_server.cpp');
const readerHeader = read('apps/weread-qt/reader_store.h');
const readerStore = read('apps/weread-qt/reader_store.cpp');
const qml = [
  'Main.qml',
  'ShelfPage.qml',
  'BookDetailPage.qml',
  'ReaderPage.qml',
  'MagicNotebookPage.qml',
  'SoftKeyboardPanel.qml',
].map((name) => read(`apps/weread-qt/${name}`)).join('\n');
const cmake = read('apps/weread-qt/CMakeLists.txt');
const inkCanvas = read('apps/weread-qt/ink_canvas_item.cpp');

assert(cmake.includes('ai_reply_store.cpp'), 'Qt target must compile the isolated DeepSeek bridge');
assert(aiHeader.includes('verifyAndSaveCredentials') && aiHeader.includes('replySentenceReady'), 'AI bridge must verify credentials and expose sentence streaming');
assert(aiStore.includes('deepseek.json') && aiStore.includes('S_IRUSR | S_IWUSR'), 'DeepSeek credentials must use an isolated owner-only file');
assert(aiStore.includes('O_NOFOLLOW') && aiStore.includes('::fsync') && aiStore.includes('::rename'), 'DeepSeek credential writes must be durable and symlink-safe');
assert(aiStore.includes('https://api.deepseek.com') && aiStore.includes('/chat/completions'), 'DeepSeek bridge must use the documented HTTPS chat-completions endpoint');
assert(aiStore.includes('text/event-stream') && aiStore.includes('replySentenceReady'), 'AI replies must consume stream events by sentence');
assert(!aiStore.includes('ignoreSslErrors') && !aiStore.includes('qDebug'), 'AI bridge must preserve TLS verification and avoid credential logging');
assert(setup.includes('service == QStringLiteral("baidu")') && setup.includes('service == QStringLiteral("deepseek")'), 'pairing form must select exactly one cloud service');
assert(setup.includes('一次只保存一个服务') && setup.includes('m_pendingService'), 'pairing form must preserve the unsubmitted service configuration');
assert(setup.includes("script-src 'unsafe-inline'") && setup.includes('function switchService(){var select=') && setup.includes('switchService()</script></html>'), 'pairing form must allow and initialize the service-field switcher');
assert(readerHeader.includes('setPageInkBlockAiReply') && readerStore.includes('QStringLiteral("aiReply")'), 'AI output must persist on the same ink block as its source');
assert(qml.includes('"tool": "ai"') && qml.includes('readerAiHandwritingPauseTimer'), 'AI handwriting must be an explicit pen tool with a pause trigger');
assert(qml.includes('interval: 1400') && qml.includes('beginPausedAiHandwriting'), 'auto OCR must wait for a deliberate handwriting pause');
assert(qml.includes('readerForceNewFreeInkGroup') && qml.includes('"groupId"'), 'new handwriting after a sent block must not be merged into the old request');
assert(qml.includes('askReaderInkBlockAi') && qml.includes('AI 回复'), 'a selected handwritten block must support manual AI retry');
assert(qml.includes('readerAiRevealTimer') && qml.includes('lxgwWenKaiFont.name'), 'Chinese AI replies must reveal progressively in the bundled handwriting-like font');
assert(qml.includes('id: magicPage') && qml.includes('id: magicInk'), 'the shelf must provide a dedicated full-page Magic Book');
assert(qml.includes('model: ["书架", "发现", "我的", "魔法笔记本"]') && qml.includes('openMagicBook()'), 'Magic Notebook must be directly reachable after My on the shelf navigation');
assert(qml.includes('magicPauseTimer') && qml.includes('recognizeStrokeBlock(batch)'), 'Magic Book must OCR only the paused handwriting batch');
assert(qml.includes('magicStrokeRecords') && qml.includes('strokes: appRoot.magicStrokeRecords') && qml.includes('magicQuestionFadeTimer'), 'Magic Book must preserve a question until it starts the original-style ink fade');
assert(!qml.includes('magicStrokeRecords.length > 0 || magicAwaitingReply'), 'Magic Book must not erase earlier pen strokes while a Chinese character is still being written');
assert(qml.includes('magicRevealTimer') && qml.includes('magicFontFamily'), 'Magic Book replies must gradually reveal in a selectable handwriting font');
assert(qml.includes('id: magicMenuDot') && qml.includes('magicMenuDotHit') && qml.includes('magicMenuPenTap'), 'Magic Book controls must stay behind a pen-only bottom dot');
assert(qml.includes('!stylusStore.active && !appRoot.magicMenuOpen') && qml.includes('palmRejectionActive && !appRoot.magicMenuOpen'), 'Magic Book must reject accidental touch while writing but release controls for its settings menu');
assert(qml.includes('magicInkBottomY = 0') && qml.includes('y: appRoot.magicNotebookAnswerTop'), 'Magic Book replies must move to the top once the handwritten question has faded');
assert(qml.includes('clearMagicPage()') && qml.includes('magicPage.inkCanvas.clearLive()'), 'Magic Book clear must remove both stored and live framebuffer ink');
assert(qml.includes('magicAnswerHoldTimer') && qml.includes('magicAnswerFadeTimer') && qml.includes('interval: 3600'), 'Magic Notebook answers must remain readable before the paper resets');
assert(qml.includes('magicAnswerMaxCharacters: 84') && qml.includes('maximumLineCount: 13'), 'Magic Book answers must be capped to the visible paper area');
assert(qml.includes('property string magicReplyDraft') && qml.includes('id: magicReplyInk')
  && qml.includes('magicPage.replyInkCanvas.begin(root.magicReplyDraft'), 'Magic Book replies must use the native pen-path writer instead of animated QML Text');
assert(qml.includes('magicPersonaChoice') && qml.includes('requestReply(result, root.magicPersonaChoice)'), 'Magic Book must send its selected persona to the AI reply service');
assert(aiStore.includes('systemPromptForPersona') && aiStore.includes('神秘日记') && aiStore.includes('kMagicReplyTokenLimit'), 'AI reply service must enforce a compact selectable Magic Book persona');
assert(qml.includes('property string magicFontChoice: "龙藏体"') && qml.includes('longCangDefaultMigrated'), 'Magic Book must use Long Cang as its default reply hand');
assert(qml.includes('id: magicNotebookRules') && qml.includes('magicNotebookFirstBaselineY') && qml.includes('magicNotebookLinePitch') && qml.includes('width: 7') && qml.includes('opacity: 0.42'), 'Magic Notebook must render visible dashed ruled-paper lines aligned to answer lines');
assert(qml.includes('y: appRoot.magicNotebookAnswerTop') && qml.includes('magicReplyTilt')
  && qml.includes('magicNotebookLinePitch') && qml.includes('interval: 120')
  && qml.includes('interval: 2600'), 'Magic Notebook answers must begin near the top and use the native pen-path writer after a deliberate pause');
assert(!qml.includes('纸页正在读取你的字迹') && !qml.includes('纸页正在思考'), 'Magic Book must not show OCR or thinking status on the paper');

console.log('ai handwriting flow ok');
