import fs from 'node:fs';

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const handoff = read('docs/agent-handoff.md');
const agents = read('AGENTS.md');
const readme = read('README.md');
const docs = read('docs/README.md');
const version = read('VERSION').trim();
const manifest = JSON.parse(read('release-manifest.json'));

for (const required of [
  version,
  'source-only',
  'VPDD',
  'systemctl suspend',
  'textOffset',
  'TextEdit.positionAt()',
  'readerSocialTouchLayer',
  '99-xovi-appload.conf',
  'bad tree object',
  'packfile',
  'Docker',
  'BusyBox',
  'weread.koplugin',
  '/home/root/.local/share/rm-weread/',
  'clientStrokeId',
  'baidu-ocr-configuration-flow.md',
]) {
  assert(handoff.includes(required), `handoff must preserve the ${required} operational lesson`);
}

assert(manifest.version === version, 'release manifest must match VERSION');
assert(
  handoff.includes(`当前源码里程碑为 \`${version}\``),
  'handoff current milestone must match VERSION',
);
assert(
  handoff.includes(`当前源码基线是 ${version} source-only 里程碑`),
  'handoff onboarding prompt must match VERSION',
);
assert(
  handoff.includes(`v${version}\` 标签或 Release`),
  'handoff release status must match VERSION',
);

assert(handoff.includes('不要直接写 `/sys/power/state`'), 'handoff must forbid bypassing official suspend hooks');
assert(handoff.includes('不表示内核成功休眠'), 'handoff must explain systemctl job acceptance');
assert(handoff.includes('24 到 48 小时'), 'handoff must preserve the long-duration battery follow-up');
assert(handoff.includes('缓存按账号隔离'), 'handoff must identify account cache isolation as unfinished');
assert(agents.includes('docs/agent-handoff.md'), 'AGENTS must route new sessions to the handoff');
assert(readme.includes('当前 Agent 交接手册'), 'README onboarding must route agents to the handoff');
assert(docs.includes('agent-handoff.md'), 'documentation index must list the handoff');

console.log('agent handoff ok');
