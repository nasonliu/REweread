import fs from 'node:fs';

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const readme = read('README.md');
const quick = read('docs/quick-start-user-guide.md');
const ocr = read('docs/baidu-ocr-configuration-flow.md');
const upgrade = read('docs/agent-upgrade-v1.5.md');

assert(readme.includes('`1.5.0`') && readme.includes('agent-upgrade-v1.5.md'), 'README must route agents into the 1.5 upgrade flow');
assert(quick.includes('颜色选择与工具选择相互独立') && quick.includes('自由手写'), 'user guide must explain the 1.5 pen capsule');
assert(quick.includes('不会识别整页') && quick.includes('原始笔迹仍保留'), 'user guide must describe selected-block optional OCR');
assert(quick.includes('上页/下页') && quick.includes('手写模式不会每写两笔就自动识别'), 'user guide must explain candidate paging and explicit handwriting recognition');
assert(quick.includes('我的 → 百度 OCR → 开启浏览器配置'), 'user guide must route users to explicit OCR setup');
assert(ocr.includes('AppID 不填') && ocr.includes('API Key') && ocr.includes('Secret Key'), 'OCR guide must distinguish the bound Baidu fields');
assert(upgrade.includes('git pull --ff-only') && upgrade.includes('install-weread-qt-appload.sh'), 'Agent upgrade guide must cover source update and atomic device installation');
assert(upgrade.includes('严禁删除') && upgrade.includes('/home/root/.local/share/rm-weread/'), 'Agent upgrade guide must preserve all user data');
assert(upgrade.includes('根分区重新挂载为可写') && upgrade.includes('取得同意'), 'Agent upgrade guide must gate the high-impact root filesystem step');

console.log('1.5 user and Agent guides ok');
