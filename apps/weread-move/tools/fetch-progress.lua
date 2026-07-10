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

local book_id = arg and arg[1]
if not book_id or book_id == "" then
    io.stderr:write("usage: fetch-progress.lua <bookId>\n")
    os.exit(2)
end

local function fail(message)
    print("state=error message=" .. tostring(message or "unknown"))
    os.exit(1)
end

local ok, err = pcall(function()
    local config = ConfigBridge:new()
    if not config:is_api_configured() then
        error("api key missing")
    end

    local client = Client:new(config)
    local result = client:gateway("/book/getprogress", { bookId = tostring(book_id) })
    local book = type(result) == "table" and result.book or {}
    local progress = tonumber(book.progress or result.progress or 0) or 0
    progress = math.max(0, math.min(100, progress))
    print("state=done bookId=" .. tostring(book_id) .. " progress=" .. string.format("%.2f", progress))
end)

if not ok then
    fail(err)
end
