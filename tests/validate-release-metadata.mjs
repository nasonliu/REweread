import fs from 'node:fs';

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const version = read('VERSION').trim();
const manifest = JSON.parse(read('release-manifest.json'));
const cmake = read('apps/weread-qt/CMakeLists.txt');
const installer = read('scripts/install-weread-qt-appload.sh');
const packager = read('scripts/package-source-release.sh');
const uninstaller = read('scripts/uninstall-weread-qt-appload.sh');
const changelog = read('CHANGELOG.md');
const releaseNotes = read(`docs/releases/v${version}.md`);

assert(version === '1.5.0', 'source milestone version must be explicit and stable');
assert(manifest.version === version, 'release manifest must match VERSION');
assert(manifest.releaseType === 'source-only', 'source milestone must remain source-only');
assert(manifest.commercialUse === false && manifest.officiallyAuthorized === false, 'manifest must preserve legal boundaries');
assert(cmake.includes('project(rm_weread_qt VERSION 1.5.0'), 'CMake project version must match VERSION');
assert(installer.includes('APP_VERSION=') && installer.includes('"version": "$APP_VERSION"'), 'AppLoad manifest must read the unified version');
assert(installer.includes('REMOTE_STAGE=') && installer.includes('REMOTE_BACKUP=') && installer.includes('rollback_on_error'), 'install and upgrade must stage atomically and retain rollback');
assert(packager.includes('git -C "$ROOT_DIR" archive'), 'source release must be generated from tracked Git content');
assert(packager.includes('check-repository.mjs') && packager.includes('tests/run-all.mjs'), 'packaging must run safety and validation gates');
assert(!fs.existsSync('scripts/package-weread-plugin.sh'), 'release tooling must not package the unlicensed upstream plugin');
assert(uninstaller.includes('preserve user data') && uninstaller.includes('CONFIRM_REMOVE_DATA=DELETE-RM-WEREAD-DATA'), 'uninstall must preserve data by default and gate deletion');
assert(changelog.includes(`## [${version}]`) && releaseNotes.includes('Source-only 1.5.0 milestone'), 'release notes must match the staged version and boundary');

console.log('release metadata ok');
