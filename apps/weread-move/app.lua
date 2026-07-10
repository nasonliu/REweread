io.stdout:setvbuf("line")
os.setlocale("C", "numeric")

local app_dir = arg and arg[0] and arg[0]:match("^(.*)/[^/]+$") or "."
package.path = app_dir .. "/?.lua;" .. app_dir .. "/lib/?.lua;" .. app_dir .. "/views/?.lua;" .. package.path
package.path =
    app_dir .. "/../../third_party/weread.koplugin/?.lua;" ..
    app_dir .. "/../../third_party/weread.koplugin/lib/?.lua;" ..
    "/home/root/xovi/exthome/appload/koreader/plugins/weread.koplugin/?.lua;" ..
    "/home/root/xovi/exthome/appload/koreader/plugins/weread.koplugin/lib/?.lua;" ..
    package.path

local Runtime = require("runtime")
local rt = Runtime:init({
    app_dir = app_dir,
    app_name = "WeRead",
})

local ConfigBridge = require("config_bridge")
local ShelfService = require("shelf_service")
local ShelfCache = require("shelf_cache")
local CoverCache = require("cover_cache")
local BookOpener = require("book_opener")
local BookStatusStore = require("book_status_store")
local BookDetailView = require("book_detail_view")
local DownloadManager = require("download_manager")
local DownloadQueueView = require("download_queue_view")
local ReaderView = require("reader_view")
local BookInfoService = require("book_info_service")
local ReviewService = require("review_service")
local ShelfGridView = require("shelf_grid_view")
local ErrorView = require("error_view")
local InfoMessage = require("ui/widget/infomessage")
local UIManager = rt.UIManager

local function display_error(err)
    local text = tostring(err or "unknown error")
    text = text:gsub("Authorization:%s*[Bb]earer%s+[%w%._%-]+", "Authorization: Bearer <redacted>")
    text = text:gsub("wrk%-[%w_%-]+", "wrk-<redacted>")
    text = text:gsub("wr_skey=[^;%s]+", "wr_skey=<redacted>")
    text = text:gsub("wr_rt=[^;%s]+", "wr_rt=<redacted>")
    text = text:gsub("wr_vid=[^;%s]+", "wr_vid=<redacted>")
    text = text:gsub("([?&]wr_skey=)[^&%s]+", "%1<redacted>")
    text = text:gsub("([?&]wr_rt=)[^&%s]+", "%1<redacted>")
    text = text:gsub("([?&]wr_vid=)[^&%s]+", "%1<redacted>")
    if #text > 400 then
        text = text:sub(1, 400) .. "..."
    end
    return text
end

local ok_config, config = pcall(function()
    return ConfigBridge:new()
end)
if not ok_config then
    ErrorView.show(UIManager, "Config error:\n" .. display_error(config))
    local exit_code = UIManager:run()
    rt:exit()
    os.exit(exit_code or 1)
end

if config.load_error then
    ErrorView.show(UIManager, "Config error:\n" .. display_error(config.load_error))
    local exit_code = UIManager:run()
    rt:exit()
    os.exit(exit_code or 1)
end

local function load_shelf_online()
    config:reload()
    if config.load_error then
        error(config.load_error)
    end

    local books = ShelfService:new(config):load_shelf()
    local cache = ShelfCache:new()
    cache:save_shelf(books)
    return {
        books = books,
    }
end

local function screenshot_requested()
    local path = os.getenv("RM_WEREAD_SCREENSHOT")
    return path ~= nil and path ~= ""
end

local function schedule_cover_prefetch(books, view, generation)
    if screenshot_requested() then
        return
    end
    local index = 1
    local limit = #(books or {})
    local chunk_size = 1
    local cache = ShelfCache:new()
    local cover_cache = CoverCache:new(config, cache)

    local function view_is_alive()
        return view and (not view.is_active or view:is_active(generation))
    end

    local function mark_dirty()
        if view and view.setBooks then
            view:setBooks(books)
        end
    end

    local function step()
        if not view_is_alive() then
            return
        end

        local processed = 0
        while index <= #(books or {}) and index <= limit and processed < chunk_size do
            if not view_is_alive() then
                return
            end
            pcall(function()
                cover_cache:ensure_cover(books[index])
            end)
            index = index + 1
            processed = processed + 1
        end

        mark_dirty()

        if index <= #(books or {}) and index <= limit and view_is_alive() then
            UIManager:scheduleIn(1, step)
        end
    end

    if view_is_alive() then
        UIManager:scheduleIn(2, step)
    end
