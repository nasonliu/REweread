local Client = require("lib.client")

local ShelfService = {}
ShelfService.__index = ShelfService

local function as_time(value)
    return tonumber(value) or 0
end

local function normalize_book(raw)
    if type(raw) ~= "table" then
        return nil
    end

    local info = raw.bookInfo or raw
    if type(info) ~= "table" then
        info = raw
    end
    local book_id = raw.bookId or info.bookId
    if not book_id then
        return nil
    end

    return {
        bookId = tostring(book_id),
        title = info.title or raw.title or tostring(book_id),
        author = info.author or raw.author or "",
        cover = info.cover or raw.cover or "",
        intro = info.intro or raw.intro or "",
        categoryName = info.categoryName or info.category or raw.categoryName or "",
        wordCount = info.wordCount or raw.wordCount or 0,
        newRating = info.newRating or raw.newRating or 0,
        readUpdateTime = raw.readUpdateTime or raw.updateTime or 0,
        finishReading = raw.finishReading or 0,
    }
end

local function normalize_books(result)
    local books = {}
    if type(result) ~= "table" or type(result.books) ~= "table" then
        return books
    end

    for _, raw in pairs(result.books) do
        local book = normalize_book(raw)
        if book then
            table.insert(books, book)
        end
    end

    table.sort(books, function(a, b)
        local a_time = as_time(a.readUpdateTime)
        local b_time = as_time(b.readUpdateTime)
        if a_time ~= b_time then
            return a_time > b_time
        end
        return tostring(a.bookId or a.title or "") < tostring(b.bookId or b.title or "")
    end)

    return books
end

function ShelfService:new(settings)
    return setmetatable({
        settings = settings,
        client = Client:new(settings),
    }, self)
end

function ShelfService:load_shelf()
    local result = self.client:gateway("/shelf/sync", {})
    return normalize_books(result)
end

return ShelfService
