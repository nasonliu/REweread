local ffi = require("ffi")
local bit = require("bit")

ffi.cdef[[
typedef signed long FT_Pos;
typedef signed long FT_Long;
typedef unsigned long FT_ULong;
typedef unsigned int FT_UInt;
typedef signed int FT_Int;
typedef signed int FT_Error;
typedef struct FT_LibraryRec_ *FT_Library;
typedef struct FT_FaceRec_ *FT_Face;
typedef struct FT_GlyphSlotRec_ *FT_GlyphSlot;
typedef struct FT_SizeRec_ *FT_Size;
typedef struct FT_CharMapRec_ *FT_CharMap;
typedef struct FT_DriverRec_ *FT_Driver;
typedef struct FT_MemoryRec_ *FT_Memory;
typedef struct FT_StreamRec_ *FT_Stream;
typedef struct FT_Face_InternalRec_ *FT_Face_Internal;
typedef struct FT_Slot_InternalRec_ *FT_Slot_Internal;
typedef struct FT_SubGlyphRec_ *FT_SubGlyph;
typedef struct FT_Size_InternalRec_ *FT_Size_Internal;
typedef struct FT_Bitmap_Size_ FT_Bitmap_Size;
typedef struct FT_Vector_ {
  FT_Pos x;
  FT_Pos y;
} FT_Vector;
typedef struct FT_BBox_ {
  FT_Pos xMin;
  FT_Pos yMin;
  FT_Pos xMax;
  FT_Pos yMax;
} FT_BBox;
typedef struct FT_Generic_ {
  void *data;
  void (*finalizer)(void *);
} FT_Generic;
typedef struct FT_Bitmap_ {
  unsigned int rows;
  unsigned int width;
  int pitch;
  unsigned char *buffer;
  unsigned short num_grays;
  unsigned char pixel_mode;
  unsigned char palette_mode;
  void *palette;
} FT_Bitmap;
typedef struct FT_Glyph_Metrics_ {
  FT_Pos width;
  FT_Pos height;
  FT_Pos horiBearingX;
  FT_Pos horiBearingY;
  FT_Pos horiAdvance;
  FT_Pos vertBearingX;
  FT_Pos vertBearingY;
  FT_Pos vertAdvance;
} FT_Glyph_Metrics;
typedef struct FT_Outline_ {
  unsigned short n_contours;
  unsigned short n_points;
  FT_Vector *points;
  unsigned char *tags;
  unsigned short *contours;
  int flags;
} FT_Outline;
typedef struct FT_GlyphSlotRec_ {
  FT_Library library;
  FT_Face face;
  FT_GlyphSlot next;
  FT_UInt glyph_index;
  FT_Generic generic;
  FT_Glyph_Metrics metrics;
  FT_Long linearHoriAdvance;
  FT_Long linearVertAdvance;
  FT_Vector advance;
  unsigned int format;
  FT_Bitmap bitmap;
  FT_Int bitmap_left;
  FT_Int bitmap_top;
  FT_Outline outline;
  FT_UInt num_subglyphs;
  FT_SubGlyph subglyphs;
  void *control_data;
  long control_len;
  FT_Pos lsb_delta;
  FT_Pos rsb_delta;
  void *other;
  FT_Slot_Internal internal;
} FT_GlyphSlotRec;
typedef struct FT_ListRec_ {
  void *head;
  void *tail;
} FT_ListRec;
typedef struct FT_FaceRec_ {
  FT_Long num_faces;
  FT_Long face_index;
  FT_Long face_flags;
  FT_Long style_flags;
  FT_Long num_glyphs;
  char *family_name;
  char *style_name;
  FT_Int num_fixed_sizes;
  FT_Bitmap_Size *available_sizes;
  FT_Int num_charmaps;
  FT_CharMap *charmaps;
  FT_Generic generic;
  FT_BBox bbox;
  unsigned short units_per_EM;
  signed short ascender;
  signed short descender;
  signed short height;
  signed short max_advance_width;
  signed short max_advance_height;
  signed short underline_position;
  signed short underline_thickness;
  FT_GlyphSlot glyph;
  FT_Size size;
  FT_CharMap charmap;
  FT_Driver driver;
  FT_Memory memory;
  FT_Stream stream;
  FT_ListRec sizes_list;
  FT_Generic autohint;
  void *extensions;
  FT_Face_Internal internal;
} FT_FaceRec;
FT_Error FT_Init_FreeType(FT_Library *);
FT_Error FT_Done_Library(FT_Library);
FT_Error FT_New_Face(FT_Library, const char *, FT_Long, FT_Face *);
FT_Error FT_Done_Face(FT_Face);
FT_Error FT_Set_Pixel_Sizes(FT_Face, FT_UInt, FT_UInt);
FT_Error FT_Select_Charmap(FT_Face, unsigned int);
FT_UInt FT_Get_Char_Index(FT_Face, FT_ULong);
FT_Error FT_Load_Char(FT_Face, FT_ULong, int);
void FT_GlyphSlot_Embolden(FT_GlyphSlot);
]]

