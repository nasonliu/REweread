import fs from 'node:fs';

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const readme = fs.readFileSync('README.md', 'utf8');
const agents = fs.readFileSync('AGENTS.md', 'utf8');

for (const text of [readme, agents]) {
  assert(text.includes('Developer Mode'), 'onboarding must explain Developer Mode');
  assert(text.includes('factory reset') || text.includes('恢复出厂'), 'onboarding must warn that first activation resets the device');
  assert(text.includes('General Information'), 'onboarding must identify the official SSH credential screen');
  assert(text.includes('root@10.11.99.1'), 'onboarding must document the USB SSH address');
  assert(text.includes('rm-ssh-over-wlan on'), 'onboarding must explain that Wi-Fi SSH is opt-in');
  assert(text.includes('StrictHostKeyChecking=no'), 'onboarding must explicitly forbid bypassing host-key verification');
}

assert(readme.includes('没有单独的“开发者账号”'), 'README must distinguish Developer Mode from a developer account');
assert(readme.includes('SSH 密码与 SSH 密钥不是一回事'), 'README must distinguish the generated device password from a host SSH key');
assert(readme.includes('Copyrights and Licenses'), 'README must provide the complete device menu path for SSH credentials');
assert(agents.includes('wait for explicit confirmation'), 'Agent guide must require user confirmation before activation');
assert(agents.includes('never ask them to paste the password or private key into chat'), 'Agent guide must prevent secret collection through chat');

console.log('agent developer onboarding ok');
