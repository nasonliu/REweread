local ffi = require("ffi")
local bit = require("bit")

ffi.cdef[[
static const int O_RDWR = 2;
static const int O_CLOEXEC = 524288;
static const int PROT_READ = 1;
static const int PROT_WRITE = 2;
static const int MAP_SHARED = 1;
static const int MS_SYNC = 4;
static const int AF_UNIX = 1;
static const int SOCK_SEQPACKET = 5;
static const int FBIOGET_FSCREENINFO = 17922;
static const int FBIOGET_VSCREENINFO = 17920;
static const int FBIOPAN_DISPLAY = 17926;
static const int MXCFB_SEND_UPDATE = 1078486574;
static const int UPDATE_MODE_FULL = 1;
static const int WAVEFORM_MODE_AUTO = 257;
static const int TEMP_USE_AMBIENT = 4096;
static const int MESSAGE_INITIALIZE = 0;
static const int MESSAGE_UPDATE = 1;
static const int UPDATE_ALL = 0;
static const int QTFB_N_RGB565 = 6;
struct fb_bitfield {
  unsigned int offset;
  unsigned int length;
  unsigned int msb_right;
};
struct sockaddr_un {
  unsigned short sun_family;
  char sun_path[108];
};
struct qtfb_init_message_contents {
  unsigned int framebufferKey;
  unsigned char framebufferType;
};
struct qtfb_update_region_message_contents {
  int type;
  int x;
  int y;
  int w;
  int h;
};
union qtfb_client_message_contents {
  struct qtfb_init_message_contents init;
  struct qtfb_update_region_message_contents update;
};
struct qtfb_client_message {
  unsigned char type;
  union qtfb_client_message_contents body;
};
struct qtfb_init_message_response_contents {
  int shmKeyDefined;
  size_t shmSize;
};
struct qtfb_server_message {
  unsigned char type;
  struct qtfb_init_message_response_contents init;
};
struct mxcfb_rect {
  unsigned int top;
  unsigned int left;
  unsigned int width;
  unsigned int height;
};
struct mxcfb_alt_buffer_data {
  unsigned int phys_addr;
  unsigned int width;
  unsigned int height;
  struct mxcfb_rect alt_update_region;
};
struct mxcfb_update_data {
  struct mxcfb_rect update_region;
  unsigned int waveform_mode;
  unsigned int update_mode;
  unsigned int update_marker;
  int temp;
  unsigned int flags;
  int dither_mode;
  int quant_bit;
  struct mxcfb_alt_buffer_data alt_buffer_data;
};
struct fb_fix_screeninfo {
  char id[16];
  unsigned long smem_start;
  unsigned int smem_len;
  unsigned int type;
  unsigned int type_aux;
  unsigned int visual;
  unsigned short xpanstep;
  unsigned short ypanstep;
  unsigned short ywrapstep;
  unsigned int line_length;
  unsigned long mmio_start;
  unsigned int mmio_len;
  unsigned int accel;
  unsigned short capabilities;
  unsigned short reserved[2];
};
struct fb_var_screeninfo {
  unsigned int xres;
  unsigned int yres;
  unsigned int xres_virtual;
  unsigned int yres_virtual;
  unsigned int xoffset;
  unsigned int yoffset;
  unsigned int bits_per_pixel;
  unsigned int grayscale;
  struct fb_bitfield red;
  struct fb_bitfield green;
  struct fb_bitfield blue;
  struct fb_bitfield transp;
  unsigned int nonstd;
  unsigned int activate;
  unsigned int height;
  unsigned int width;
  unsigned int accel_flags;
  unsigned int pixclock;
  unsigned int left_margin;
  unsigned int right_margin;
  unsigned int upper_margin;
  unsigned int lower_margin;
  unsigned int hsync_len;
  unsigned int vsync_len;
  unsigned int sync;
  unsigned int vmode;
  unsigned int rotate;
  unsigned int colorspace;
  unsigned int reserved[4];
};
int open(const char *, int, ...);
int close(int);
int ioctl(int, unsigned long, ...);
void *mmap(void *, size_t, int, int, int, long);
int munmap(void *, size_t);
int msync(void *, size_t, int);
int shm_open(const char *, int, unsigned int);
int snprintf(char *, size_t, const char *, ...);
int socket(int, int, int);
int connect(int, const struct sockaddr_un *, unsigned int);
long send(int, const void *, size_t, int);
long recv(int, void *, size_t, int);
char *strerror(int);
]]

