import fs from 'node:fs';

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

assert(fs.existsSync('scripts/download-reader-fonts.sh'), 'reader font download script must exist');

const script = read('scripts/download-reader-fonts.sh');
const installer = read('scripts/install-weread-qt-appload.sh');
const font = read('apps/weread-move/lib/native_font.lua');
const runner = read('tests/run-all.mjs');

assert(script.includes('downloads/fonts'), 'font download script must keep font binaries out of the app tree');
assert(script.includes('wqy-microhei-0.2.0-beta.tar.gz'), 'font download script must fetch WenQuanYi Micro Hei');
assert(script.includes('wqy-zenhei-0.9.45.tar.gz'), 'font download script must fetch WenQuanYi Zen Hei');
assert(script.includes('raw.githubusercontent.com/lxgw/LxgwWenKai'), 'font download script must fetch LXGW WenKai from the official GitHub project');
assert(script.includes('LXGW_WENKAI_COMMIT'), 'font download script must pin LXGW WenKai to a commit');
assert(script.includes('LXGWWenKai-Regular.ttf'), 'font download script must stage LXGW WenKai regular TTF');
assert(script.includes('lxgw-wenkai/lxgw-wenkai.ttf'), 'font download script must normalize LXGW WenKai to a stable staged filename');
assert(script.includes('SOURCE_HAN_SANS_COMMIT') && script.includes('SOURCE_HAN_SERIF_COMMIT'), 'font download script must pin both Source Han font sources');
assert(script.includes('source-han-sans-sc/source-han-sans-sc.otf'), 'font download script must normalize Source Han Sans SC');
assert(script.includes('source-han-serif-sc/source-han-serif-sc.otf'), 'font download script must normalize Source Han Serif SC');
assert(script.includes('ChillKai.zip') && script.includes('ChillHuoSong_F.zip'), 'font download script must fetch official Chill archives');
assert(script.includes('ChillKai/ChillKai.ttf') && script.includes('ChillHuoSong_F_Regular.otf'), 'font download script must extract regular Chill faces');
assert(script.includes('CHILL_KAI_FONT_SHA256') && script.includes('CHILL_HUOSONG_FONT_SHA256'), 'font download script must verify extracted Chill font checksums');
assert(script.includes('GOOGLE_FONTS_COMMIT'), 'handwritten Google Fonts must be pinned to a commit');
for (const fontName of ['ma-shan-zheng', 'liu-jian-mao-cao', 'zhi-mang-xing', 'long-cang', 'zcool-kuaile']) {
  assert(script.includes(`${fontName}/${fontName}.ttf`), `font downloader must stage ${fontName}`);
}
assert(script.includes('MA_SHAN_ZHENG_SHA256') && script.includes('LIU_JIAN_MAO_CAO_SHA256')
  && script.includes('ZHI_MANG_XING_SHA256') && script.includes('LONG_CANG_SHA256')
  && script.includes('ZCOOL_KUAILE_SHA256') && script.includes('ZCOOL_KUAILE_URL'), 'handwritten fonts must have fixed checksums and pinned sources');
assert(script.includes('/home/root/.local/share/fonts'), 'font download script must install to the Move user font directory');
assert(script.includes('MOVE_HOST="${MOVE_HOST:-root@10.11.99.1}"'), 'font download script must default to the official USB Move host');
assert(script.includes('rsync'), 'font download script must copy fonts with rsync');
assert(script.includes('sha256sum'), 'font download script must print device-side font checksums');
assert(script.includes('verify_sha256'), 'font download script must verify downloaded font checksums locally');
assert(installer.includes('zcool-kuaile/zcool-kuaile.ttf')
  && installer.includes('fonts/zcool-kuaile.ttf'), 'installer must stage the optional cute handwriting font with the app');
assert(!script.includes('xargs -0'), 'font download script must avoid xargs -0 for BusyBox compatibility');
assert(font.includes('wqy-microhei.ttc'), 'native font candidates must include WenQuanYi Micro Hei');
assert(font.includes('wqy-zenhei.ttc'), 'native font candidates must include WenQuanYi Zen Hei');
assert(font.includes('lxgw-wenkai.ttf'), 'native font candidates must include the normalized LXGW WenKai font');
assert(runner.includes('validate-font-downloads.mjs'), 'run-all must include font download validation');

console.log('font downloads ok');
