local Device = require("device")
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local InputContainer = require("ui/widget/container/inputcontainer")
local UIManager = require("ui/uimanager")
local ViewHelpers = require("view_helpers")

local BookDetailView = InputContainer:extend{
    name = "BookDetailView",
    book = nil,
    status = nil,
    reviews = nil,
    review_filter = "Recommended",
    on_back = nil,
    on_open = nil,
    on_download_full = nil,
    on_chapters = nil,
    on_refresh_info = nil,
    on_clear_cache = nil,
    on_load_reviews = nil,
    probeCatalog = nil,
    action_labels = { "Continue", "Open", "Download full book", "Chapters", "Reviews", "Recommended", "Newest", "Clear cache" },
}

function BookDetailView:init()
    self.dimen = ViewHelpers.screen_size()
    self.status = self.status or {}
    self.reviews = self.reviews or { type = "Recommended", reviews = {} }
    if Device:isTouchDevice() then
        self.ges_events.Tap = {
            GestureRange:new{
                ges = "tap",
                range = Geom:new{ x = 0, y = 0, w = self.dimen.w, h = self.dimen.h },
            },
        }
    end
end

function BookDetailView:onShow()
    UIManager:setDirty(self, function()
        return "full", self.dimen
    end)
    return true
end

function BookDetailView:setBook(book, status, reviews)
    self.book = book
    self.status = status or {}
    self.review_filter = (reviews and reviews.type) or "Recommended"
    self.reviews = reviews or { type = self.review_filter, reviews = {} }
    UIManager:setDirty(self, function()
        return "ui", self.dimen
    end)
end

function BookDetailView:showSpecialState()
    self.status = self.status or {}
    self.status.downloadState = "special"
    self.status.lastError = "This looks like a bundle or special WeRead item. Quick open/download is not supported yet."
    UIManager:setDirty(self, function()
        return "ui", self.dimen
    end)
end

function BookDetailView:loadReviews(filter)
    self.review_filter = filter or self.review_filter or "Recommended"
    if not self.on_load_reviews or not self.book then
        self.reviews = { type = self.review_filter, reviews = {}, state = "failed" }
        UIManager:setDirty(self, "ui")
        return
    end
    self.reviews = { type = self.review_filter, reviews = {}, state = "loading" }
    UIManager:setDirty(self, "ui")
    local ok, result = pcall(self.on_load_reviews, self.book, self.review_filter)
    if ok then
        self.reviews = result or { type = self.review_filter, reviews = {} }
    else
        self.reviews = { type = self.review_filter, reviews = {}, state = "failed", error = tostring(result) }
    end
    UIManager:setDirty(self, "ui")
end

function BookDetailView:primaryLabel()
    if self.status.downloadState == "special" then return "不可用" end
    if (self.status.fullFile and self.status.fullFile ~= "") or (self.status.cachedFile and self.status.cachedFile ~= "") then
        return "继续阅读"
    end
    return "开始阅读"
end

function BookDetailView:downloadLabel()
    if self.status.downloadState == "downloading" then
        local progress = tonumber(self.status.downloadProgress or 0) or 0
        local total = tonumber(self.status.downloadTotal or 0) or 0
        if total > 0 then
            return "下载 " .. tostring(progress) .. "/" .. tostring(total)
        end
        return "下载中"
    end
    if self.status.downloadState == "partial" and self.status.fullFile and self.status.fullFile ~= "" then
        return "已下载部分"
    end
    if self.status.fullFile and self.status.fullFile ~= "" and self.status.imageAssets ~= true then
        return "补下载图片"
    end
    if self.status.fullFile and self.status.fullFile ~= "" then
        return "已下载"
    end
    return "下载整本"
end

function BookDetailView:friendlyError(value)
    local text = ViewHelpers.safe_text(value, "")
    if text:find("No readable chapter", 1, true) then
        return "这本书暂时没有可下载章节，可能是套装、版权受限或微信读书特殊条目。"
    end
    text = text:gsub("^.-weread%.koplugin/", "")
    return text
end

function BookDetailView:bookMetaLine(book)
    local parts = {}
    local word_count = tonumber(book.wordCount or book.word_count or 0) or 0
    if word_count > 0 then
        table.insert(parts, tostring(word_count) .. " 字")
    end
    local category = ViewHelpers.safe_text(book.categoryName or book.category, "")
    if category ~= "" then
        table.insert(parts, category)
    end
    local rating = tonumber(book.newRating or book.recommendation or 0) or 0
    local recommendation = self:recommendationLabel(rating)
    if recommendation ~= "" then
        table.insert(parts, recommendation)
    end
    local state = ViewHelpers.safe_text(self.status.downloadState, "remote")
    if state == "partial" and tonumber(self.status.failedChapterCount or 0) > 0 then
        table.insert(parts, "部分下载")
        table.insert(parts, tostring(self.status.failedChapterCount) .. "章失败")
    else
        table.insert(parts, "状态 " .. state)
    end
    if self.status.chapterCount then
        table.insert(parts, tostring(self.status.chapterCount) .. "章")
    end
    return table.concat(parts, "  ·  ")
