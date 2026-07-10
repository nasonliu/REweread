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
local Json = require("json_util")

local mode = tostring((arg and arg[1]) or "")
local keyword = tostring((arg and arg[2]) or "")

local function emit(row)
    print(Json.encode(row))
end

local function fail(message)
    emit({ state = "error", message = tostring(message or "unknown") })
    os.exit(1)
end

local function text(value)
    return tostring(value or "")
end

local function number(value)
    return tonumber(value or 0) or 0
end

local function trim(value)
    return text(value):gsub("^%s+", ""):gsub("%s+$", "")
end

local function truncate(value, max_len)
    value = trim(value)
    if #value <= max_len then
        return value
    end
    return value:sub(1, max_len)
end

local function emit_book(kind, rank, info, extra)
    info = info or {}
    extra = extra or {}
    local book_id = trim(info.bookId)
    if book_id == "" then
        return false
    end
    emit({
        state = "row",
        kind = kind,
        rank = rank,
        bookId = book_id,
        title = trim(info.title),
        author = trim(info.author),
        cover = trim(info.cover),
        intro = truncate(info.intro, 140),
        category = trim(info.category),
        rating = number(info.newRating or extra.newRating),
        readingCount = number(info.readingCount or extra.readingCount),
        reason = trim(extra.reason),
    })
    return true
end

local function run_recommend(client)
    local result = client:gateway("/book/recommend", { count = 12, maxIdx = 0 })
    local books = type(result) == "table" and result.books or {}
    local count = 0
    for index, entry in ipairs(books or {}) do
        if emit_book("recommendation", index, entry, { reason = entry.reason }) then
            count = count + 1
        end
    end
    emit({ state = "done", mode = "recommend", count = count })
end

local function run_search(client)
    keyword = trim(keyword)
    if keyword == "" then
        error("empty keyword")
    end

    local result = client:gateway("/store/search", {
        keyword = keyword,
        scope = 10,
        maxIdx = 0,
        count = 12,
    })
    local groups = type(result) == "table" and result.results or {}
    local count = 0
    for _, group in ipairs(groups or {}) do
        for _, entry in ipairs(group.books or {}) do
            local info = entry.bookInfo or entry
            if emit_book("search", count + 1, info, entry) then
                count = count + 1
            end
        end
    end
    emit({ state = "done", mode = "search", count = count })
end

local ok, err = pcall(function()
    if mode ~= "recommend" and mode ~= "search" then
        error("usage: discover-books.lua recommend|search [keyword]")
    end

    local config = ConfigBridge:new()
    if not config:is_api_configured() then
        error("api key missing")
    end

    local client = Client:new(config)
    if mode == "search" then
        run_search(client)
    else
        run_recommend(client)
    end
end)

if not ok then
    fail(err)
end
