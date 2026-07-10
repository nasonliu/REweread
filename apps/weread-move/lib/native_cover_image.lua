local ffi = require("ffi")

ffi.cdef[[
typedef void *tjhandle;
void *malloc(size_t);
void free(void *);
typedef unsigned int png_uint_32;
typedef int png_int_32;
typedef const void *png_const_voidp;
typedef const void *png_const_colorp;
tjhandle tj3Init(int);
int tj3Set(tjhandle, int, int);
int tj3Get(tjhandle, int);
int tj3DecompressHeader(tjhandle, const unsigned char *, size_t);
int tj3Decompress8(tjhandle, const unsigned char *, size_t, unsigned char *, int, int);
void tj3Destroy(tjhandle);
typedef struct png_control *png_controlp;
typedef struct {
  png_controlp opaque;
  png_uint_32 version;
  png_uint_32 width;
  png_uint_32 height;
  png_uint_32 format;
  png_uint_32 flags;
  png_uint_32 colormap_entries;
  png_uint_32 warning_or_error;
  char message[64];
} png_image, *png_imagep;
int png_image_begin_read_from_memory(png_imagep, png_const_voidp, size_t);
int png_image_finish_read(png_imagep, png_const_colorp, void *, png_int_32, void *);
void png_image_free(png_imagep);
]]

local NativeImage = {}
local C = ffi.C

local PNG_IMAGE_VERSION = 1
local PNG_FORMAT_RGBA = 3
local TJINIT_DECOMPRESS = 1
local TJPARAM_JPEGWIDTH = 5
local TJPARAM_JPEGHEIGHT = 6
local TJPARAM_FASTUPSAMPLE = 9
local TJPARAM_FASTDCT = 10
local TJPF_RGB = 0

local function file_exists(path)
    if not path or path == "" then return false end
    local file = io.open(path, "rb")
    if not file then return false end
    local size = file:seek("end") or 0
    file:close()
    return size > 0
end

local function ensure_ffi_loadlib()
    if ffi.loadlib then return true end
    local ok = pcall(require, "ffi/loadlib")
    return ok and ffi.loadlib ~= nil
end

local turbojpeg = nil
local libpng = nil

local function load_turbojpeg()
    if turbojpeg then
        return turbojpeg
    end
    if not ensure_ffi_loadlib() then
        return nil, "missing ffi/loadlib"
    end
    local ok, lib = pcall(function()
        return ffi.loadlib("turbojpeg", "0.4.0", "turbojpeg", "0.3.0", "turbojpeg")
    end)
    if not ok then
        return nil, lib
    end
    turbojpeg = lib
    return turbojpeg
end

local function load_png()
    if libpng then
        return libpng
    end
    if not ensure_ffi_loadlib() then
        return nil, "missing ffi/loadlib"
    end
    local ok, lib = pcall(function()
        return ffi.loadlib("png16", "16", "png")
    end)
    if not ok then
        return nil, lib
    end
    libpng = lib
    return libpng
end

local function read_all(path)
    local file = io.open(path, "rb")
    if not file then
        return nil, "could not open cover"
    end
    local data = file:read("*a")
    file:close()
    return data
end

local function is_png(data)
    return tostring(data or ""):sub(1, 8) == "\137PNG\r\n\26\n"
end

local function flatten_rgba_to_rgb(rgba_data, width, height)
    local stride = width * 3
    local size = stride * height
    local rgb_data = C.malloc(size)
    if rgb_data == nil then
        return nil, "PNG RGB allocation failed"
    end
    local rgb = ffi.cast("uint8_t *", rgb_data)
    for i = 0, width * height - 1 do
        local src = i * 4
        local dst = i * 3
        local alpha = tonumber(rgba_data[src + 3]) or 255
        local inv = 255 - alpha
        rgb[dst] = math.floor((tonumber(rgba_data[src]) or 0) * alpha / 255 + inv + 0.5)
        rgb[dst + 1] = math.floor((tonumber(rgba_data[src + 1]) or 0) * alpha / 255 + inv + 0.5)
        rgb[dst + 2] = math.floor((tonumber(rgba_data[src + 2]) or 0) * alpha / 255 + inv + 0.5)
    end
    return rgb_data, stride
