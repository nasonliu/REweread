local Client = require("lib.client")
local Content = require("lib.content")
local Cookie = require("lib.cookie")
local WeRead = require("lib.weread")
local ChapterCache = require("chapter_cache")

local DEFAULT_CACHE_DIR = "/home/root/.local/share/rm-weread/books"

local DownloadManager = {}
DownloadManager.__index = DownloadManager

local function file_exists(path)
    if not path or path == "" then return false end
    local file = io.open(path, "rb")
    if not file then return false end
    local size = file:seek("end") or 0
    file:close()
    return size > 0
end

local function canonical_book_id(book)
    return book and (book.bookId or book.book_id)
end

local function deepcopy(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for key, item in pairs(value) do out[key] = deepcopy(item) end
    return out
end

local function content_book(book, book_id)
    local copy = deepcopy(book or {})
    copy.bookId = book_id
    copy.book_id = book_id
    return copy
end

local function assert_login_cookie(settings)
    if not settings:is_cookie_configured() then
        error("微信读书登录 Cookie 未配置。请在微信读书 App 的账号页使用扫码登录，或点续期 Cookie 后再重试。")
    end
end

local function first_substantive_chapter_index(chapters)
    for index, chapter in ipairs(chapters or {}) do
        local title = tostring((chapter or {}).title or "")
        local normalized = title:gsub("%s+", "")
        if normalized ~= ""
            and not normalized:find("版权")
            and not normalized:find("目录")
            and not normalized:find("封面")
            and not normalized:find("书名")
            and not normalized:find("扉页")
            and not normalized:find("出版")
            and not normalized:find("版权信息")
            and not normalized:find("本书插图")
            and not normalized:find("插图")
            and not normalized:find("前言")
            and not normalized:find("Copyright")
        then
            return index
        end
    end
    return 1
end

local ContentSettings = {}
ContentSettings.__index = ContentSettings

function ContentSettings:new(config, cache_dir)
    local cache = config:get("cache", {
        download_book_images = true,
        download_mp_images = false,
        download_underlines_and_thoughts = false,
        show_annotations = true,
    })
    cache.download_book_images = cache.download_book_images ~= false
    return setmetatable({
        cache_dir = cache_dir or DEFAULT_CACHE_DIR,
        values = {
            api_key = config:get("api_key", ""),
            cookies = config:get("cookies", {}),
            wr_ticket = config:get("wr_ticket", ""),
            wr_wrpa = config:get("wr_wrpa", ""),
            cache = cache,
        },
    }, self)
end

function ContentSettings:get(key, default)
    local value = self.values[key]
    if value == nil then value = default end
    return deepcopy(value)
end

function ContentSettings:set(key, value)
    self.values[key] = value
end

function ContentSettings:flush()
end

function ContentSettings:get_download_dir()
    return self.cache_dir
end

function ContentSettings:is_cookie_configured()
    return Cookie.has_login_cookie(self.values.cookies)
end

function DownloadManager:new(opts)
    opts = opts or {}
    return setmetatable({
        config = opts.config,
        status_store = opts.status_store,
        cache_dir = opts.cache_dir or DEFAULT_CACHE_DIR,
        chapter_cache = opts.chapter_cache or ChapterCache:new{ root = opts.cache_dir or DEFAULT_CACHE_DIR },
        active_job = nil,
    }, self)
end

function DownloadManager:settings()
    self.config:reload()
    return ContentSettings:new(self.config, self.cache_dir)
end

function DownloadManager:client(settings)
    return Client:new(settings)
end

function DownloadManager:probe_catalog(book)
    local settings = self:settings()
    assert_login_cookie(settings)
    local book_id = canonical_book_id(book)
    local work_book = content_book(book, book_id)
    local client = self:client(settings)
    Content.ensure_reader_state(client, work_book)
    local chapters = Content.fetch_catalog(client, work_book)
    book.chapters = chapters
    if self.status_store and book_id then
        self.status_store:update(book_id, {
            title = book.title,
            chapterCount = #(chapters or {}),
            downloadState = (#(chapters or {}) == 0) and "special" or "remote",
        })
    end
    return chapters
end

function DownloadManager:open(book)
    local settings = self:settings()
    assert_login_cookie(settings)
    local book_id = canonical_book_id(book)
    local status = self.status_store and self.status_store:get(book_id) or {}
    if status.fullFile and status.fullFile ~= "" and file_exists(status.fullFile) then
        return status.fullFile
    end
    if status.cachedFile and status.cachedFile ~= "" and file_exists(status.cachedFile) then
        return status.cachedFile
    end
    local client = self:client(settings)
    local work_book = content_book(book, book_id)
    local path, chapter = Content.fetch_first_chapter(client, settings, work_book)
    book.chapters = work_book.chapters
    if self.status_store and book_id then
        self.status_store:update(book_id, {
            title = book.title,
            cachedFile = path,
            downloadState = "partial",
            chapterCount = book.chapters and #book.chapters or nil,
            lastError = nil,
        })
    end
    return path, chapter
end

function DownloadManager:open_native_chapter(book)
    local settings = self:settings()
    assert_login_cookie(settings)
    local book_id = canonical_book_id(book)
    local cached = self.chapter_cache and self.chapter_cache:first_cached_chapter_path(book_id)
    if cached and cached ~= "" then
        return cached, nil
    end

    local client = self:client(settings)
    local work_book = content_book(book, book_id)
    Content.ensure_reader_state(client, work_book)
    local chapters = work_book.chapters or Content.fetch_catalog(client, work_book)
    work_book.chapters = chapters
    local chapter = Content.first_readable_chapter(chapters)
    if not chapter then
        error("No readable chapter found")
    end
    local xhtml, chapter_assets = Content.fetch_single_chapter_content(client, settings, work_book, chapter, {})
    local path = self.chapter_cache:write_chapter(book_id, chapter, xhtml)
    self.chapter_cache:write_chapter_assets(book_id, chapter_assets)
    if self.status_store and book_id then
        self.status_store:update(book_id, {
            title = book.title,
            cachedChapterFile = path,
            downloadState = "partial",
            chapterCount = chapters and #chapters or nil,
            lastError = "",
        })
    end
    return path, chapter
end

function DownloadManager:download_full(book)
    local settings = self:settings()
    assert_login_cookie(settings)
    local book_id = canonical_book_id(book)
    local status = self.status_store and self.status_store:get(book_id) or {}
    if status.fullFile and status.fullFile ~= "" and status.imageAssets == true and file_exists(status.fullFile) then
        return status.fullFile, book.chapters or {}
    end

    local client = self:client(settings)
    local work_book = content_book(book, book_id)
    if self.status_store and book_id then
        self.status_store:update(book_id, {
            title = book.title,
            downloadState = "downloading",
            downloadProgress = 0,
            lastError = "",
        })
    end

    local ok, path_or_err, selected = pcall(function()
        Content.ensure_reader_state(client, work_book)
        local chapters = work_book.chapters or Content.fetch_catalog(client, work_book)
        work_book.chapters = chapters
        if self.status_store and book_id then
            self.status_store:update(book_id, {
                chapterCount = #(chapters or {}),
                downloadTotal = #(chapters or {}),
            })
        end
        return Content.fetch_chapters_epub(client, settings, work_book, chapters, {
            suffix = "full",
            progress = function(chapter_index, total, chapter, stage)
                if self.status_store and book_id and (
                    chapter_index == 1 or chapter_index == total or chapter_index % 5 == 0 or stage == "images"
                ) then
                    self.status_store:update(book_id, {
                        downloadState = "downloading",
                        downloadProgress = chapter_index,
                        downloadTotal = total,
                        downloadStage = stage,
                        currentChapter = chapter and chapter.title or "",
                    })
                end
            end,
        })
    end)

    if not ok then
        local message = tostring(path_or_err or "Download failed")
        local state = "failed"
        if message:find("No readable chapter", 1, true) then
            state = "special"
            message = "这本书暂时没有可下载章节，可能是套装、版权受限或微信读书特殊条目。"
        end
        if self.status_store and book_id then
            self.status_store:update(book_id, {
                downloadState = state,
                lastError = message,
            })
        end
        error(message, 0)
    end

    if self.status_store and book_id then
        book.chapters = work_book.chapters
        self.status_store:update(book_id, {
            title = book.title,
            fullFile = path_or_err,
            cachedFile = path_or_err,
            downloadState = "full",
            downloadProgress = #(selected or {}),
            downloadTotal = #(selected or {}),
            chapterCount = #(selected or {}),
            currentChapter = "",
            downloadStage = "done",
            imageAssets = true,
            lastError = "",
        })
    end
    return path_or_err, selected
end

function DownloadManager:start_full_download(book, opts)
    opts = opts or {}
    local settings = self:settings()
    assert_login_cookie(settings)
    local book_id = canonical_book_id(book)
    local status = self.status_store and self.status_store:get(book_id) or {}
    if not opts.force and status.fullFile and status.fullFile ~= "" and status.imageAssets == true and file_exists(status.fullFile) then
        return {
            state = "done",
            book = book,
            book_id = book_id,
            path = status.fullFile,
            selected = book.chapters or {},
        }
    end

    local client = self:client(settings)
    local work_book = content_book(book, book_id)
    Content.ensure_reader_state(client, work_book)
    local chapters = work_book.chapters or Content.fetch_catalog(client, work_book)
    work_book.chapters = chapters
    if #(chapters or {}) == 0 then
        local message = "这本书暂时没有可下载章节，可能是套装、版权受限或微信读书特殊条目。"
        if self.status_store and book_id then
            self.status_store:update(book_id, {
                title = book.title,
                chapterCount = 0,
                downloadState = "special",
                downloadProgress = 0,
                downloadTotal = 0,
                lastError = message,
            })
        end
        error(message, 0)
    end

    if self.status_store and book_id then
        self.status_store:update(book_id, {
            title = book.title,
            chapterCount = #chapters,
            downloadState = "downloading",
            downloadProgress = 0,
            downloadTotal = #chapters,
            downloadStage = "text",
            currentChapter = "",
            lastError = "",
        })
    end

    local index = 1
    if opts.opening then
        index = self:opening_start_index(client, book_id, chapters)
    end

    local job = {
        state = "running",
        book = book,
        work_book = work_book,
        book_id = book_id,
        client = client,
        settings = settings,
        chapters = chapters,
        index = index,
        selected = {},
        bodies = {},
        assets = {},
        content_state = {},
        failed = {},
    }
    self.active_job = job
    return job
end

local function append_assets(target, source)
    for _, asset in ipairs(source or {}) do
        table.insert(target, asset)
    end
end

function DownloadManager:opening_start_index(client, book_id, chapters)
    local default_index = first_substantive_chapter_index(chapters)
    local use_remote = os.getenv("RM_WEREAD_OPENING_PROGRESS") ~= "0"
    if not use_remote then
        return default_index
    end

    local ok, progress_resp = pcall(function()
        return client:gateway("/book/getprogress", { bookId = tostring(book_id) })
    end)
    if not ok or type(progress_resp) ~= "table" then
        return default_index
    end

    local book = progress_resp.book or {}
    local progress = tonumber(book.progress or progress_resp.progress or 0) or 0
    if progress <= 1 then
        return default_index
    end
    local count = math.max(1, #(chapters or {}))
    local index = math.floor((math.max(0, math.min(100, progress)) / 100) * count) + 1
    if index < default_index then
        index = default_index
    end
    if index > count then
        index = count
    end
    return index
end

function DownloadManager:finish_full_download(job)
    if #job.selected == 0 then
        local message = "没有章节下载成功，请稍后重试。"
        if self.status_store and job.book_id then
            self.status_store:update(job.book_id, {
                downloadState = "failed",
                lastError = message,
            })
        end
        if self.active_job == job then
            self.active_job = nil
        end
        error(message, 0)
    end
    local cover_data
    local cover_url = WeRead.normalize_cover_url(job.work_book.cover)
    if cover_url and cover_url ~= "" then
        pcall(function()
            cover_data = job.client:get_binary(cover_url)
        end)
    end
    local path = Content.save_book_epub(
        job.settings, job.work_book, job.selected, job.bodies,
        "full", job.assets, job.content_state.css, cover_data
    )
    job.book.chapters = job.chapters
    local partial_state = (#job.failed > 0) and "partial" or "full"
    local last_error = ""
    if partial_state == "partial" then
        last_error = "部分章节下载失败: " .. tostring(#job.failed) .. " 章"
    end
    if self.status_store and job.book_id then
        self.status_store:update(job.book_id, {
            title = job.book.title,
            fullFile = path,
            cachedFile = path,
            downloadState = partial_state,
            downloadProgress = #job.selected,
            downloadTotal = #job.chapters,
            chapterCount = #job.selected,
            failedChapterCount = #job.failed,
            currentChapter = "",
            downloadStage = "done",
            imageAssets = true,
            lastError = last_error,
        })
    end
    job.path = path
    job.state = "done"
    if self.active_job == job then
        self.active_job = nil
    end
    return path, job.selected
end

function DownloadManager:finish_opening_download(job)
    if #job.selected == 0 then
        local message = "没有章节下载成功，请稍后重试。"
        if self.status_store and job.book_id then
            self.status_store:update(job.book_id, {
                downloadState = "failed",
                lastError = message,
            })
        end
        if self.active_job == job then
            self.active_job = nil
        end
        error(message, 0)
    end
    local path = Content.save_book_epub(
        job.settings, job.work_book, job.selected, job.bodies,
        "opening", job.assets, job.content_state.css
    )
    job.book.chapters = job.chapters
    if self.status_store and job.book_id then
        self.status_store:update(job.book_id, {
            title = job.book.title,
            cachedFile = path,
            downloadState = "partial",
            downloadProgress = #job.selected,
            downloadTotal = #job.chapters,
            chapterCount = #job.chapters,
            currentChapter = "",
            downloadStage = "opening",
            imageAssets = true,
            lastError = "",
        })
    end
    job.path = path
    job.state = "done"
    if self.active_job == job then
        self.active_job = nil
    end
    return path, job.selected
end

function DownloadManager:step_full_download(job)
    if not job or job.state == "done" then
        return "done", job
    end
    local chapter = job.chapters[job.index]
    if not chapter then
        self:finish_full_download(job)
        return "done", job
    end

    if self.status_store and job.book_id then
        self.status_store:update(job.book_id, {
            downloadState = "downloading",
            downloadProgress = job.index,
            downloadTotal = #job.chapters,
            downloadStage = "text",
            currentChapter = chapter.title or "",
        })
    end

    local ok, xhtml_or_err, chapter_assets = pcall(function()
        return Content.fetch_single_chapter_content(
            job.client, job.settings, job.work_book, chapter, job.content_state
        )
    end)
    if ok then
        local uid = tostring(chapter.chapterUid or job.index)
        table.insert(job.selected, chapter)
        job.bodies[uid] = xhtml_or_err
        append_assets(job.assets, chapter_assets)
        if job.book_id and self.chapter_cache then
            pcall(function()
                self.chapter_cache:write_chapter(job.book_id, chapter, xhtml_or_err)
                self.chapter_cache:write_chapter_assets(job.book_id, chapter_assets)
            end)
        end
    else
        table.insert(job.failed, {
            index = job.index,
            title = chapter.title or "",
            error = tostring(xhtml_or_err),
        })
    end
    job.index = job.index + 1
    return "running", job
end

return DownloadManager
