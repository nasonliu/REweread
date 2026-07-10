local Device = require("device")
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local InputContainer = require("ui/widget/container/inputcontainer")
local UIManager = require("ui/uimanager")
local ViewHelpers = require("view_helpers")

local ShelfGridView = InputContainer:extend{
    name = "ShelfGridView",
    books = nil,
    on_book_tap = nil,
    on_refresh = nil,
    on_downloads = nil,
    books_per_page = 9,
}

function ShelfGridView:init()
    self.books = self.books or {}
    self.dimen = ViewHelpers.screen_size()
    self.active = false
    self.disposed = false
    self.generation = 0
    self.page = self.page or 1
    if Device:isTouchDevice() then
        self.ges_events.Tap = {
            GestureRange:new{
                ges = "tap",
                range = Geom:new{ x = 0, y = 0, w = self.dimen.w, h = self.dimen.h },
            },
        }
    end
end

function ShelfGridView:current_generation()
    return self.generation
end

function ShelfGridView:is_active(generation)
    return not self.disposed
        and self.active
        and (generation == nil or generation == self.generation)
end

function ShelfGridView:onShow()
    self.active = true
    self.generation = self.generation + 1
    UIManager:setDirty(self, function()
        return "full", self.dimen
    end)
    return true
end

function ShelfGridView:onCloseWidget()
    self.active = false
    self.generation = self.generation + 1
end

function ShelfGridView:close()
    self.disposed = true
    self.active = false
    self.generation = self.generation + 1
    UIManager:close(self)
end

function ShelfGridView:setBooks(books)
    self.books = books or {}
    self:clampPage()
    UIManager:setDirty(self, function()
        return "ui", self.dimen
    end)
end