local C = ffi.C
local NativeFramebuffer = {}
NativeFramebuffer.__index = NativeFramebuffer

local function map_failed(ptr)
    return tonumber(ffi.cast("intptr_t", ptr)) == -1
end

local function rgb565(color)
    local r = bit.rshift(tonumber(color[1] or 0), 3)
    local g = bit.rshift(tonumber(color[2] or 0), 2)
    local b = bit.rshift(tonumber(color[3] or 0), 3)
    return bit.bor(bit.lshift(r, 11), bit.lshift(g, 5), b)
end

local function qtfb_framebuffer_type()
    local mode = os.getenv("QTFB_SHIM_MODE") or ""
    if mode == "" or mode == "N_RGB565" then
        return C.QTFB_N_RGB565
    end
    return C.QTFB_N_RGB565
end

local function connect_qtfb_socket(key)
    local fd = C.socket(C.AF_UNIX, C.SOCK_SEQPACKET, 0)
    if fd < 0 then
        error("Could not open qtfb socket: " .. ffi.string(C.strerror(ffi.errno())))
    end
    local addr = ffi.new("struct sockaddr_un")
    addr.sun_family = C.AF_UNIX
    ffi.copy(addr.sun_path, "/tmp/qtfb.sock")
    if C.connect(fd, addr, ffi.sizeof(addr)) ~= 0 then
        C.close(fd)
        error("Could not connect /tmp/qtfb.sock: " .. ffi.string(C.strerror(ffi.errno())))
    end
    local init = ffi.new("struct qtfb_client_message")
    init.type = C.MESSAGE_INITIALIZE
    init.body.init.framebufferKey = key
    init.body.init.framebufferType = qtfb_framebuffer_type()
    if C.send(fd, init, ffi.sizeof(init), 0) < 0 then
        C.close(fd)
        error("Could not initialize qtfb framebuffer: " .. ffi.string(C.strerror(ffi.errno())))
    end
    local response = ffi.new("struct qtfb_server_message")
    if C.recv(fd, response, ffi.sizeof(response), 0) < 1 then
        C.close(fd)
        error("Could not receive qtfb framebuffer response: " .. ffi.string(C.strerror(ffi.errno())))
    end
    return fd, response
end

local function open_qtfb_framebuffer(self, key)
    local qtfb_socket_fd, response = connect_qtfb_socket(key)
    local name = ffi.new("char[32]")
    C.snprintf(name, ffi.sizeof(name), "/qtfb_%d", response.init.shmKeyDefined)
    local shm_fd = C.shm_open(name, C.O_RDWR, 0)
    if shm_fd < 0 then
        C.close(qtfb_socket_fd)
        error("Could not open qtfb shm: " .. ffi.string(C.strerror(ffi.errno())))
    end
    local size = tonumber(response.init.shmSize)
    local data = C.mmap(nil, size, bit.bor(C.PROT_READ, C.PROT_WRITE), C.MAP_SHARED, shm_fd, 0)
    if map_failed(data) then
        C.close(shm_fd)
        C.close(qtfb_socket_fd)
        error("mmap qtfb framebuffer failed: " .. ffi.string(C.strerror(ffi.errno())))
    end
    local width = tonumber(os.getenv("RM_WEREAD_FB_WIDTH") or "954") or 954
    local height = tonumber(os.getenv("RM_WEREAD_FB_HEIGHT") or "") or math.floor(size / (width * 2))
    return setmetatable({
        fd = -1,
        qtfb_socket_fd = qtfb_socket_fd,
        shm_fd = shm_fd,
        qtfb_key = key,
        device = "/tmp/qtfb.sock",
        data = data,
        size = size,
        width = width,
        height = height,
        bpp = 16,
        line_length = width * 2,
        update_marker = 1,
    }, self)
end

function NativeFramebuffer:send_qtfb_repaint()
    if not self.qtfb_socket_fd or self.qtfb_socket_fd < 0 then
        return false
    end
    local update = ffi.new("struct qtfb_client_message")
    update.type = C.MESSAGE_UPDATE
    update.body.update.type = C.UPDATE_ALL
    return C.send(self.qtfb_socket_fd, update, ffi.sizeof(update), 0) >= 0
