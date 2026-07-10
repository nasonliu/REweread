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
local Client = require("lib.client")
local BookInfoService = require("book_info_service")
local BookStatusStore = require("book_status_store")
local ReviewService = require("review_service")

local function usage()
    io.stderr:write("usage: refresh-detail.lua <bookId>\n")
    os.exit(2)
end

local book_id = arg and arg[1]
if not book_id or book_id == "" then
    usage()
end

local config = ConfigBridge:new()
local status_store = BookStatusStore:new()

print("bookId=" .. tostring(book_id))

local ok_progress, progress_or_error = pcall(function()
    config:reload()
    local result = Client:new(config):gateway("/book/getprogress", { bookId = tostring(book_id) })
    local book = type(result) == "table" and result.book or {}
    local progress = tonumber(book.progress or result.progress or 0) or 0
    return math.max(0, math.min(100, progress))
end)

if ok_progress then
    status_store:update(book_id, { remoteProgress = progress_or_error })
    print("state=progress value=" .. string.format("%.2f", progress_or_error))
else
    print("state=progress-failed")
end

local ok_info, info = pcall(function()
    config:reload()
    return BookInfoService:new(config):load(book_id)
end)

if ok_info and type(info) == "table" then
    info.infoUpdatedAt = info.updatedAt
    status_store:update(book_id, info)
    print("state=book-info")
else
    status_store:update(book_id, {
        infoState = "failed",
        lastInfoError = tostring(info or "book info unavailable"),
    })
    print("state=book-info-failed")
end

local ok_reviews, reviews = pcall(function()
    config:reload()
    return ReviewService:new(config):load_public_reviews(book_id, ReviewService.types.Recommended, 10)
end)

if ok_reviews and type(reviews) == "table" then
    status_store:save_reviews(book_id, reviews)
    print("state=reviews count=" .. tostring(#(reviews.reviews or {})))
else
    status_store:mark_reviews_failed(book_id, reviews)
    print("state=reviews-failed")
end

print("state=done")
