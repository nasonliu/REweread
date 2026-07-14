import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';

const root = process.cwd();

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

const lexiconSource = fs.readFileSync(path.join(root, 'apps/weread-qt/PinyinLexicon.js'), 'utf8');
const engineSource = fs.readFileSync(path.join(root, 'apps/weread-qt/PinyinEngine.js'), 'utf8');
const engine = {};
vm.createContext(engine);
vm.runInContext(lexiconSource.replace('.pragma library', ''), engine, { filename: 'PinyinLexicon.js' });
// QML's JavaScript import creates a module namespace.  Mirror that namespace
// in Node's lightweight VM so this validation exercises the same contract.
engine.Lexicon = { candidates: engine.candidates };
vm.runInContext(engineSource.replace('.pragma library', '').replace(/^\.import .*$/m, ''), engine, { filename: 'PinyinEngine.js' });

const china = engine.candidates('zhongguo', 8);
assert(china.some((candidate) => candidate.text === '中国' && candidate.consume === 8), 'pinyin engine must offer 中国 for zhongguo');
const sentence = engine.candidates('zhongguoren', 8);
assert(sentence[0].text === '中国人' && sentence[0].consume === 11, 'engine must compose a complete phrase across a known phrase and syllable');
const novel = engine.candidates('hongloumeng', 8);
assert(novel.some((candidate) => candidate.text === '红楼梦' && candidate.consume === 11), 'engine must surface Apache-licensed Rime phrase candidates');
const fallback = engine.candidates('wen', 8);
assert(fallback.some((candidate) => candidate.text === '文' && candidate.consume === 3), 'engine must retain common single-syllable fallback candidates');
const paged = engine.candidates('shi', 50);
assert(paged.length > 5 && new Set(paged.map((candidate) => candidate.text)).size === paged.length, 'common syllables must provide enough unique candidates for a second page');
assert(engine.candidates('123', 8).length === 0, 'engine must not treat non-pinyin input as composition text');

const qml = fs.readFileSync(path.join(root, 'apps/weread-qt/Main.qml'), 'utf8');
const cmake = fs.readFileSync(path.join(root, 'apps/weread-qt/CMakeLists.txt'), 'utf8');
assert(qml.includes('import "PinyinEngine.js" as PinyinEngine'), 'Qt UI must load the self-contained pinyin engine');
assert(cmake.includes('PinyinEngine.js') && cmake.includes('PinyinLexicon.js'), 'Qt build must package the pinyin engine with the application');
assert(qml.includes('function keyboardChooseCandidate'), 'soft keyboard must commit selected pinyin candidates');
assert(qml.includes('keyboardPinyinMode = !isPassword'), 'password fields must open in English mode');
assert(qml.includes('function setKeyboardInputMode'), 'soft keyboard must switch input modes through one explicit controller');
assert(qml.includes('{"mode": "pinyin", "label": "拼音"}') && qml.includes('{"mode": "english", "label": "英文"}'), 'soft keyboard must expose separate pinyin and English choices');
assert(qml.includes('nextMode !== "english"'), 'password fields must reject cloud-backed and composition input modes');
assert(qml.includes('PinyinEngine.candidates(keyboardPinyinBuffer, 50)'), 'pinyin input must retain enough candidates for multiple pages');
assert(qml.includes('function keyboardChangeCandidatePage') && qml.includes('keyboardPagedPinyinCandidates'), 'pinyin candidates must expose explicit page navigation');
assert(qml.includes('text: "上页"') && qml.includes('text: "下页"'), 'candidate row must show previous and next page controls');

console.log('pinyin ime ok');
