local Device = require("device")
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local InputContainer = require("ui/widget/container/inputcontainer")
local UIManager = require("ui/uimanager")
local ReaderDocument = require("reader_document")
local ViewHelpers = require("view_helpers")

local ReaderView = InputContainer:extend{
    name = "ReaderView",
    path = nil,
    book = nil,
    chapter = nil,
    pages = nil,
    page = 1,
    on_back = nil,
}

local function read_all(path)
    local file = io.open(path, "rb")
    if not file then return nil end
    local text = file:read("*a")
    file:close()
    return text
end

function ReaderView:init()
    self.dimen = ViewHelpers.screen_size()
    self.pages = self.pages or {}
    if self.path then
        self:setChapter(self.path, self.book, self.chapter)
    end
    if Device:isTouchDevice() then
        self.ges_events.Tap = {
            GestureRange:new{
                ges = "tap",
                range = Geom:new{ x = 0, y = 0, w = self.dimen.w, h = self.dimen.h },
            },
        }
    end
end

function ReaderView:onShow()
    UIManager:setDirty(self, function()
        return "full", self.dimen
    end)
    return true
end

function ReaderView:setChapter(path, book, chapter)
    self.path = path
    self.book = book or self.book or {}
    self.chapter = chapter or self.chapter
    local xhtml = read_all(path) or ""
    self.document = ReaderDocument.from_xhtml(xhtml)
    self.pages = ReaderDocument.paginate(self.document, {
        chars_per_line = 30,
        heading_chars = 18,
        lines_per_page = 24,
        image_lines = 7,
    })
    self.page = 1
    UIManager:setDirty(self, "ui")
end

function ReaderView:pageCount()
    return math.max(1, #(self.pages or {}))
end

function ReaderView:nextPage()
    if self.page < self:pageCount() then
        self.page = self.page + 1
        UIManager:setDirty(self, "ui")
    end
end

function ReaderView:prevPage()
    if self.page > 1 then
        self.page = self.page - 1
        UIManager:setDirty(self, "ui")
    end
end

function ReaderView:onTap(_, ges)
    local x, y = ges.pos.x, ges.pos.y
    if y < 70 and x < 150 then
        if self.on_back then self.on_back() else UIManager:close(self) end
        return true
    end
    if x < self.dimen.w * 0.33 then
        self:prevPage()
        return true
    end
    if x > self.dimen.w * 0.66 then
        self:nextPage()
        return true
    end
    return true
end

function ReaderView:drawHeader(bb)
    bb:paintRect(0, 0, self.dimen.w, 64, ViewHelpers.palette.background)
    ViewHelpers.draw_text(bb, 28, 20, "< 书架", 16, false, ViewHelpers.palette.text, 110)
    local title = ViewHelpers.safe_text((self.book or {}).title, "微信读书")
    ViewHelpers.draw_centered_text(bb, 150, 18, self.dimen.w - 300, 28, ViewHelpers.truncate(title, 22), 16, true, ViewHelpers.palette.text)
    bb:paintRect(28, 62, self.dimen.w - 56, 1, ViewHelpers.palette.light)
end

function ReaderView:drawFooter(bb)
    local footer_y = self.dimen.h - 54
    bb:paintRect(0, footer_y, self.dimen.w, 54, ViewHelpers.palette.background)
    bb:paintRect(28, footer_y, self.dimen.w - 56, 1, ViewHelpers.palette.light)
    local progress = tostring(self.page) .. " / " .. tostring(self:pageCount())
    ViewHelpers.draw_centered_text(bb, 0, footer_y + 12, self.dimen.w, 30, progress, 14, false, ViewHelpers.palette.text)
end

function ReaderView:drawItem(bb, item, x, y, w)
    if item.type == "image" then
        bb:paintRect(x, y + 8, w, 118, ViewHelpers.palette.light)
        bb:paintRect(x + 2, y + 10, w - 4, 114, ViewHelpers.palette.background)
        ViewHelpers.draw_centered_text(bb, x + 12, y + 42, w - 24, 44, "图片", 18, true, ViewHelpers.palette.text)
        ViewHelpers.draw_centered_text(bb, x + 12, y + 78, w - 24, 30, ViewHelpers.truncate(item.src or "", 36), 12, false, ViewHelpers.palette.text)
        return 138
    end
    local size = item.type == "heading" and 26 or 18
    local line_height = item.type == "heading" and 36 or 30
    local bold = item.type == "heading"
    local used = 0
    for _, line in ipairs(item.lines or {}) do
        ViewHelpers.draw_text(bb, x, y + used, line, size, bold, ViewHelpers.palette.text, w)
        used = used + line_height
    end
    if item.type == "heading" then
        used = used + 12
    end
    return math.max(used, line_height)
end

function ReaderView:paintTo(bb)
    bb:paintRect(0, 0, self.dimen.w, self.dimen.h, ViewHelpers.palette.background)
    self:drawHeader(bb)
    local page = (self.pages or {})[self.page] or { items = {} }
    local x = 52
    local y = 96
    local w = self.dimen.w - 104
    if #page.items == 0 then
        ViewHelpers.draw_centered_text(bb, x, y + 160, w, 60, "暂无可读内容", 20, true, ViewHelpers.palette.text)
    end
    for _, item in ipairs(page.items or {}) do
        local used = self:drawItem(bb, item, x, y, w)
        y = y + used + 10
        if y > self.dimen.h - 90 then break end
    end
    self:drawFooter(bb)
end

return ReaderView