end

function NativeFramebuffer:open(device)
    local qtfb_key = tonumber(os.getenv("QTFB_KEY") or "")
    if qtfb_key then
        return open_qtfb_framebuffer(self, qtfb_key)
    end
    device = device or "/dev/fb0"
    local fd = C.open(device, bit.bor(C.O_RDWR, C.O_CLOEXEC))
    if fd < 0 then
        error("Could not open " .. tostring(device) .. ": " .. ffi.string(C.strerror(ffi.errno())))
    end
    local finfo = ffi.new("struct fb_fix_screeninfo")
    local vinfo = ffi.new("struct fb_var_screeninfo")
    if C.ioctl(fd, C.FBIOGET_FSCREENINFO, finfo) ~= 0 then
        C.close(fd)
        error("FBIOGET_FSCREENINFO failed: " .. ffi.string(C.strerror(ffi.errno())))
    end
    if C.ioctl(fd, C.FBIOGET_VSCREENINFO, vinfo) ~= 0 then
        C.close(fd)
        error("FBIOGET_VSCREENINFO failed: " .. ffi.string(C.strerror(ffi.errno())))
    end
    local size = tonumber(finfo.line_length * vinfo.yres)
    local data = C.mmap(nil, size, bit.bor(C.PROT_READ, C.PROT_WRITE), C.MAP_SHARED, fd, 0)
    if map_failed(data) then
        C.close(fd)
        error("mmap framebuffer failed: " .. ffi.string(C.strerror(ffi.errno())))
    end
    return setmetatable({
        fd = fd,
        device = device,
        finfo = finfo,
        vinfo = vinfo,
        data = data,
        size = size,
        width = tonumber(vinfo.xres),
        height = tonumber(vinfo.yres),
        bpp = tonumber(vinfo.bits_per_pixel),
        line_length = tonumber(finfo.line_length),
        update_marker = 1,
    }, self)
end

function NativeFramebuffer:info()
    return {
        width = self.width,
        height = self.height,
        bpp = self.bpp,
        line_length = self.line_length,
    }
end

function NativeFramebuffer:blit_raster(raster)
    if self.bpp ~= 16 then
        error("Only RGB565 framebuffer is supported for now; got " .. tostring(self.bpp) .. " bpp")
    end
    local out = ffi.cast("uint16_t *", self.data)
    local stride = math.floor(self.line_length / 2)
    local src_w = raster.width
    local src_h = raster.height
    for y = 0, self.height - 1 do
        local sy = math.min(src_h, math.max(1, math.floor(y * src_h / self.height) + 1))
        local row = raster.pixels[sy]
        for x = 0, self.width - 1 do
            local sx = math.min(src_w, math.max(1, math.floor(x * src_w / self.width) + 1))
            out[y * stride + x] = rgb565(row[sx] or { 255, 255, 255 })
        end
    end
end

function NativeFramebuffer:refresh()
    C.msync(self.data, self.size, C.MS_SYNC)
    if self.qtfb_socket_fd then
        self:send_qtfb_repaint()
        return
    end
    local update = ffi.new("struct mxcfb_update_data")
    update.update_region.top = 0
    update.update_region.left = 0
    update.update_region.width = self.width
    update.update_region.height = self.height
    update.waveform_mode = C.WAVEFORM_MODE_AUTO
    update.update_mode = C.UPDATE_MODE_FULL
    update.update_marker = self.update_marker
    update.temp = C.TEMP_USE_AMBIENT
    self.update_marker = self.update_marker + 1
    if C.ioctl(self.fd, C.MXCFB_SEND_UPDATE, update) ~= 0 then
        C.ioctl(self.fd, C.FBIOPAN_DISPLAY, self.vinfo)
    end
end

function NativeFramebuffer:close()
    if self.data then
        C.munmap(self.data, self.size)
        self.data = nil
    end
    if self.fd and self.fd >= 0 then
        C.close(self.fd)
        self.fd = -1
    end
    if self.shm_fd and self.shm_fd >= 0 then
        C.close(self.shm_fd)
        self.shm_fd = -1
    end
    if self.qtfb_socket_fd and self.qtfb_socket_fd >= 0 then
        C.close(self.qtfb_socket_fd)
        self.qtfb_socket_fd = -1
    end
end

return NativeFramebuffer