end

local cache = ShelfCache:new()
local cached = cache:load_shelf()
local book_status_store = BookStatusStore:new()
local shelf_view
local book_opener
local book_detail_view
local download_queue_view
local reader_view

local function canonical_book_id(book)
    return book and (book.bookId or book.book_id)
end

local function sync_book_status(book)
    local book_id = canonical_book_id(book)
    if book and book_id then
        book.status = book_status_store:get(book_id)
    end
    return book
end

local function attach_book_statuses(books)
    for _, book in ipairs(books or {}) do
        sync_book_status(book)
    end
    return books or {}
end

local function refresh_shelf_statuses()
    if shelf_view and shelf_view.books then
        attach_book_statuses(shelf_view.books)
        shelf_view:setBooks(shelf_view.books)
    end
end

local initial_books = attach_book_statuses(cached and cached.books or {})
local download_manager = DownloadManager:new{
    config = config,
    status_store = book_status_store,
}

local function hydrate_book(book, status)
    status = status or {}
    for _, key in ipairs({
        "intro", "publisher", "publishTime", "isbn", "translator",
        "categoryName", "wordCount", "newRating", "newRatingCount",
    }) do
        if status[key] ~= nil and status[key] ~= "" and (book[key] == nil or book[key] == "" or book[key] == 0) then
            book[key] = status[key]
        end
    end
    return book
end

local function review_type_code(filter)
    return filter == "Newest" and ReviewService.types.Newest or ReviewService.types.Recommended
end

local function load_reviews(book, filter)
    local book_id = canonical_book_id(book)
    filter = filter or "Recommended"
    if not book_id then
        return { type = filter, reviews = {}, state = "failed" }
    end
    local cached_reviews = book_status_store:load_reviews(book_id, filter)
    if cached_reviews then
        return cached_reviews
    end
    config:reload()
    local ok, result = pcall(function()
        return ReviewService:new(config):load_public_reviews(book_id, review_type_code(filter), 10)
    end)
    if ok then
        return book_status_store:save_reviews(book_id, result)
    end
    book_status_store:mark_reviews_failed(book_id, result)
    return { type = filter, reviews = {}, state = "failed" }
end

local function load_book_info(book)
    local book_id = canonical_book_id(book)
    if not book_id then return end
    config:reload()
    local ok, info = pcall(function()
        return BookInfoService:new(config):load(book_id)
    end)
    if ok and info then
        info.infoUpdatedAt = info.updatedAt
        book_status_store:update(book_id, info)
        hydrate_book(book, info)
    else
        book_status_store:update(book_id, {
            infoState = "failed",
            lastInfoError = display_error(info),
        })
    end
end

local function close_detail()
    if book_detail_view then
        pcall(function()
            UIManager:close(book_detail_view)
        end)
    end
end

local function show_detail(book)
    sync_book_status(book)
    local book_id = canonical_book_id(book)
    local status = book.status or book_status_store:get(book_id)
    hydrate_book(book, status)
    book_detail_view:setBook(book, status, book_status_store:load_reviews(book_id, "Recommended"))
    UIManager:show(book_detail_view)
    UIManager:scheduleIn(2, function()
        if screenshot_requested() then return end
        if book_detail_view.book == book then
            if tostring(book.intro or "") == "" or tostring(book.publisher or "") == "" then
                load_book_info(book)
                sync_book_status(book)
                book_detail_view:setBook(book, book.status or book_status_store:get(book_id), book_status_store:load_reviews(book_id, book_detail_view.review_filter))
            end
            book_detail_view:loadReviews("Recommended")
        end
    end)
end

local function show_downloads()
    download_queue_view:setJobs(book_status_store:list_downloads())
    UIManager:show(download_queue_view)
end

download_queue_view = DownloadQueueView:new{
    on_back = function()
        UIManager:close(download_queue_view)
    end,
    on_download_open = function(job)
        if not book_opener then return end
        book_opener:open({
            bookId = job.bookId,
            title = job.title,
            author = job.author or "",
        })
    end,
}

reader_view = ReaderView:new{
    on_back = function()
        UIManager:close(reader_view)
        if shelf_view and not shelf_view.disposed then
            UIManager:setDirty(shelf_view, "ui")
        end
    end,
}