local NativeFont = {}
NativeFont.__index = NativeFont

local FT_LOAD_RENDER = 4
local FT_LOAD_TARGET_LIGHT = 65536
local FT_ENCODING_UNICODE = 1970170211

local freetype = nil

local function ensure_ffi_loadlib()
    if ffi.loadlib then return true end
    local ok = pcall(require, "ffi/loadlib")
    return ok and ffi.loadlib ~= nil
end

local function load_freetype()
    if freetype then
        return freetype
    end
    if not ensure_ffi_loadlib() then
        return nil, "missing ffi/loadlib"
    end
    local ok, lib = pcall(function()
        return ffi.loadlib("freetype", "6")
    end)
    if not ok then
        return nil, lib
    end
    freetype = lib
    return freetype
end

local function file_exists(path)
    if not path or path == "" then return false end
    local file = io.open(path, "rb")
    if not file then return false end
    file:close()
    return true
end

local function default_font_path()
    local configured = os.getenv("RM_WEREAD_NATIVE_FONT")
    if file_exists(configured) then
        return configured
    end
    local candidates = {
        "/home/root/weread-qt/fonts/lxgw-wenkai.ttf",
        "/home/root/.local/share/fonts/lxgw-wenkai/lxgw-wenkai.ttf",
        "/home/root/.local/share/fonts/wqy-microhei/wqy-microhei.ttc",
        "/home/root/.local/share/fonts/wqy-zenhei/wqy-zenhei.ttc",
        "/home/root/.local/share/fonts/LXGWWenKai-Regular.ttf",
        "/home/root/.local/share/fonts/LXGWNeoZhiSong.ttf",
        "/home/root/.local/share/fonts/Songti.ttc",
        "/home/root/xovi/exthome/appload/koreader/fonts/noto/NotoSansCJKsc-Regular.otf",
        "/usr/share/fonts/ttf/noto/NotoSans-Regular.ttf",
    }
    for _, path in ipairs(candidates) do
        if file_exists(path) then
            return path
        end
    end
    return candidates[#candidates]
end

local function utf8_codepoints(text)
    local codepoints = {}
    text = tostring(text or "")
    local i = 1
    while i <= #text do
        local c = text:byte(i)
        local code
        if c < 0x80 then
            code = c
            i = i + 1
        elseif c < 0xE0 then
            code = (c - 0xC0) * 0x40 + (text:byte(i + 1) - 0x80)
            i = i + 2
        elseif c < 0xF0 then
            code = (c - 0xE0) * 0x1000 + (text:byte(i + 1) - 0x80) * 0x40 + (text:byte(i + 2) - 0x80)
            i = i + 3
        else
            code = (c - 0xF0) * 0x40000 + (text:byte(i + 1) - 0x80) * 0x1000 + (text:byte(i + 2) - 0x80) * 0x40 + (text:byte(i + 3) - 0x80)
            i = i + 4
        end
        table.insert(codepoints, code)
    end
    return codepoints
end

function NativeFont:new(opts)
    opts = opts or {}
    local ft, err = load_freetype()
    if not ft then
        return nil, err
    end
    local library_ref = ffi.new("FT_Library[1]")
    if ft.FT_Init_FreeType(library_ref) ~= 0 then
        return nil, "FT_Init_FreeType failed"
    end
    local path = opts.path or default_font_path()
    local face_ref = ffi.new("FT_Face[1]")
    if ft.FT_New_Face(library_ref[0], path, 0, face_ref) ~= 0 then
        ft.FT_Done_Library(library_ref[0])
        return nil, "FT_New_Face failed: " .. tostring(path)
    end
    ft.FT_Select_Charmap(face_ref[0], FT_ENCODING_UNICODE)
    local size = tonumber(opts.size or 18) or 18
    if ft.FT_Set_Pixel_Sizes(face_ref[0], 0, size) ~= 0 then
        ft.FT_Done_Face(face_ref[0])
        ft.FT_Done_Library(library_ref[0])
        return nil, "FT_Set_Pixel_Sizes failed"
    end
    local eink_contrast = opts.eink_contrast ~= false
    return setmetatable({
        ft = ft,
        library = ffi.gc(library_ref[0], ft.FT_Done_Library),
        face = ffi.gc(face_ref[0], ft.FT_Done_Face),
        path = path,
        size = size,
        color = opts.color or { 0, 0, 0 },
        eink_contrast = eink_contrast,
        embolden = opts.embolden ~= false,
        alpha_floor = eink_contrast and (tonumber(opts.alpha_floor or 20) or 20) or 0,
        alpha_gamma = eink_contrast and (tonumber(opts.alpha_gamma or 0.78) or 0.78) or 1,
        glyphs = 0,
    }, self)
end

local function blend_channel(dst, src, alpha)
    return math.floor(dst + (src - dst) * alpha / 255 + 0.5)
end

function NativeFont:apply_embolden(glyph)
    if not self.embolden or not glyph then
        return false
    end
    local ok = pcall(function()
        self.ft.FT_GlyphSlot_Embolden(glyph)
    end)
    return ok
end

function NativeFont:adjust_alpha(alpha)
    alpha = tonumber(alpha) or 0
    if alpha <= 0 then
        return 0
    end
    local gamma = tonumber(self.alpha_gamma or 1) or 1
    if gamma > 0 and gamma ~= 1 then
        alpha = math.floor(((alpha / 255) ^ gamma) * 255 + 0.5)
    end
    local floor = tonumber(self.alpha_floor or 0) or 0
    if alpha > 0 and alpha < floor then
        alpha = floor
    end
    if alpha > 255 then
        return 255
    end
    return math.floor(alpha)
end

function NativeFont:draw_glyph(raster, glyph, x, baseline_y, color)
    local bitmap = glyph.bitmap
    if bitmap.width == 0 or bitmap.rows == 0 or bitmap.buffer == nil then
        return
    end
    local left = tonumber(glyph.bitmap_left)
    local top = tonumber(glyph.bitmap_top)
    local pitch = tonumber(bitmap.pitch)
    color = color or self.color
    for row = 0, tonumber(bitmap.rows) - 1 do
        for col = 0, tonumber(bitmap.width) - 1 do
            local alpha = self:adjust_alpha(bitmap.buffer[row * pitch + col])
            if alpha > 0 then
                local px = x + left + col
                local py = baseline_y - top + row
                if px >= 1 and px <= raster.width and py >= 1 and py <= raster.height then
                    local old = raster.pixels[py][px] or { 255, 255, 255 }
                    raster:set_pixel(px, py, {
                        blend_channel(old[1], color[1], alpha),
                        blend_channel(old[2], color[2], alpha),
                        blend_channel(old[3], color[3], alpha),
                    })
                end
            end
        end
    end
end

function NativeFont:draw_text(raster, x, y, text, opts)
    opts = opts or {}
    local cursor = math.floor(x or 1)
    local baseline_y = math.floor((y or 1) + (opts.baseline or self.size))
    local max_x = opts.max_x or raster.width
    local color = opts.color or self.color
    local glyphs = 0
    for _, code in ipairs(utf8_codepoints(text)) do
        if code == 10 then
            break
        end
        local glyph_index = self.ft.FT_Get_Char_Index(self.face, code)
        if glyph_index ~= 0 and self.ft.FT_Load_Char(self.face, code, bit.bor(FT_LOAD_RENDER, FT_LOAD_TARGET_LIGHT)) == 0 then
            local glyph = self.face.glyph
            self:apply_embolden(glyph)
            local advance = math.max(1, math.floor(tonumber(glyph.advance.x) / 64))
            if cursor + advance > max_x then
                break
            end
            self:draw_glyph(raster, glyph, cursor, baseline_y, color)
            cursor = cursor + advance
            glyphs = glyphs + 1
        end
    end
    self.glyphs = self.glyphs + glyphs
    return {
        width = cursor - x,
        glyphs = glyphs,
    }
end

function NativeFont:glyph_index(codepoint)
    return tonumber(self.ft.FT_Get_Char_Index(self.face, codepoint)) or 0
end

function NativeFont:measure_codepoint(codepoint)
    local glyph_index = self.ft.FT_Get_Char_Index(self.face, codepoint)
    if glyph_index == 0 then
        return 0
    end
    if self.ft.FT_Load_Char(self.face, codepoint, bit.bor(FT_LOAD_RENDER, FT_LOAD_TARGET_LIGHT)) ~= 0 then
        return 0
    end
    self:apply_embolden(self.face.glyph)
    return math.max(1, math.floor(tonumber(self.face.glyph.advance.x) / 64))
end

function NativeFont:measure_text(text)
    local width = 0
    local glyphs = 0
    for _, code in ipairs(utf8_codepoints(text)) do
        if code == 10 then
            break
        end
        local advance = self:measure_codepoint(code)
        width = width + advance
        if advance > 0 then
            glyphs = glyphs + 1
        end
    end
    return {
        width = width,
        glyphs = glyphs,
    }
end

function NativeFont:wrap_text(text, max_width)
    max_width = math.max(1, tonumber(max_width or 1) or 1)
    local lines = {}
    local current = {}
    local width = 0

    local function flush()
        if #current > 0 then
            table.insert(lines, table.concat(current))
            current = {}
            width = 0
        end
    end

    local function encode_codepoint(code)
        if code < 0x80 then
            return string.char(code)
        elseif code < 0x800 then
            return string.char(0xC0 + math.floor(code / 0x40), 0x80 + (code % 0x40))
        elseif code < 0x10000 then
            return string.char(0xE0 + math.floor(code / 0x1000), 0x80 + (math.floor(code / 0x40) % 0x40), 0x80 + (code % 0x40))
        end
        return string.char(0xF0 + math.floor(code / 0x40000), 0x80 + (math.floor(code / 0x1000) % 0x40), 0x80 + (math.floor(code / 0x40) % 0x40), 0x80 + (code % 0x40))
    end

    local function token_width(token)
        return self:measure_text(token).width
    end

    local function append_token(token)
        if token == " " and #current == 0 then
            return
        end
        local advance = token_width(token)
        if #current > 0 and width + advance > max_width then
            flush()
        end
        if advance > max_width and #token > 1 then
            for _, code in ipairs(utf8_codepoints(token)) do
                append_token(encode_codepoint(code))
            end
        else
            table.insert(current, token)
            width = width + advance
        end
    end

    local codes = utf8_codepoints(text)
    local i = 1
    while i <= #codes do
        local code = codes[i]
        if code == 10 then
            flush()
            i = i + 1
        elseif code < 128 and encode_codepoint(code):match("[%w%p]") then
            local latin_word = {}
            while i <= #codes and codes[i] < 128 and encode_codepoint(codes[i]):match("[%w%p]") do
                table.insert(latin_word, encode_codepoint(codes[i]))
                i = i + 1
            end
            append_token(table.concat(latin_word))
        elseif code < 128 and encode_codepoint(code):match("%s") then
            append_token(" ")
            i = i + 1
        else
            append_token(encode_codepoint(code))
            i = i + 1
        end
    end
    flush()
    if #lines == 0 then
        table.insert(lines, "")
    end
    return lines
end

return NativeFont
