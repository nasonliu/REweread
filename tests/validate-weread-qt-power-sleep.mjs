import fs from 'node:fs';

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const header = fs.readFileSync('apps/weread-qt/power_store.h', 'utf8');
const source = fs.readFileSync('apps/weread-qt/power_store.cpp', 'utf8');
const qml = fs.readFileSync('apps/weread-qt/Main.qml', 'utf8');
const cmake = fs.readFileSync('apps/weread-qt/CMakeLists.txt', 'utf8');
const main = fs.readFileSync('apps/weread-qt/main.cpp', 'utf8');
const session = fs.readFileSync('scripts/weread-qt-session.sh', 'utf8');
const runner = fs.readFileSync('scripts/run-weread-qt-on-move.sh', 'utf8');

assert(header.includes('class PowerStore'), 'Qt app must expose a dedicated power lifecycle bridge');
assert(source.includes('44440000.bbnsm:pwrkey'), 'power bridge must discover the Move power key by device name');
assert(source.includes('Hall effect sensors'), 'power bridge must discover the Move Hall sensor input');
assert(source.includes('code != SW_LID'), 'folio handling must ignore the pen-holder Hall sensor');
assert(source.includes('kMaximumShortPressMs'), 'power bridge must distinguish short presses from long presses');
assert(source.includes('/sys/power/wake_lock') && source.includes('/sys/power/wake_unlock'), 'power bridge must use the device autosleep wake-lock contract');
assert(!source.includes('poweroff') && !source.includes('/sys/power/state'), 'reader power handling must never invoke shutdown or bypass the device sleep stack');
assert(!source.includes('/usr/bin/systemctl') && !source.includes('QStringLiteral("suspend")'), 'short press must let the device autosleep stack choose the display-safe suspend time');
assert(source.indexOf('acquireWakeLock();', source.indexOf('void PowerStore::resume')) < source.indexOf('m_sleeping = false', source.indexOf('void PowerStore::resume')), 'resume must reacquire the wake lock before restoring UI state');
assert(cmake.includes('power_store.cpp'), 'Qt build must compile PowerStore');
assert(main.includes('setContextProperty("powerStore"'), 'PowerStore must be available to QML');
assert(qml.includes('readerStore.saveProgress') && qml.includes('sleepCoverScreen'), 'sleep UI must save reading position and render the current cover');
assert(qml.includes('interval: 750') && qml.includes('powerStore.commitSleep()'), 'cover must get a render window before autosuspend');
assert(qml.includes('selfTestMode === "power-sleep"'), 'power lifecycle needs a dry-run device self-test');
assert(session.includes('RM_WEREAD_POWER_DRY_RUN'), 'device session must support non-suspending power tests');
assert(session.includes('gpio-hall-sensors') && session.includes('/etc/pm/sleep.wakesrc'), 'folio sensor must remain a system suspend wake source');
assert(session.includes('systemctl reset-failed xochitl'), 'returning to the system must clear xochitl start-rate failures');
assert(runner.includes('rm-weread-deploy') && session.includes('release_deploy_lock'), 'deployment must stay awake until the new app owns its wake lock');
assert(runner.includes('rm-were > /sys/power/wake_unlock') && session.includes('release_app_wake_locks'), 'replacement and crash cleanup must release legacy and current app wake locks');

console.log('weread Qt power sleep ok');
