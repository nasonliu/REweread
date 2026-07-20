import fs from 'node:fs';
import path from 'node:path';

const root = process.cwd();
const read = (relative) => fs.readFileSync(path.join(root, relative), 'utf8');
const assert = (condition, message) => {
  if (!condition) throw new Error(message);
};

const storeHeader = read('apps/weread-qt/ocr_store.h');
const store = read('apps/weread-qt/ocr_store.cpp');
const server = read('apps/weread-qt/ocr_setup_server.cpp');
const qml = [
  'Main.qml',
  'ShelfPage.qml',
  'BookDetailPage.qml',
  'ReaderPage.qml',
  'MagicNotebookPage.qml',
  'SoftKeyboardPanel.qml',
].map((name) => read(`apps/weread-qt/${name}`)).join('\n');
const docs = read('docs/baidu-ocr-configuration-flow.md');

assert(storeHeader.includes('verifyAndSaveCredentials'), 'credential verification must be restricted to the native setup path');
assert(store.includes('aip.baidubce.com') && store.includes('/oauth/2.0/token'), 'OCR credentials must be verified against Baidu over HTTPS');
assert(store.includes('aip.baidubce.com') && store.includes('/rest/2.0/ocr/v1/handwriting'), 'handwriting OCR must use the Baidu HTTPS endpoint');
assert(storeHeader.includes('recognizeStrokeBlock') && storeHeader.includes('handwritingRecognitionFinished'), 'native OCR must accept selected stroke groups and report completion');
assert(store.includes('QImage image(kStrokeRasterWidth, kStrokeRasterHeight') && store.includes('QPainterPath'), 'stroke groups must be rasterized natively without opening a full-page QML canvas');
assert(store.includes('writePrivateFileAtomically') && store.includes('S_IRUSR | S_IWUSR'), 'OCR credentials must be created owner-only');
assert(store.includes('O_NOFOLLOW') && store.includes('::fsync') && store.includes('::rename') && store.includes('::stat'), 'OCR credential writes must be symlink-safe, durable, atomic, and permission-verified');
assert(store.includes('/home/root/.local/share/rm-weread') && !store.includes('QDir::home()'), 'OCR storage must not depend on HOME because AppLoad launches without it');
assert(store.includes('runConnectionSelfTest') && store.includes('postBaidu') && store.includes('QProcess'), 'OCR must distinguish a Baidu HTTP response from a device network failure through the native transport');
assert(store.includes('runStorageSelfTest') && store.includes('storage-probe-api-key') && store.includes('loadCredentials()'), 'OCR must round-trip the real credential path without using real credentials');
assert(store.includes('ECDHE-RSA-AES128-GCM-SHA256') && store.includes('"-4"') && store.includes('"-tls1_2"') && store.includes('"-verify_return_error"') && store.includes('"-CAfile"'), 'Baidu OCR requests must force the device-verified IPv4 TLS 1.2 cipher and certificate validation');
assert(!store.includes('ignoreSslErrors') && !store.includes('VerifyNone'), 'OCR transport must not bypass TLS certificate validation');
assert(store.includes('decodeHttpResponse') && store.includes('transfer-encoding: chunked'), 'the OpenSSL transport must decode Baidu chunked HTTP responses before parsing JSON');
assert(!store.includes('qDebug') && !server.includes('qDebug'), 'OCR implementation must not log credentials or API payloads');
assert(server.includes('QSslSocket') && server.includes('startServerEncryption'), 'browser setup must use TLS, not plaintext HTTP');
assert(server.includes('m_secondsRemaining = 10 * 60') && server.includes('kMaximumFailures = 3'), 'browser setup must expire and reject repeated pairing failures');
assert(qml.includes('开启浏览器配置') && qml.includes('手写识别后搜索'), 'My page and discovery search must expose explicit cloud OCR entry points');
assert(qml.includes('setParagraphNoteOcrText') && qml.includes('recognizeParagraphNote'), 'handwritten notes must support direct OCR text attachment');
assert(qml.includes('recognizeReaderInkBlock') && qml.includes('beginDirectHandwritingOcr'), 'selected reader ink blocks must start OCR without a second window');
assert(!qml.includes('id: handwritingOcrScreen') && !qml.includes('showHandwritingOcr = true'), 'reader and search OCR must not open the removed full-screen recognition window');
assert(qml.includes('id: keyboardHandwritingPad') && qml.includes('id: keyboardHandwritingInk'), 'the built-in keyboard must provide a native handwriting pad');
assert(qml.includes('softKeyboardPanel.handwritingPad.mapFromItem(root.contentItem') && !qml.includes('softKeyboardPanel.handwritingPad.mapFromItem(root,'), 'handwriting coordinates must map through the Window content item');
assert(qml.includes('{"mode": "pinyin", "label": "拼音"}') && qml.includes('{"mode": "handwriting", "label": "手写"}') && qml.includes('{"mode": "english", "label": "英文"}'), 'keyboard input modes must be independently selectable');
assert(qml.includes('keyboardRecognizeHandwriting') && qml.includes('keyboardChooseHandwritingCandidate'), 'handwriting keyboard must recognize explicitly and commit a selected result');
assert(qml.includes('ocr-setup-selftest=ok') && qml.includes('runOcrSetupSelfTest'), 'device must self-test the explicit HTTPS setup service without exposing its pairing data');
assert(qml.includes('ocr-network-selftest=') && qml.includes('runOcrNetworkSelfTest'), 'device must test the Baidu connection without real credentials');
assert(qml.includes('ocr-storage-selftest=') && qml.includes('runStorageSelfTest'), 'device must test private credential storage without real credentials');
assert(docs.includes('cloud.baidu.com/doc/OCR/index.html'), 'documentation must point to the official Baidu OCR entry point');
assert(docs.includes('AppID') && docs.includes('API Key') && docs.includes('Secret Key'), 'documentation must distinguish every Baidu application credential');
assert(docs.includes('AppID 不填') && docs.includes('应用列表'), 'documentation must tell users which Baidu console credentials the device actually binds');
assert(docs.includes('Agent 操作边界') && docs.includes('不得把真实凭据'), 'documentation must prevent agents from collecting or shell-testing real credentials');
assert(docs.includes('我的') && docs.includes('开启浏览器配置') && docs.includes('https://'), 'documentation must describe the complete human pairing flow');

console.log('baidu ocr flow ok');
