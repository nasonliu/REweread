local BD = require("ui/bidi")
local Menu = require("ui/widget/menu")
local InfoMessage = require("ui/widget/infomessage")

local ShelfView = {}
ShelfView.__index = ShelfView

function ShelfView:new(opts)
    opts = opts or {}
    return setmetatable({
        UIManager = opts.UIManager,
        load_shelf = opts.load_shelf,
        open_book = opts.open_book,
        after_refresh = opts.after_refresh,
        books = opts.books or {},
        title = opts.title or "WeRead",
        disposed = false,
        active = false,
        generation = 0,
    }, self)
end

local function cache_badge(book)
    if book.localCover and book.localCover ~= "" then
        return "cover"
    end
    if book.cover and book.cover ~= "" then
        return "remote"
    end
    return ""
end

function ShelfView:show_cover_info(book)
    local title = book.title or book.bookId or "Untitled"
    local lines = {
        title,
        "Author: " .. tostring(book.author or ""),
        "Book ID: " .. tostring(book.bookId or ""),
    }
    if book.localCover and book.localCover ~= "" then
        table.insert(lines, "Cover cached:")
        table.insert(lines, book.localCover)
    elseif book.cover and book.cover ~= "" then
        table.insert(lines, "Cover URL available; refresh shelf to cache it.")
    else
        table.insert(lines, "No cover found.")
    end
    self.UIManager:show(InfoMessage:new{ text = table.concat(lines, "\n") })
end

function ShelfView:items()
    local items = {
        {
            text = "Refresh shelf",
            mandatory = "online",
            callback = function()
                self:refresh()
            end,
            separator = true,
        },
    }

    for _i, book in ipairs(self.books or {}) do
        table.insert(items, {
            text = BD.auto(book.title or book.bookId or "Untitled"),
            mandatory = cache_badge(book),
            post_text = BD.auto(book.author or ""),
            callback = function()
                if self.open_book then
                    self.open_book(book)
                else
                    self:show_cover_info(book)
                end
            end,
        })
    end
    return items
end

function ShelfView:current_generation()
    return self.generation
end

function ShelfView:is_active(generation)
    return not self.disposed
        and self.active
        and self.menu ~= nil
        and (generation == nil or generation == self.generation)
end

function ShelfView:mark_inactive(menu, generation)
    if self.menu == menu and generation == self.generation then
        self.active = false
        self.menu = nil
        self.generation = self.generation + 1
    end
end

function ShelfView:refresh()
    if not self.load_shelf then
        self.UIManager:show(InfoMessage:new{ text = "Refresh is not available." })
        return
    end

    local generation = self:current_generation()
    self.UIManager:scheduleIn(0.1, function()
        if not self:is_active(generation) then
            return
        end

        local ok, result = pcall(self.load_shelf, generation)
        if ok then
            if not self:is_active(generation) then
                return
            end
            self.books = result.books or result
            self:show()
            if self.after_refresh and self:is_active() then
                self.after_refresh(self.books, self:current_generation())
            end
        elseif self:is_active(generation) then
            self.UIManager:show(InfoMessage:new{
                text = "Refresh failed. Check account or network configuration.",
            })
        end
    end)
end

function ShelfView:close()
    self.disposed = true
    self.active = false
    self.generation = self.generation + 1
    if self.menu then
        self.UIManager:close(self.menu)
        self.menu = nil
    end
end

function ShelfView:show()
    if self.disposed then
        return
    end
    if self.menu then
        self.menu.onCloseWidget = self.menu._weread_original_onCloseWidget
        self.menu.onClose = self.menu._weread_original_onClose
        self.UIManager:close(self.menu)
    end
    self.generation = self.generation + 1
    local generation = self.generation
    self.menu = Menu:new{
        title = self.title .. " - Shelf",
        item_table = self:items(),
        is_borderless = true,
        title_bar_fm_style = true,
    }
    self.active = true

    local menu = self.menu
    local original_on_close_widget = menu.onCloseWidget
    local original_on_close = menu.onClose
    menu._weread_original_onCloseWidget = original_on_close_widget
    menu._weread_original_onClose = original_on_close
    menu.onCloseWidget = function(widget, ...)
        self:mark_inactive(menu, generation)
        if original_on_close_widget then
            original_on_close_widget(widget, ...)
        end
    end
    menu.onClose = function(widget, ...)
        self:mark_inactive(menu, generation)
        if original_on_close then
            original_on_close(widget, ...)
        end
    end

    self.UIManager:show(self.menu)
end

return ShelfView
