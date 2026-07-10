io.stdout:setvbuf("line")
os.setlocale("C", "numeric")

local app_dir = os.getenv("RM_WEREAD_APP_DIR") or "/home/root/xovi/exthome/appload/weread-move"
local koreader_dir = os.getenv("KO_DIR") or "/home/root/xovi/exthome/appload/koreader"
package.path = app_dir .. "/?.lua;" .. app_dir .. "/lib/?.lua;" .. app_dir .. "/views/?.lua;" .. app_dir .. "/tools/?.lua;" .. package.path
package.path =
    app_dir .. "/../../third_party/weread.koplugin/?.lua;" ..
    app_dir .. "/../../third_party/weread.koplugin/lib/?.lua;" ..
    "/home/root/xovi/exthome/appload/koreader/plugins/weread.koplugin/?.lua;" ..
    "/home/root/xovi/exthome/appload/koreader/plugins/weread.koplugin/lib/?.lua;" ..
    package.path

local KoreaderPaths = require("koreader_paths")
KoreaderPaths.append(koreader_dir)

local ConfigBridge = require("config_bridge")
local ShelfService = require("shelf_service")
local ShelfCache = require("shelf_cache")
local CoverCache = require("cover_cache")

local cover_limit = tonumber(os.getenv("RM_WEREAD_COVER_LIMIT") or "27") or 27
local config = ConfigBridge:new()
local shelf_cache = ShelfCache:new()

local ok, books_or_error = pcall(function()
    config:reload()
    return ShelfService:new(config):load_shelf()
end)

if not ok then
    print("state=error phase=shelf message=" .. tostring(books_or_error))
    os.exit(1)
end

local books = books_or_error or {}
shelf_cache:save_shelf(books)
print("state=shelf count=" .. tostring(#books))

local ok_covers, cover_count_or_error = pcall(function()
    return CoverCache:new(config, shelf_cache):ensure_first_covers(books, cover_limit)
end)

if ok_covers then
    print("state=covers count=" .. tostring(cover_count_or_error or 0))
else
    print("state=covers-failed message=" .. tostring(cover_count_or_error))
end

print("state=done")