function ShelfGridView:pageCount()
    return math.max(1, math.ceil(#(self.books or {}) / self.books_per_page))
end

function ShelfGridView:clampPage()
    local page_count = self:pageCount()
    if self.page < 1 then self.page = 1 end
    if self.page > page_count then self.page = page_count end
end

function ShelfGridView:pageOffset()
    self:clampPage()
    return (self.page - 1) * self.books_per_page
end

function ShelfGridView:nextPage()
    if self.page < self:pageCount() then
        self.page = self.page + 1
        UIManager:setDirty(self, "ui")
    end
end

function ShelfGridView:prevPage()
    if self.page > 1 then
        self.page = self.page - 1
        UIManager:setDirty(self, "ui")
    end
end

function ShelfGridView:setPage(page)
    self.page = tonumber(page) or 1
    self:clampPage()
    UIManager:setDirty(self, "ui")
end

function ShelfGridView:layout()
    local margin = 24
    local gap = 18
    local header_h = 72
    local card_w = math.floor((self.dimen.w - margin * 2 - gap * 2) / 3)
    local cover_h = math.floor(card_w * 1.34)
    local card_h = cover_h + 76
    return {
        margin = margin,
        gap = gap,
        header_h = header_h,
        card_w = card_w,
        cover_h = cover_h,
        card_h = card_h,
        top = header_h + 16,
    }
end

function ShelfGridView:drawHeader(bb)
    bb:paintRect(0, 0, self.dimen.w, 72, ViewHelpers.palette.background)
    ViewHelpers.draw_text(bb, 24, 16, "WeRead", 28, true, ViewHelpers.palette.text, 260)
    ViewHelpers.draw_button(bb, self.dimen.w - 314, 16, 122, 38, "Refresh", "ghost", { size = 14 })
    ViewHelpers.draw_button(bb, self.dimen.w - 178, 16, 154, 38, "Downloads", "secondary", { size = 14 })
    bb:paintRect(24, 68, self.dimen.w - 48, 2, ViewHelpers.palette.light)
end

function ShelfGridView:statusFor(book)
    local status = book.status or {}
    if status.downloadState == "full" then return "Downloaded" end
    if status.downloadState == "ready" then return "Ready" end
    if status.downloadState == "partial" then return "Partial" end
    if status.downloadState == "downloading" then return "Downloading" end
    if status.downloadState == "special" then return "Special" end
    if status.downloadState == "failed" then return "Failed" end
    return "Remote"
end

function ShelfGridView:drawCoverFallback(bb, book, x, y, w, h)
    local tone = ViewHelpers.cover_tone(book)
    local text_color = (tone == ViewHelpers.palette.light or tone == ViewHelpers.palette.panel)
        and ViewHelpers.palette.text
        or ViewHelpers.palette.background
    bb:paintRect(x, y, w, h, tone)
    local inset = math.max(8, math.floor(w * 0.08))
    bb:paintRect(x + inset, y + inset, w - inset * 2, h - inset * 2, ViewHelpers.palette.background)
    bb:paintRect(x + inset * 2, y + inset * 2, w - inset * 4, h - inset * 4, tone)
    ViewHelpers.draw_text(
        bb,
        x + 10,
        y + 18,
        ViewHelpers.truncate(book.title or "Untitled", 18),
        17,
        true,
        text_color,
        w - 20
    )
end

function ShelfGridView:drawBookCard(bb, book, index, x, y, w, h)
    local layout = self:layout()
    local cover_h = layout.cover_h
    local cover_path = ViewHelpers.local_cover_path(book)
    if not ViewHelpers.draw_image(bb, cover_path, x, y, w, cover_h) then
        self:drawCoverFallback(bb, book, x, y, w, cover_h)
    end
    ViewHelpers.draw_text(bb, x, y + cover_h + 8, ViewHelpers.truncate(book.title, 20), 15, true, ViewHelpers.palette.text, w)
    ViewHelpers.draw_text(bb, x, y + cover_h + 31, ViewHelpers.truncate(book.author, 20), 12, false, ViewHelpers.palette.muted, w)
    ViewHelpers.draw_text(bb, x, y + cover_h + 52, self:statusFor(book), 12, false, ViewHelpers.palette.muted, w)
end

function ShelfGridView:drawCoverGrid(bb, x, y)
    bb:paintRect(0, 0, self.dimen.w, self.dimen.h, ViewHelpers.palette.background)
    self:drawHeader(bb, x or 0, y or 0)
    local layout = self:layout()
    local offset = self:pageOffset()
    for visible_index = 1, self.books_per_page do
        local index = offset + visible_index
        local book = (self.books or {})[index]
        if not book then break end
        local col = (visible_index - 1) % 3
        local row = math.floor((visible_index - 1) / 3)
        local card_x = layout.margin + col * (layout.card_w + layout.gap)
        local card_y = layout.top + row * (layout.card_h + 16)
        if card_y < self.dimen.h then
            self:drawBookCard(bb, book, index, card_x, card_y, layout.card_w, layout.card_h)
        end
    end
    self:drawFooter(bb)
end

function ShelfGridView:drawFooter(bb)
    local footer_y = self.dimen.h - 72
    bb:paintRect(0, footer_y, self.dimen.w, 72, ViewHelpers.palette.background)
    bb:paintRect(24, footer_y, self.dimen.w - 48, 1, ViewHelpers.palette.light)
    local page_text = "Page " .. tostring(self.page) .. " / " .. tostring(self:pageCount())
    ViewHelpers.draw_centered_text(bb, 0, footer_y + 18, self.dimen.w, 34, page_text, 15, false, ViewHelpers.palette.muted, 220)
    ViewHelpers.draw_button(bb, 24, footer_y + 15, 120, 40, "< Prev", "ghost", { size = 15, disabled = self.page <= 1 })
    ViewHelpers.draw_button(bb, self.dimen.w - 144, footer_y + 15, 120, 40, "Next >", "ghost", { size = 15, disabled = self.page >= self:pageCount() })
end

function ShelfGridView:bookIndexAt(x, y)
    local layout = self:layout()
    if y < layout.top then
        return nil
    end
    local col = math.floor((x - layout.margin) / (layout.card_w + layout.gap))
    local row = math.floor((y - layout.top) / (layout.card_h + 16))
    if col < 0 or col > 2 or row < 0 then
        return nil
    end
    local in_col_x = (x - layout.margin) % (layout.card_w + layout.gap)
    local in_row_y = (y - layout.top) % (layout.card_h + 16)
    if in_col_x > layout.card_w or in_row_y > layout.card_h then
        return nil
    end
    local index = self:pageOffset() + row * 3 + col + 1
    if index >= 1 and index <= #(self.books or {}) then
        return index
    end
    return nil
end

function ShelfGridView:onTap(_, ges)
    local x, y = ges.pos.x, ges.pos.y
    if y < 72 then
        if x > self.dimen.w - 175 and self.on_downloads then
            self.on_downloads()
            return true
        end
        if x > self.dimen.w - 305 and self.on_refresh then
            self.on_refresh()
            return true
        end
        return true
    end
    if y > self.dimen.h - 74 then
        if x < 170 then self:prevPage(); return true end
        if x > self.dimen.w - 170 then self:nextPage(); return true end
        return true
    end
    local index = self:bookIndexAt(x, y)
    if index and self.books[index] and self.on_book_tap then
        self.on_book_tap(self.books[index])
        return true
    end
    return true
end

function ShelfGridView:paintTo(bb, x, y)
    self:drawCoverGrid(bb, x or 0, y or 0)
end

return ShelfGridView
