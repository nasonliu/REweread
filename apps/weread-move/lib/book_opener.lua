local InfoMessage = require("ui/widget/infomessage")
local WeRead = require("lib.weread")

local BookOpener = {}
BookOpener.__index = BookOpener

local function canonical_book_id(book)
    return book and (book.bookId or book.book_id)
end

local function display_error(err)
    local text = tostring(err or "unknown error")
    text = text:gsub("Authorization:%s*[Bb]earer%s+[%w%._%-]+", "Authorization: Bearer <redacted>")
    text = text:gsub("wrk%-[%w_%-]+", "wrk-<redacted>")
    text = text:gsub("wr_skey=[^;%s]+", "wr_skey=<redacted>")
    text = text:gsub("wr_rt=[^;%s]+", "wr_rt=<redacted>")
    text = text:gsub("wr_vid=[^;%s]+", "wr_vid=<redacted>")
    if #text > 300 then
        text = text:sub(1, 300) .. "..."
    end
    return text
end

function BookOpener:new(opts)
    opts = opts or {}
    return setmetatable({
        UIManager = opts.UIManager,
        config = opts.config,
        download_manager = opts.download_manager,
        before_open_reader = opts.before_open_reader,
        on_open_reader = opts.on_open_reader,
    }, self)
end

function BookOpener:show_message(text, opts)
    opts = opts or {}
    local message = InfoMessage:new{
        text = text,
        timeout = opts.timeout,
    }
    self.UIManager:show(message)
    return message
end

function BookOpener:open_reader(path, book, chapter)
    if self.before_open_reader then
        self.before_open_reader()
    end
    if self.on_open_reader then
        self.on_open_reader(path, book, chapter)
        return
    end
    self:show_message("Native reader is not configured.", { timeout = 4 })
end

function BookOpener:download_first_chapter(book)
    if not self.download_manager then
        error("Download manager is not configured")
    end
    return self.download_manager:open_native_chapter(book)
end

function BookOpener:open(book)
    local book_id = canonical_book_id(book)
    if not book_id or book_id == "" then
        self:show_message("Cannot open this book: missing Book ID.", { timeout = 3 })
        return
    end
    if WeRead.is_mp_book(book_id) then
        self:show_message("Public account articles are not supported in the standalone app yet.", { timeout = 4 })
        return
    end

    self.UIManager:scheduleIn(0.1, function()
        local busy = self:show_message("Downloading first chapter...\n" .. tostring(book.title or book_id), { timeout = 0 })
        if self.UIManager.forceRePaint then
            self.UIManager:forceRePaint()
        end

        local ok, result_or_err = pcall(function()
            local path, chapter = self:download_first_chapter(book)
            return {
                path = path,
                chapter = chapter,
            }
        end)

        self.UIManager:close(busy)
        if ok then
            self:open_reader(result_or_err.path, book, result_or_err.chapter)
        else
            local message = display_error(result_or_err)
            if message:find("No readable chapter", 1, true) then
                message = "No readable chapters were found for this shelf item. It may be a bundle or special WeRead item; try another book for now."
            end
            self:show_message("Open book failed:\n" .. message, { timeout = 6 })
        end
    end)
end

return BookOpener