shelf_view = ShelfGridView:new{
    books = initial_books,
    on_book_tap = function(book)
        show_detail(book)
    end,
    on_refresh = function()
        local generation = shelf_view:current_generation()
        UIManager:scheduleIn(0.1, function()
            if not shelf_view:is_active(generation) then
                return
            end
            local ok, result = pcall(load_shelf_online)
            if ok then
                local books = attach_book_statuses(result.books or {})
                shelf_view:setBooks(books)
                schedule_cover_prefetch(books, shelf_view, shelf_view:current_generation())
            else
                UIManager:show(InfoMessage:new{
                    text = "Refresh failed. Check account or network configuration.",
                })
            end
        end)
    end,
    on_downloads = function()
        show_downloads()
    end,
}
book_detail_view = BookDetailView:new{
    on_back = close_detail,
    on_open = function(book)
        book_opener:open(book)
    end,
    on_download_full = function(book)
        local book_id = canonical_book_id(book)
        local status = book_status_store:get(book_id)
        if status.downloadState == "full" and status.fullFile and status.fullFile ~= "" and status.imageAssets == true then
            UIManager:show(InfoMessage:new{ text = "已下载整本。\n点继续阅读即可打开。", timeout = 3 })
            return
        end
        local job
        local function refresh_detail()
            sync_book_status(book)
            hydrate_book(book, book.status or {})
            refresh_shelf_statuses()
            book_detail_view:setBook(book, book.status or book_status_store:get(book_id), book_status_store:load_reviews(book_id, book_detail_view.review_filter))
        end
        local function step_job()
            local ok, state_or_err = pcall(function()
                return download_manager:step_full_download(job)
            end)
            refresh_detail()
            if not ok then
                book_status_store:update(book_id, {
                    downloadState = "failed",
                    lastError = display_error(state_or_err),
                })
                refresh_detail()
                UIManager:show(InfoMessage:new{
                    text = "整本下载失败:\n" .. display_error(state_or_err),
                    timeout = 6,
                })
                return
            end
            if state_or_err == "done" or (job and job.state == "done") then
                local failed_count = job and #(job.failed or {}) or 0
                local message = "已下载整本。\n点继续阅读即可打开。"
                if failed_count > 0 then
                    message = "已下载 " .. tostring(#(job.selected or {})) .. " 章，"
                        .. tostring(failed_count) .. " 章失败。\n可先阅读已下载部分。"
                end
                UIManager:show(InfoMessage:new{
                    text = message,
                    timeout = 5,
                })
                return
            end
            UIManager:scheduleIn(0.05, step_job)
        end

        UIManager:scheduleIn(0.1, function()
            book_status_store:update(book_id, {
                title = book.title,
                downloadState = "downloading",
                downloadProgress = 0,
                downloadTotal = 0,
                lastError = "",
            })
            refresh_detail()
            local ok, result = pcall(function()
                return download_manager:start_full_download(book)
            end)
            if ok then
                job = result
                refresh_detail()
                if job.state == "done" then
                    UIManager:show(InfoMessage:new{ text = "已下载整本。\n点继续阅读即可打开。", timeout = 3 })
                    return
                end
                UIManager:scheduleIn(0.05, step_job)
            else
                book_status_store:update(book_id, {
                    downloadState = "failed",
                    lastError = display_error(result),
                })
                refresh_detail()
                UIManager:show(InfoMessage:new{
                    text = "整本下载失败:\n" .. display_error(result),
                    timeout = 6,
                })
            end
        end)
    end,
    on_chapters = function(book)
        UIManager:scheduleIn(0.1, function()
            local book_id = canonical_book_id(book)
            local ok, result = pcall(function()
                return download_manager:probe_catalog(book)
            end)
            if ok and #(result or {}) == 0 then
                sync_book_status(book)
                refresh_shelf_statuses()
                book_detail_view:showSpecialState()
            else
                if not ok then
                    book_status_store:update(book_id, {
                        downloadState = "failed",
                        lastError = display_error(result),
                    })
                end
                sync_book_status(book)
                refresh_shelf_statuses()
                book_detail_view:setBook(book, book.status or book_status_store:get(book_id), book_status_store:load_reviews(book_id, book_detail_view.review_filter))
            end
        end)
    end,
    on_refresh_info = function(book)
        UIManager:scheduleIn(0.1, function()
            local book_id = canonical_book_id(book)
            pcall(function()
                download_manager:probe_catalog(book)
            end)
            sync_book_status(book)
            refresh_shelf_statuses()
            book_detail_view:setBook(book, book.status or book_status_store:get(book_id), book_status_store:load_reviews(book_id, "Recommended"))
            book_detail_view:loadReviews("Recommended")
        end)
    end,
    on_clear_cache = function(book)
        local book_id = canonical_book_id(book)
        book_status_store:update(book_id, {
            downloadState = "remote",
            cachedFile = "",
            fullFile = "",
            lastError = "",
        })
        sync_book_status(book)
        refresh_shelf_statuses()
        book_detail_view:setBook(book, book.status or book_status_store:get(book_id), book_status_store:load_reviews(book_id, book_detail_view.review_filter))
    end,
    on_load_reviews = load_reviews,
}
book_opener = BookOpener:new{
    UIManager = UIManager,
    config = config,
    download_manager = download_manager,
    before_open_reader = function()
        close_detail()
    end,
    on_open_reader = function(path, book, chapter)
        reader_view:setChapter(path, book, chapter)
        UIManager:show(reader_view)
    end,
}

UIManager:show(shelf_view)

if #initial_books == 0 then
    local generation = shelf_view:current_generation()
    UIManager:scheduleIn(0.5, function()
        if not shelf_view:is_active(generation) then
            return
        end
        local ok, result = pcall(load_shelf_online)
        if ok then
            if not shelf_view:is_active(generation) then
                return
            end
            local books = result.books or {}
            books = attach_book_statuses(books)
            shelf_view:setBooks(books)
            if shelf_view:is_active() then
                schedule_cover_prefetch(books, shelf_view, shelf_view:current_generation())
            end
        else
            if shelf_view:is_active(generation) then
                UIManager:show(InfoMessage:new{
                    text = "Initial shelf load failed:\n" .. display_error(result),
                })
            end
        end
    end)
elseif shelf_view:is_active() then
    schedule_cover_prefetch(initial_books, shelf_view, shelf_view:current_generation())
end

local smoke_detail_index = tonumber(os.getenv("RM_WEREAD_DETAIL_INDEX") or "")
if smoke_detail_index then
    UIManager:scheduleIn(1, function()
        local book = shelf_view.books and shelf_view.books[smoke_detail_index]
        if book then
            show_detail(book)
        end
    end)
end

local smoke_download_full_index = tonumber(os.getenv("RM_WEREAD_DOWNLOAD_FULL_INDEX") or "")
if smoke_download_full_index then
    UIManager:scheduleIn(1, function()
        local book = shelf_view.books and shelf_view.books[smoke_download_full_index]
        if book then
            show_detail(book)
            UIManager:scheduleIn(0.2, function()
                if book_detail_view.book == book and book_detail_view.on_download_full then
                    book_detail_view.on_download_full(book)
                end
            end)
        end
    end)
end

local smoke_open_index = tonumber(os.getenv("RM_WEREAD_OPEN_INDEX") or "")
if smoke_open_index then
    UIManager:scheduleIn(1, function()
        local book = shelf_view.books and shelf_view.books[smoke_open_index]
        if book then
            book_opener:open(book)
        end
    end)
end

if os.getenv("RM_WEREAD_DOWNLOADS_VIEW") == "1" then
    UIManager:scheduleIn(1, function()
        show_downloads()
    end)
end

local smoke_shelf_page = tonumber(os.getenv("RM_WEREAD_SHELF_PAGE") or "")
if smoke_shelf_page then
    UIManager:scheduleIn(1, function()
        if shelf_view and shelf_view.setPage then
            shelf_view:setPage(smoke_shelf_page)
        end
    end)
end

local smoke_screenshot = os.getenv("RM_WEREAD_SCREENSHOT")
if smoke_screenshot and smoke_screenshot ~= "" then
    local delay = tonumber(os.getenv("RM_WEREAD_SCREENSHOT_DELAY") or "2") or 2
    UIManager:scheduleIn(delay, function()
        pcall(function()
            rt.Device.screen:shot(smoke_screenshot)
        end)
        if os.getenv("RM_WEREAD_EXIT_AFTER_SCREENSHOT") == "1" then
            UIManager:quit(0)
        end
    end)
end

local exit_code = UIManager:run()
rt:exit()
os.exit(exit_code or 0)
