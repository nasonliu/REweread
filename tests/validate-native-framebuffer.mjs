import fs from 'node:fs';

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const fb = read('apps/weread-move/lib/native_framebuffer.lua');
const smoke = read('apps/weread-move/tools/qtfb-native-smoke.lua');
const runner = read('tests/run-all.mjs');

assert(fb.includes('function NativeFramebuffer:open'), 'native framebuffer must open a framebuffer device');
assert(fb.includes('/dev/fb0'), 'native framebuffer must target the qtfb-shim framebuffer path');
assert(fb.includes('FBIOGET_FSCREENINFO'), 'native framebuffer must read fixed screen info');
assert(fb.includes('FBIOGET_VSCREENINFO'), 'native framebuffer must read variable screen info');
assert(fb.includes('MXCFB_SEND_UPDATE'), 'native framebuffer must trigger qtfb eink updates');
assert(fb.includes('struct mxcfb_update_data'), 'native framebuffer must define mxcfb update data');
assert(fb.includes('update.update_region.width = self.width'), 'native framebuffer refresh must update the full screen width');
assert(fb.includes('update.update_region.height = self.height'), 'native framebuffer refresh must update the full screen height');
assert(fb.includes('/tmp/qtfb.sock'), 'native framebuffer must be able to notify AppLoad qtfb directly');
assert(fb.includes('MESSAGE_UPDATE'), 'native framebuffer must send direct qtfb update messages');
assert(fb.includes('QTFB_KEY'), 'native framebuffer direct repaint must target the AppLoad qtfb key');
assert(fb.includes('shm_open'), 'native framebuffer must map the qtfb shared memory directly');
assert(fb.includes('response.init.shmKeyDefined'), 'native framebuffer must map the shm key returned by AppLoad');
assert(fb.includes('qtfb_socket_fd'), 'native framebuffer must retain the qtfb socket used for the visible surface');
assert(fb.includes('C.send(self.qtfb_socket_fd'), 'native framebuffer must repaint through the original qtfb connection');
assert(fb.includes('C.ioctl(self.fd, C.FBIOPAN_DISPLAY, self.vinfo)'), 'native framebuffer must keep FBIOPAN_DISPLAY as a fallback');
assert(fb.includes('function NativeFramebuffer:blit_raster'), 'native framebuffer must blit native raster pixels');
assert(fb.includes('RGB565'), 'native framebuffer must support qtfb N_RGB565 mode');
assert(!fb.includes('require("runtime")'), 'native framebuffer must not require KOReader runtime');
assert(!fb.includes('require("device")'), 'native framebuffer must not require KOReader device');
assert(!fb.includes('ui/'), 'native framebuffer must not use KOReader UI widgets');
assert(smoke.includes('NativeFramebuffer'), 'qtfb smoke must use native framebuffer');
assert(smoke.includes('NativeRaster'), 'qtfb smoke must render native raster output');
assert(smoke.includes('ReaderDocument.paginate'), 'qtfb smoke must render a real reader page');
assert(runner.includes('validate-native-framebuffer.mjs'), 'run-all must include native framebuffer validation');

console.log('native framebuffer ok');
