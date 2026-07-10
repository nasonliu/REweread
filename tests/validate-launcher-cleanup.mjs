import fs from 'node:fs';

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const launcher = read('apps/weread-move/rm-weread.sh');
const qtSession = read('scripts/weread-qt-session.sh');

assert(launcher.includes('cleanup_stale_instances'), 'launcher must clean stale app instances before starting');
assert(launcher.includes('app_path="${1}"'), 'launcher cleanup must accept an explicit app path');
assert(launcher.includes('cleanup_stale_instances "${APP_DIR}/app.lua"'), 'launcher cleanup must clear stale legacy WeRead UI instances');
assert(launcher.includes('cleanup_stale_instances "${APP_DIR}/native_app.lua"'), 'launcher cleanup must clear stale native WeRead instances');
assert(!launcher.includes('killall luajit'), 'launcher cleanup must not kill all LuaJIT processes');
assert(launcher.includes('kill -TERM'), 'launcher cleanup must first try graceful termination');
assert(launcher.includes('kill -KILL'), 'launcher cleanup must force stale instances that survive');
assert(launcher.includes('-v self="$$"'), 'launcher cleanup must pass its own shell pid into awk');
assert(launcher.includes('pid != self'), 'launcher cleanup must not kill its own shell');

assert(qtSession.includes('wait_for_exit'), 'Qt session cleanup must wait for app exit through a bounded helper');
assert(qtSession.includes('kill -TERM "$APP_PID"'), 'Qt session cleanup must first ask the app to exit gracefully');
assert(qtSession.includes('kill -KILL "$APP_PID"'), 'Qt session cleanup must force-kill the app if TERM is ignored');
assert(qtSession.includes('systemctl start xochitl'), 'Qt session cleanup must always restore xochitl');
assert(qtSession.includes('systemctl stop --no-block xochitl'), 'Qt session startup must not block forever while stopping xochitl');
assert(qtSession.includes('xochitl-state-before-app'), 'Qt session startup must log xochitl handoff state');
assert(!qtSession.includes('kill "$APP_PID" 2>/dev/null || true\n    wait "$APP_PID"'), 'Qt session cleanup must not block forever on an unbounded wait');

console.log('launcher cleanup ok');
