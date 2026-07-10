local Client = require("lib.client")

local BookInfoService = {}
BookInfoService.__index = BookInfoService

local function text(value)
    return tostring(value or "")
end

local function number(value)
    return tonumber(value or 0) or 0
end

function BookInfoService:new(settings)
    return setmetatable({
        settings = settings,
        client = Client:new(settings),
    }, self)
end

function BookInfoService:load(book_id)
    local info = self.client:gateway("/book/info", {
        bookId = tostring(book_id),
    })
    info = info or {}
    local out = { updatedAt = os.time() }
    for key, value in pairs({
        title = info.title,
        author = info.author,
        intro = info.intro,
        publisher = info.publisher,
        publishTime = info.publishTime or info.publishDate,
        isbn = info.isbn,
        translator = info.translator,
        categoryName = info.categoryName or info.category,
    }) do
        value = text(value)
        if value ~= "" then
            out[key] = value
        end
    end
    for key, value in pairs({
        wordCount = info.wordCount,
        newRating = info.newRating,
        newRatingCount = info.newRatingCount,
    }) do
        value = number(value)
        if value > 0 then
            out[key] = value
        end
    end
    return out
end

return BookInfoService
