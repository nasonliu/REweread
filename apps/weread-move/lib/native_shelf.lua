local ShelfCache = require("shelf_cache")

local NativeShelf = {}
NativeShelf.__index = NativeShelf

local function as_time(value)
    return tonumber(value) or 0
end

local function normalize_book(book)
    if type(book) ~= "table" or not book.bookId then
        return nil
    end
    return {
        bookId = tostring(book.bookId),
        title = book.title or tostring(book.bookId),
        author = book.author or "",
        cover = book.cover or "",
        localCover = book.localCover or "",
        readUpdateTime = book.readUpdateTime or 0,
        status = book.status or {},
    }
end

function NativeShelf:new(root)
    return setmetatable({
        cache = ShelfCache:new(root),
    }, self)
end

function NativeShelf:load()
    local data = self.cache:load_shelf() or {}
    local books = {}
    for _, book in ipairs(data.books or {}) do
        local normalized = normalize_book(book)
        if normalized then
            table.insert(books, normalized)
        end
    end
    table.sort(books, function(a, b)
        local a_time = as_time(a.readUpdateTime)
        local b_time = as_time(b.readUpdateTime)
        if a_time ~= b_time then
            return a_time > b_time
        end
        return tostring(a.bookId) < tostring(b.bookId)
    end)
    return {
        savedAt = data.savedAt or 0,
        books = books,
    }
end

function NativeShelf:first_book_id()
    local data = self:load()
    return data.books[1] and data.books[1].bookId or nil
end

function NativeShelf:book_at(books, x, y)
    x = tonumber(x) or 0
    y = tonumber(y) or 0
    local margin = 18
    local top = 72
    local gap = 12
    local card_w = 100
    local card_h = 136
    if y < top then
        return nil
    end
    local col = math.floor((x - margin) / (card_w + gap))
    local row = math.floor((y - top) / (card_h + gap))
    if col < 0 or col > 2 or row < 0 or row > 2 then
        return nil
    end
    local in_x = (x - margin) % (card_w + gap)
    local in_y = (y - top) % (card_h + gap)
    if in_x > card_w or in_y > card_h then
        return nil
    end
    return books[row * 3 + col + 1]
end

return NativeShelf