end

function BookDetailView:recommendationLabel(value)
    local rating = tonumber(value or 0) or 0
    if rating <= 0 then return "" end
    if rating > 100 and rating <= 1000 then
        rating = rating / 10
    end
    if rating > 100 then
        return ""
    end
    local text = string.format("%.1f", rating):gsub("%.0$", "")
    return "推荐值 " .. text .. "%"
end

function BookDetailView:copyrightLine(book)
    local parts = {}
    local publisher = ViewHelpers.safe_text(book.publisher or book.publisherName, "")
    if publisher ~= "" then
        table.insert(parts, "出版社 " .. publisher)
    end
    local publish_time = ViewHelpers.safe_text(book.publishTime or book.publishDate, "")
    if publish_time ~= "" then
        table.insert(parts, "出版时间 " .. publish_time)
    end
    local word_count = tonumber(book.wordCount or book.word_count or 0) or 0
    if word_count > 0 then
        table.insert(parts, "字数 " .. tostring(word_count))
    end
    local category = ViewHelpers.safe_text(book.categoryName or book.category, "")
    if category ~= "" then
        table.insert(parts, "分类 " .. category)
    end
    return table.concat(parts, "  ")
end

function BookDetailView:ratingLine()
    local bundle = self.reviews or {}
    if tonumber(bundle.total or 0) and tonumber(bundle.total or 0) > 0 then
        return tostring(bundle.total) .. " 人点评"
    end
    return "公开书评"
end

function BookDetailView:renderReviews(bb, y)
    local bundle = self.reviews or {}
    ViewHelpers.draw_text(bb, 48, y, "书评", 22, true, ViewHelpers.palette.text, 110)
    ViewHelpers.draw_text(bb, 130, y + 5, self:ratingLine(), 14, false, ViewHelpers.palette.muted, 150)
    local rec_color = self.review_filter == "Recommended" and ViewHelpers.palette.text or ViewHelpers.palette.muted
    local new_color = self.review_filter == "Newest" and ViewHelpers.palette.text or ViewHelpers.palette.muted
    ViewHelpers.draw_text(bb, self.dimen.w - 206, y + 4, "推荐", 15, true, rec_color, 76)
    ViewHelpers.draw_text(bb, self.dimen.w - 120, y + 4, "最新", 15, true, new_color, 76)
    bb:paintRect(48, y + 38, self.dimen.w - 96, 1, ViewHelpers.palette.light)
    if bundle.state == "loading" then
        ViewHelpers.draw_text(bb, 48, y + 68, "正在加载书评...", 15, false, ViewHelpers.palette.muted, self.dimen.w - 96)
        return
    end
    if bundle.state == "failed" then
        ViewHelpers.draw_text(bb, 48, y + 68, "书评暂不可用", 15, false, ViewHelpers.palette.muted, self.dimen.w - 96)
        return
    end
    local reviews = bundle.reviews or {}
    if #reviews == 0 then
        ViewHelpers.draw_text(bb, 48, y + 68, "暂无公开书评", 15, false, ViewHelpers.palette.muted, self.dimen.w - 96)
        return
    end
    for index, review in ipairs(reviews) do
        if index > 3 then break end
        local row_y = y + 52 + (index - 1) * 128
        local star = tonumber(review.star or 0) or 0
        if star > 5 then
            star = star / 20
        end
        local star_value = string.format("%.1f", star):gsub("%.0$", "")
        local meta = ViewHelpers.safe_text(review.userName, "读者") .. "  " .. star_value .. " 星"
        local counts = tostring(review.likedCount or 0) .. " 赞  " .. tostring(review.commentCount or 0) .. " 评论"
        bb:paintRect(48, row_y + 12, 40, 40, ViewHelpers.palette.light)
        ViewHelpers.draw_text(bb, 103, row_y + 10, meta, 15, true, ViewHelpers.palette.text, self.dimen.w - 151)
        ViewHelpers.draw_wrapped_text(bb, 103, row_y + 38, review.content, 14, false, ViewHelpers.palette.muted, self.dimen.w - 151, 34, 2, 24)
        ViewHelpers.draw_text(bb, 103, row_y + 92, counts, 12, false, ViewHelpers.palette.muted, self.dimen.w - 151)
        bb:paintRect(48, row_y + 118, self.dimen.w - 96, 1, ViewHelpers.palette.light)
    end
end

