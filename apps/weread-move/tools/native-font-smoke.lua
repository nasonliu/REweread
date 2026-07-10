io.stdout:setvbuf("line")

local app_dir = os.getenv("RM_WEREAD_APP_DIR") or "/home/root/xovi/exthome/appload/weread-move"
package.path = app_dir .. "/?.lua;" .. app_dir .. "/lib/?.lua;" .. app_dir .. "/tools/?.lua;" .. package.path

local ChapterCache = require("chapter_cache")
local NativeFont = require("native_font")
local NativePaginator = require("native_paginator")
local NativeRaster = require("native_raster")
local ReaderDocument = require("reader_document")

local function env_number(name, fallback)
    return math.floor(tonumber(os.getenv(name) or "") or fallback)
end

local typography = {
    font_size = env_number("RM_WEREAD_FONT_SIZE", 18),
    heading_size = env_number("RM_WEREAD_HEADING_SIZE", 22),
    line_height = env_number("RM_WEREAD_LINE_HEIGHT", 24),
    heading_line_height = env_number("RM_WEREAD_HEADING_LINE_HEIGHT", 26),
    margin = env_number("RM_WEREAD_MARGIN", 22),
    paragraph_gap = env_number("RM_WEREAD_PARAGRAPH_GAP", 10),
}

local book_id = os.getenv("RM_WEREAD_NATIVE_BOOK_ID") or ""
if book_id == "" then
    error("RM_WEREAD_NATIVE_BOOK_ID is required")
end
local out_path = os.getenv("RM_WEREAD_NATIVE_FONT_SMOKE_OUT") or "/tmp/native-reader-font.ppm"
local cache = ChapterCache:new()
local path = cache:first_cached_chapter_path(book_id)
if not path then
    error("no cached chapter for " .. tostring(book_id))
end

local document = ReaderDocument.from_xhtml(cache:read_chapter(path))
local pages = NativePaginator.paginate(document, {
    page_width = 360,
    page_height = 540,
    font_size = typography.font_size,
    heading_size = typography.heading_size,
    body_line_height = typography.line_height,
    heading_line_height = typography.heading_line_height,
    margin = typography.margin,
    paragraph_gap = typography.paragraph_gap,
})

local raster = NativeRaster:new{ width = 360, height = 540 }
local font = NativeFont:new{ size = 18 }
local rendered = raster:draw_reader_page(pages[1] or { items = {} }, {
    page_number = "1/" .. tostring(#pages),
    font_size = typography.font_size,
    heading_size = typography.heading_size,
    body_line_height = typography.line_height,
    heading_line_height = typography.heading_line_height,
    margin = typography.margin,
    paragraph_gap = typography.paragraph_gap,
})
raster:write_ppm(out_path)

print("font_smoke=ok")
print("bookId=" .. tostring(book_id))
print("chapter=" .. tostring(path))
print("pages=" .. tostring(#pages))
print("fontGlyphs=" .. tostring(rendered.fontGlyphs or 0))
print("typography=font_size=" .. tostring(typography.font_size) .. ",line_height=" .. tostring(typography.line_height) .. ",margin=" .. tostring(typography.margin))
print("font=" .. tostring(font and font.path or ""))
print("glyphYi=" .. tostring(font and font:glyph_index(0x4f0a) or 0))
print("glyphA=" .. tostring(font and font:glyph_index(65) or 0))
print("out=" .. tostring(out_path))
