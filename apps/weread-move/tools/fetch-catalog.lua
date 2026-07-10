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
local BookStatusStore = require("book_status_store")
local DownloadManager = require("download_manager")
local Json = require("json_util")

local function usage()
    io.stderr:write("usage: fetch-catalog.lua <bookId> [title]\n")
    os.exit(2)
end

local function text(value)
    return tostring(value or "")
end

local book_id = arg and arg[1]
if not book_id or book_id == "" then
    usage()
end

local title = arg and arg[2] or book_id
local config = ConfigBridge:new()
local status_store = BookStatusStore:new()
local manager = DownloadManager:new{
    config = config,
    status_store = status_store,
}

local ok, result = pcall(function()
    config:reload()
    return manager:probe_catalog({
        bookId = book_id,
        book_id = book_id,
        title = title,
    })
end)

if not ok then
    print(Json.encode({
        state = "error",
        message = text(result),
    }))
    os.exit(1)
end

local chapters = result or {}
for index, chapter in ipairs(chapters) do
    local row = {
        state = "chapter",
        index = index,
        chapterUid = text(chapter.chapterUid or chapter.uid or chapter.chapter_uid),
        title = text(chapter.title ~= "" and chapter.title or chapter.chapterName),
        level = tonumber(chapter.level or chapter.chapterLevel or 0) or 0,
        wordCount = tonumber(chapter.wordCount or chapter.words or 0) or 0,
        chapterIdx = tonumber(chapter.chapterIdx or chapter.idx or index) or index,
    }
    if row.title == "" then
        row.title = "第 " .. tostring(index) .. " 章"
    end
    print(Json.encode(row))
end

print(Json.encode({
    state = "done",
    count = #chapters,
}))
