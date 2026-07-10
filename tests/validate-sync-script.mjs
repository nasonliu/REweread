import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { execFileSync } from 'node:child_process';

const script = fs.readFileSync('scripts/sync-weread-app.sh', 'utf8');

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

assert(script.includes('rsync'), 'sync script must use rsync');
assert(script.includes("--exclude='logs/'"), 'sync script must exclude logs');
assert(script.includes("--exclude='state/'"), 'sync script must exclude state');
assert(script.includes("--exclude='*.key'"), 'sync script must exclude key files');
assert(script.includes('/home/root/xovi/exthome/appload'), 'sync target must be AppLoad directory');
assert(script.includes('REMOTE_APP_DIR="${APPLOAD_DIR%/}/weread-move"'), 'sync script must build a normalized remote app dir');
assert(script.includes('^/[A-Za-z0-9._/-]+$'), 'sync script must validate APPLOAD_DIR as an absolute POSIX path');
assert(script.includes('"$APPLOAD_DIR" == *..*'), 'sync script must reject APPLOAD_DIR parent traversal');
assert(!script.includes('wrk-'), 'sync script must not contain real API keys');
assert(!script.includes('wr_skey'), 'sync script must not contain cookies');

fs.accessSync('scripts/sync-weread-app.sh', fs.constants.X_OK);

const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'rm-weread-launcher-'));
try {
  const appDir = path.join(tmpDir, 'app');
  const koDir = path.join(tmpDir, 'ko');
  const capturePath = path.join(tmpDir, 'luajit-arg.txt');
  fs.mkdirSync(appDir);
  fs.mkdirSync(koDir);
  fs.copyFileSync('apps/weread-move/rm-weread.sh', path.join(appDir, 'rm-weread.sh'));
  fs.copyFileSync('apps/weread-move/app.lua', path.join(appDir, 'app.lua'));
  fs.copyFileSync('apps/weread-move/native_app.lua', path.join(appDir, 'native_app.lua'));
  fs.chmodSync(path.join(appDir, 'rm-weread.sh'), 0o755);
  fs.writeFileSync(
    path.join(koDir, 'luajit'),
    '#!/bin/sh\nprintf "%s\\n" "$1" > "$FAKE_LUAJIT_CAPTURE"\nprintf "fake luajit saw %s\\n" "$1"\n',
  );
  fs.chmodSync(path.join(koDir, 'luajit'), 0o755);

  execFileSync('./rm-weread.sh', {
    cwd: appDir,
    env: {
      ...process.env,
      KO_DIR: koDir,
      FAKE_LUAJIT_CAPTURE: capturePath,
    },
  });

  const luajitArg = fs.readFileSync(capturePath, 'utf8').trim();
  assert(path.isAbsolute(luajitArg), 'launcher must pass an absolute native_app.lua path to luajit');
  assert(
    fs.realpathSync(luajitArg) === fs.realpathSync(path.join(appDir, 'native_app.lua')),
    'launcher must pass the temp native_app.lua path to luajit',
  );
  const logPath = path.join(appDir, 'logs', 'rm-weread-native.log');
  assert(fs.readFileSync(logPath, 'utf8').includes('fake luajit saw'), 'launcher must write logs under the app dir');
  assert(fs.readFileSync(capturePath, 'utf8').includes('native_app.lua'), 'launcher must default to the native app');
} finally {
  fs.rmSync(tmpDir, { recursive: true, force: true });
}

console.log('sync script ok');
