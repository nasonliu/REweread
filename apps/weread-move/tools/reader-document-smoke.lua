io.stdout:setvbuf("line")

local app_dir = os.getenv("RM_WEREAD_APP_DIR") or "/home/root/xovi/exthome/appload/weread-move"
package.path = app_dir .. "/?.lua;" .. app_dir .. "/lib/?.lua;" .. app_dir .. "/tools/?.lua;" .. package.path

local ChapterCache = require("chapter_cache")
local ReaderDocument = require("reader_document")

local book_id = arg and arg[1] or ""
if book_id == "" then
    io.stderr:write("usage: reader-document-smoke.lua <book-id> [chapter-path]\n")
    os.exit(2)
end
local cache = ChapterCache:new()
local path = arg and arg[2] or cache:first_cached_chapter_path(book_id)
if not path or path == "" then
    io.stderr:write("no cached chapter for " .. tostring(book_id) .. "\n")
    os.exit(1)
end

local xhtml = cache:read_chapter(path)
if not xhtml or xhtml == "" then
    io.stderr:write("empty cached chapter: " .. tostring(path) .. "\n")
    os.exit(1)
end

local document = ReaderDocument.from_xhtml(xhtml)
local pages = ReaderDocument.paginate(document, {
    chars_per_line = 24,
    lines_per_page = 18,
})

local first_text = ""
for _, block in ipairs(document.blocks or {}) do
    if block.text and block.text ~= "" then
        first_text = block.text
        break
    end
end

print("chapter=" .. tostring(path))
print("blocks=" .. tostring(#(document.blocks or {})))
print("pages=" .. tostring(#pages))
print("first_text=" .. tostring(first_text):sub(1, 80))
