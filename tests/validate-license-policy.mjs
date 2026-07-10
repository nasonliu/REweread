import fs from 'node:fs';

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const license = fs.readFileSync('LICENSE', 'utf8');
const readme = fs.readFileSync('README.md', 'utf8');
const agents = fs.readFileSync('AGENTS.md', 'utf8');
const dependencies = fs.readFileSync('docs/dependencies.md', 'utf8');
const legal = fs.readFileSync('docs/legal-and-commercial-use.md', 'utf8');
const release = fs.readFileSync('docs/release-checklist.md', 'utf8');

assert(license.startsWith('# PolyForm Noncommercial License 1.0.0'), 'root license must use the standard PolyForm Noncommercial title');
assert(license.includes('https://polyformproject.org/licenses/noncommercial/1.0.0'), 'root license must link the canonical terms');
assert(license.includes('Required Notice: Copyright 2026 nasonliu'), 'root license must carry the project copyright notice');
assert(license.includes('## Noncommercial Purposes'), 'root license must include the standard noncommercial grant');
assert(!license.includes('Permission is hereby granted, free of charge'), 'root license must no longer grant MIT commercial rights');

for (const text of [readme, agents, dependencies, legal, release]) {
  assert(text.includes('PolyForm Noncommercial'), 'project policy documents must name the active noncommercial license');
}

assert(readme.includes('不是 OSI 定义的开源软件'), 'README must accurately call the project source-available rather than open source');
assert(readme.includes('本项目当前不提供商业许可'), 'README must refuse commercial licensing under the current project state');
assert(readme.includes('已经在旧 MIT 许可证下合法取得的历史副本'), 'README must disclose that prior MIT grants are not retroactively revoked');
assert(agents.includes('The project currently offers no commercial license'), 'Agent guide must reject current commercial-use requests');
assert(legal.includes('微信读书用户协议') && legal.includes('weread.koplugin'), 'legal guide must identify service-terms and upstream-license blockers');

console.log('license policy ok');
