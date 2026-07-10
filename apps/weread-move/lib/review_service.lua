local Client = require("lib.client")

local ReviewService = {}
ReviewService.__index = ReviewService

ReviewService.types = {
    Recommended = 1,
    Newest = 3,
}

local function nested_review(row)
    if type(row) ~= "table" then return {} end
    if type(row.review) == "table" and type(row.review.review) == "table" then
        return row.review.review
    end
    if type(row.review) == "table" then
        return row.review
    end
    return row
end

local function nested_author(row, review)
    if type(row) == "table" and type(row.author) == "table" then
        return row.author
    end
    if type(review) == "table" and type(review.author) == "table" then
        return review.author
    end
    return {}
end

local function strip_html(value)
    return tostring(value or ""):gsub("<[^>]->", ""):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
end

local function normalize_review(book_id, row)
    local review = nested_review(row)
    local author = nested_author(row, review)
    local review_id = review.reviewId or row.reviewId or ""
    local star = tonumber(review.star or row.star or 0) or 0
    if star > 5 then
        star = star / 20
    end
    return {
        reviewId = tostring(review_id),
        bookId = tostring(book_id),
        userName = tostring(author.name or author.userName or review.userName or "Reader"),
        star = star,
        content = strip_html(review.content or review.htmlContent or ""),
        likedCount = tonumber(review.likedCount or row.likedCount or 0) or 0,
        commentCount = tonumber(review.commentCount or row.commentCount or 0) or 0,
        time = tonumber(review.createTime or row.createTime or 0) or 0,
        link = "https://weread.qq.com/web/bookReview/" .. tostring(review_id),
    }
end

function ReviewService:new(settings)
    return setmetatable({
        settings = settings,
        client = Client:new(settings),
    }, self)
end

function ReviewService:load_public_reviews(book_id, review_type, count)
    local type_code = review_type or self.types.Recommended
    local result = self.client:gateway("/review/list", {
        bookId = tostring(book_id),
        reviewListType = type_code,
        count = count or 10,
        maxIdx = 0,
    })
    local reviews = {}
    for _, row in ipairs(result.reviews or {}) do
        local item = normalize_review(book_id, row)
        if item.content ~= "" then
            table.insert(reviews, item)
        end
    end
    return {
        type = type_code == self.types.Newest and "Newest" or "Recommended",
        total = tonumber(result.reviewsCnt or result.recentTotalCnt or #reviews) or #reviews,
        hasMore = result.reviewsHasMore == true,
        reviews = reviews,
        updatedAt = os.time(),
    }
end

return ReviewService
