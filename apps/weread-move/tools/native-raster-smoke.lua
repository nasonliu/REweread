io.stdout:setvbuf("line")

local app_dir = os.getenv("RM_WEREAD_APP_DIR") or "/home/root/xovi/exthome/appload/weread-move"
package.path = app_dir .. "/?.lua;" .. app_dir .. "/lib/?.lua;" .. app_dir .. "/tools/?.lua;" .. package.path

local ChapterCache = require("chapter_cache")
local NativeRaster = require("native_raster")
local ReaderDocument = require("reader_document")

local book_id = arg and arg[1] or ""
if book_id == "" then
    io.stderr:write("usage: native-raster-smoke.lua <book-id> [output]\n")
    os.exit(2)
end
local output = arg and arg[2] or "/tmp/weread-native-raster.ppm"
local cache = ChapterCache:new()
local path = cache:first_cached_chapter_path(book_id)
if not path then
    io.stderr:write("no cached chapter for " .. tostring(book_id) .. "\n")
    os.exit(1)
end

local xhtml = cache:read_chapter(path)
local document = ReaderDocument.from_xhtml(xhtml)
local pages = ReaderDocument.paginate(document, {
    chars_per_line = 24,
    lines_per_page = 18,
})
local raster = NativeRaster:new{ width = 360, height = 540 }
raster:draw_reader_page(pages[1] or { items = {} })
raster:write_ppm(output)

print("chapter=" .. tostring(path))
print("pages=" .. tostring(#pages))
print("output=" .. tostring(output))