function BookDetailView:paintTo(bb)
    local book = self.book or {}
    local page_w = self.dimen.w
    bb:paintRect(0, 0, self.dimen.w, self.dimen.h, ViewHelpers.palette.background)
    ViewHelpers.draw_text(bb, 36, 28, "< 书架", 16, false, ViewHelpers.palette.text, 100)
    ViewHelpers.draw_text(bb, page_w - 206, 28, "微信读书 Move", 15, false, ViewHelpers.palette.muted, 170)
    bb:paintRect(32, 72, page_w - 64, 1, ViewHelpers.palette.light)

    local cover_x, cover_y, cover_w, cover_h = 54, 116, 238, 318
    local cover_path = ViewHelpers.local_cover_path(book)
    if not ViewHelpers.draw_image(bb, cover_path, cover_x, cover_y, cover_w, cover_h) then
        bb:paintRect(cover_x, cover_y, cover_w, cover_h, ViewHelpers.cover_tone(book))
        ViewHelpers.draw_wrapped_text(bb, cover_x + 18, cover_y + 26, ViewHelpers.safe_text(book.title, "Untitled"), 20, true, ViewHelpers.palette.background, cover_w - 36, 8, 3, 32)
    end
    bb:paintRect(cover_x + 10, cover_y + cover_h + 12, cover_w - 20, 2, ViewHelpers.palette.light)

    local info_x = 336
    local info_w = page_w - info_x - 48
    ViewHelpers.draw_wrapped_text(bb, info_x, 114, ViewHelpers.safe_text(book.title, "Untitled"), 28, true, ViewHelpers.palette.text, info_w, 15, 2, 42)
    ViewHelpers.draw_text(bb, info_x, 206, ViewHelpers.safe_text(book.author, ""), 17, false, ViewHelpers.palette.muted, info_w)
    ViewHelpers.draw_wrapped_text(bb, info_x, 254, self:bookMetaLine(book), 14, false, ViewHelpers.palette.muted, info_w, 34, 2, 24)

    ViewHelpers.draw_button(bb, info_x, 330, 184, 52, self:primaryLabel(), "primary", { size = 17 })
    ViewHelpers.draw_button(bb, info_x + 204, 330, 184, 52, self:downloadLabel(), "secondary", { size = 17 })
    ViewHelpers.draw_button(bb, info_x, 406, 112, 38, "目录", "ghost", { size = 14 })
    ViewHelpers.draw_button(bb, info_x + 128, 406, 112, 38, "刷新", "ghost", { size = 14 })
    ViewHelpers.draw_button(bb, info_x + 256, 406, 132, 38, "清缓存", "danger", { size = 14 })

    local intro_y = 500
    bb:paintRect(48, intro_y - 28, page_w - 96, 1, ViewHelpers.palette.light)
    ViewHelpers.draw_text(bb, 48, intro_y, "简介", 22, true, ViewHelpers.palette.text, 120)
    local intro = ViewHelpers.safe_text(book.intro or book.description, "暂无简介")
    if intro == "" then intro = "暂无简介" end
    ViewHelpers.draw_wrapped_text(bb, 48, intro_y + 42, intro, 16, false, ViewHelpers.palette.text, page_w - 96, 46, 4, 28)

    local copyright_y = intro_y + 184
    ViewHelpers.draw_text(bb, 48, copyright_y, "版权", 20, true, ViewHelpers.palette.text, 120)
    local copyright = self:copyrightLine(book)
    if copyright == "" then
        copyright = self:bookMetaLine(book)
    end
    ViewHelpers.draw_wrapped_text(bb, 48, copyright_y + 38, copyright, 14, false, ViewHelpers.palette.muted, page_w - 96, 44, 2, 24)
    if self.status.lastError and self.status.lastError ~= "" then
        ViewHelpers.draw_wrapped_text(bb, 48, copyright_y + 98, ViewHelpers.truncate(self:friendlyError(self.status.lastError), 90), 14, false, ViewHelpers.palette.muted, page_w - 96, 44, 2, 24)
    elseif self.status.lastReviewError and self.status.lastReviewError ~= "" then
        ViewHelpers.draw_text(bb, 48, copyright_y + 98, "书评暂不可用", 14, false, ViewHelpers.palette.muted, page_w - 96)
    end
    self:renderReviews(bb, 840)
end

function BookDetailView:onTap(_, ges)
    local x, y = ges.pos.x, ges.pos.y
    if y < 78 then
        if self.on_back then self.on_back() end
        return true
    end
    if x >= 336 and x <= 520 and y >= 330 and y < 382 then if self.on_open then self.on_open(self.book) end; return true end
    if x >= 540 and x <= 724 and y >= 330 and y < 382 then if self.on_download_full then self.on_download_full(self.book) end; return true end
    if x >= 336 and x <= 448 and y >= 406 and y < 444 then if self.on_chapters then self.on_chapters(self.book) end; return true end
    if x >= 464 and x <= 576 and y >= 406 and y < 444 then if self.on_refresh_info then self.on_refresh_info(self.book) end; return true end
    if x >= 592 and x <= 724 and y >= 406 and y < 444 then if self.on_clear_cache then self.on_clear_cache(self.book) end; return true end
    if y >= 836 and y < 884 and x >= self.dimen.w - 216 and x < self.dimen.w - 130 then self:loadReviews("Recommended"); return true end
    if y >= 836 and y < 884 and x >= self.dimen.w - 130 and x < self.dimen.w - 44 then self:loadReviews("Newest"); return true end
    return true
end

return BookDetailView