end

function NativeImage.open_png(path, png_data)
    local png, load_err = load_png()
    if not png then
        return nil, load_err
    end
    local image = ffi.new("png_image")
    image.version = PNG_IMAGE_VERSION
    local source = ffi.cast("const unsigned char *", png_data)
    if png.png_image_begin_read_from_memory(image, source, #png_data) == 0 then
        return nil, "reading PNG header"
    end
    image.format = PNG_FORMAT_RGBA
    local width = tonumber(image.width)
    local height = tonumber(image.height)
    local rgba_stride = width * 4
    local rgba_size = rgba_stride * height
    local rgba_data = C.malloc(rgba_size)
    if rgba_data == nil then
        png.png_image_free(image)
        return nil, "PNG RGBA allocation failed"
    end
    if png.png_image_finish_read(image, nil, rgba_data, rgba_stride, nil) == 0 then
        C.free(rgba_data)
        png.png_image_free(image)
        return nil, "decoding PNG file"
    end
    local rgb_data, stride_or_err = flatten_rgba_to_rgb(ffi.cast("uint8_t *", rgba_data), width, height)
    C.free(rgba_data)
    if not rgb_data then
        return nil, stride_or_err
    end
    return {
        path = path,
        width = width,
        height = height,
        ncomp = 3,
        stride = stride_or_err,
        data = ffi.gc(ffi.cast("uint8_t *", rgb_data), C.free),
        _png = png_data,
    }
end

function NativeImage.open_jpeg(path, jpeg_data)
    local tj, load_err = load_turbojpeg()
    if not tj then
        return nil, load_err
    end
    local handle = tj.tj3Init(TJINIT_DECOMPRESS)
    if handle == nil then
        return nil, "no TurboJPEG decompressor"
    end
    tj.tj3Set(handle, TJPARAM_FASTUPSAMPLE, 1)
    tj.tj3Set(handle, TJPARAM_FASTDCT, 1)
    local source = ffi.cast("const unsigned char *", jpeg_data)
    if tj.tj3DecompressHeader(handle, source, #jpeg_data) < 0 then
        tj.tj3Destroy(handle)
        return nil, "reading JPEG header"
    end
    local width = tonumber(tj.tj3Get(handle, TJPARAM_JPEGWIDTH))
    local height = tonumber(tj.tj3Get(handle, TJPARAM_JPEGHEIGHT))
    local stride = width * 3
    local size = stride * height
    local data = C.malloc(size)
    if data == nil then
        tj.tj3Destroy(handle)
        return nil, "cover allocation failed"
    end
    if tj.tj3Decompress8(handle, source, #jpeg_data, ffi.cast("unsigned char *", data), stride, TJPF_RGB) < 0 then
        C.free(data)
        tj.tj3Destroy(handle)
        return nil, "decoding JPEG file"
    end
    tj.tj3Destroy(handle)
    return {
        path = path,
        width = width,
        height = height,
        ncomp = 3,
        stride = stride,
        data = ffi.gc(ffi.cast("uint8_t *", data), C.free),
        _jpeg = jpeg_data,
    }
end

function NativeImage.open(path)
    if not file_exists(path) then
        return nil, "missing cover"
    end
    local image_data, read_err = read_all(path)
    if not image_data then
        return nil, read_err
    end
    if is_png(image_data) then
        return NativeImage.open_png(path, image_data)
    end
    return NativeImage.open_jpeg(path, image_data)
end

function NativeImage.sample(image, x, y)
    if not image or not image.data then
        return nil
    end
    local sx = math.min(image.width, math.max(1, math.floor(x or 1)))
    local sy = math.min(image.height, math.max(1, math.floor(y or 1)))
    local offset = (sy - 1) * image.stride + (sx - 1) * image.ncomp
    return {
        tonumber(image.data[offset]) or 0,
        tonumber(image.data[offset + 1]) or 0,
        tonumber(image.data[offset + 2]) or 0,
    }
end

return NativeImage
