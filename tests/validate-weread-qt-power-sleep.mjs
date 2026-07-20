import fs from 'node:fs';

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const header = fs.readFileSync('apps/weread-qt/power_store.h', 'utf8');
const source = fs.readFileSync('apps/weread-qt/power_store.cpp', 'utf8');
const qml = fs.readFileSync('apps/weread-qt/Main.qml', 'utf8');
const sleepCover = fs.readFileSync('apps/weread-qt/SleepCoverScreen.qml', 'utf8');
const cmake = fs.readFileSync('apps/weread-qt/CMakeLists.txt', 'utf8');
const main = fs.readFileSync('apps/weread-qt/main.cpp', 'utf8');
const session = fs.readFileSync('scripts/weread-qt-session.sh', 'utf8');
const runner = fs.readFileSync('scripts/run-weread-qt-on-move.sh', 'utf8');
const networkHeader = fs.readFileSync('apps/weread-qt/network_store.h', 'utf8');
const networkSource = fs.readFileSync('apps/weread-qt/network_store.cpp', 'utf8');

assert(header.includes('class PowerStore'), 'Qt app must expose a dedicated power lifecycle bridge');
assert(header.includes('Q_PROPERTY(int batteryLevel') && header.includes('Q_PROPERTY(bool charging'), 'power bridge must expose the Move battery state');
assert(source.includes('44440000.bbnsm:pwrkey'), 'power bridge must discover the Move power key by device name');
assert(source.includes('Hall effect sensors'), 'power bridge must discover the Move Hall sensor input');
assert(source.includes('code != SW_LID'), 'folio handling must ignore the pen-holder Hall sensor');
assert(source.includes('kMaximumShortPressMs'), 'power bridge must distinguish short presses from long presses');
assert(source.includes('/sys/power/wake_lock') && source.includes('/sys/power/wake_unlock'), 'power bridge must use the device autosleep wake-lock contract');
assert(header.includes('m_sleepCommitTimer') && source.includes('connect(&m_sleepCommitTimer, &QTimer::timeout, this, &PowerStore::commitSleep)'), 'C++ must release the wake lock even if the QML sleep timer stalls');
assert(source.includes('power-sleep request') && source.includes('power-sleep commit') && source.includes('power-sleep resume'), 'power transitions must leave token-free device diagnostics');
assert(source.includes('/sys/class/power_supply/max77818_battery/capacity'), 'battery status must come from the Move main battery rather than marker accessories');
assert(source.includes('m_batteryTimer.setInterval(60000)'), 'battery status must refresh periodically without polling every frame');
assert(!source.includes('poweroff') && !source.includes('/sys/power/state'), 'reader power handling must never invoke shutdown or bypass the device sleep stack');
assert(source.includes('/usr/bin/systemctl') && source.includes('QStringLiteral("suspend")'), 'sleep must use the official systemd path so device Wi-Fi and wake-source hooks run');
assert(header.includes('m_suspendRetryTimer') && source.includes('kSuspendRetryDelayMs'), 'a busy display regulator must retry suspend after its protection timer settles');
assert(source.includes('kMaximumSuspendAttempts') && source.includes('handleSystemSuspendFinished'), 'failed system suspend retries must be bounded and observable');
assert(header.includes('m_suspendVerifyTimer') && source.includes('systemd-suspend.service'), 'suspend must verify the final systemd unit result instead of trusting job acceptance');
assert(source.includes('vpdd_timeout_ms') && source.includes('power-sleep wait-vpdd'), 'sleep must wait for the color display VPDD protection timer before releasing the wake lock');
assert(!source.includes('/sys/power/state'), 'reader power handling must not bypass the official systemd sleep hooks');
assert(source.indexOf('acquireWakeLock();', source.indexOf('void PowerStore::resume')) < source.indexOf('m_sleeping = false', source.indexOf('void PowerStore::resume')), 'resume must reacquire the wake lock before restoring UI state');
assert(cmake.includes('power_store.cpp'), 'Qt build must compile PowerStore');
assert(cmake.includes('SleepCoverScreen.qml'), 'Qt build must package the sleep cover component');
assert(main.includes('setContextProperty("powerStore"'), 'PowerStore must be available to QML');
assert(qml.includes('readerStore.saveProgress') && qml.includes('SleepCoverScreen'), 'sleep UI must save reading position and render the current cover');
assert(sleepCover.includes('required property string coverSource') && sleepCover.includes('Image.PreserveAspectFit'), 'sleep cover component must render the current cover through an explicit interface');
assert(qml.includes('interval: 750') && qml.includes('powerStore.commitSleep()'), 'cover must get a render window before autosuspend');
assert(networkHeader.includes('prepareForSleep()') && networkHeader.includes('resumeAfterSleep()'), 'network bridge must expose the sleep lifecycle');
assert(networkHeader.includes('m_resumeReconnectTimer') && networkSource.includes('m_resumeReconnectTimer.stop()'), 'a repeated sleep must cancel a pending Wi-Fi reconnect');
assert(networkHeader.includes('m_resumeReconnectAttempts') && networkSource.includes('m_resumeReconnectAttempts < 4'), 'wake must retry while the official Wi-Fi module restore finishes');
assert(networkSource.includes('QStringLiteral("disconnect")') && networkSource.includes('QStringLiteral("reassociate")'), 'sleep must disconnect Wi-Fi and wake must reconnect without forgetting the saved network');
assert(qml.includes('networkStore.prepareForSleep()') && qml.includes('networkStore.resumeAfterSleep()'), 'power lifecycle must route sleep and wake through the network bridge');
assert(qml.includes('selfTestMode === "power-sleep"'), 'power lifecycle needs a dry-run device self-test');
assert(session.includes('RM_WEREAD_POWER_DRY_RUN'), 'device session must support non-suspending power tests');
assert(session.includes('gpio-hall-sensors') && session.includes('/etc/pm/sleep.wakesrc'), 'folio sensor must remain a system suspend wake source');
assert(session.includes('systemctl reset-failed xochitl'), 'returning to the system must clear xochitl start-rate failures');
assert(runner.includes('rm-weread-deploy') && session.includes('release_deploy_lock'), 'deployment must stay awake until the new app owns its wake lock');
assert(runner.includes('rm-were > /sys/power/wake_unlock') && session.includes('release_app_wake_locks'), 'replacement and crash cleanup must release legacy and current app wake locks');

console.log('weread Qt power sleep ok');
