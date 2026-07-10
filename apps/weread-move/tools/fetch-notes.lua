io.stdout:setvbuf("line")
os.setlocale("C", "numeric")

local app_dir = os.getenv("RM_WEREAD_APP_DIR") or "/home/root/xovi/exthome/appload/weread-move"
local koreader_dir = os.getenv("KO_DIR") or "/home/root/xovi/exthome/appload/koreader"
package.path = app_dir .. "/?.lua;" .. app_dir .. "/lib/?.lua;" .. app_dir .. "/views/?.lua;" .. app_dir .. "/tools/?.lua;" .. package.path
package.path =
    app_dir .. "/../../third_party/weread.koplugin/?.lua;" ..
    app_dir .. "/../../third_party/weread.koplugin/lib/?.lua;" ..
    "/home/root/xovi/exthome/appload/koreader/plugins/weread.koplugin/?.lua;" ..
    "/home/root/xovi/exthome/appload/koreader/plugins/weread.koplugin/lib/?.lua;" ..
    package.path

local KoreaderPaths = require("koreader_paths")
KoreaderPaths.append(koreader_dir)

local ConfigBridge = require("config_bridge")
local Client = require("lib.client")
local Content = require("lib.content")
local Json = require("json_util")

local mode = tostring((arg and arg[1]) or "")
local book_id = tostring((arg and arg[2]) or "")

local function emit(row)
    print(Json.encode(row))
end

local function fail(message)
    emit({ state = "error", message = tostring(message or "unknown") })
    os.exit(1)
end

local function text(value)
    return tostring(value or "")
end

local function trim(value)
    return text(value):gsub("^%s+", ""):gsub("%s+$", "")
end

local function number(value)
    return tonumber(value or 0) or 0
end

local function strip_html(value)
    value = text(value)
    value = value:gsub("<br%s*/?>", "\n")
    value = value:gsub("<[^>]+>", "")
    value = value:gsub("&nbsp;", " ")
    value = value:gsub("&lt;", "<")
    value = value:gsub("&gt;", ">")
    value = value:gsub("&amp;", "&")
    return trim(value)
end

local function truncate(value, max_len)
    value = strip_html(value)
    if #value <= max_len then
        return value
    end
    return value:sub(1, max_len)
end

local function utf8_len(value)
    value = text(value)
    local count = 0
    local index = 1
    local length = #value
    while index <= length do
        local byte = value:byte(index) or 0
        if byte < 0x80 then
            index = index + 1
        elseif byte < 0xE0 then
            index = index + 2
        elseif byte < 0xF0 then
            index = index + 3
        else
            index = index + 4
        end
        count = count + 1
    end
    return count
end

local function valid_utf8(value)
    value = text(value)
    local index = 1
    while index <= #value do
        local first = value:byte(index) or 0
        local width = 1
        if first < 0x80 then
            width = 1
        elseif first >= 0xC2 and first <= 0xDF then
            width = 2
        elseif first >= 0xE0 and first <= 0xEF then
            width = 3
        elseif first >= 0xF0 and first <= 0xF4 then
            width = 4
        else
            return false
        end
        if index + width - 1 > #value then
            return false
        end
        for continuation = index + 1, index + width - 1 do
            local byte = value:byte(continuation) or 0
            if byte < 0x80 or byte > 0xBF then
                return false
            end
        end
        index = index + width
    end
    return true
end

local function utf8_prefix(value, max_chars)
    value = text(value)
    local index = 1
    local count = 0
    while index <= #value and count < max_chars do
        local byte = value:byte(index) or 0
        if byte < 0x80 then
            index = index + 1
        elseif byte < 0xE0 then
            index = index + 2
        elseif byte < 0xF0 then
            index = index + 3
        else
            index = index + 4
        end
        count = count + 1
    end
    return value:sub(1, index - 1)
end

local function utf8_byte_index(value, character_offset)
    value = text(value)
    local wanted = math.max(0, math.floor(tonumber(character_offset) or 0))
    local index = 1
    local count = 0
    while index <= #value and count < wanted do
        local byte = value:byte(index) or 0
        if byte < 0x80 then
            index = index + 1
        elseif byte < 0xE0 then
            index = index + 2
        elseif byte < 0xF0 then
            index = index + 3
        else
            index = index + 4
        end
        count = count + 1
    end
    return math.min(index, #value + 1)
end

local function utf8_slice(value, start_character, end_character)
    value = text(value)
    local start_byte = utf8_byte_index(value, start_character)
    local end_byte = utf8_byte_index(value, end_character)
    if end_byte <= start_byte then
        return ""
    end
    return value:sub(start_byte, end_byte - 1)
end

local function run_notebooks(client)
    local result = client:gateway("/user/notebooks", { count = 30 })
    local books = type(result) == "table" and result.books or {}
    local count = 0
    for _, entry in ipairs(books or {}) do
        local book = entry.book or {}
        local id = trim(entry.bookId or book.bookId)
        if id ~= "" then
            local review_count = number(entry.reviewCount)
            local note_count = number(entry.noteCount)
            local bookmark_count = number(entry.bookmarkCount)
            count = count + 1
            emit({
                state = "row",
                kind = "notebook",
                bookId = id,
                title = trim(book.title),
                author = trim(book.author),
                cover = trim(book.cover),
                reviewCount = review_count,
                noteCount = note_count,
                bookmarkCount = bookmark_count,
                totalNotes = review_count + note_count + bookmark_count,
                progress = trim(entry.readingProgress),
                sort = number(entry.sort),
            })
        end
    end
    emit({ state = "done", mode = "notebooks", count = count })
end

local function chapter_names(bookmarks_resp)
    local out = {}
    for _, chapter in ipairs((bookmarks_resp or {}).chapters or {}) do
        local uid = trim(chapter.chapterUid)
        if uid ~= "" then
            out[uid] = trim(chapter.title)
        end
    end
    return out
end

local function run_book_notes(client)
    book_id = trim(book_id)
    if book_id == "" then
        error("empty book id")
    end

    local bookmarks_resp = client:gateway("/book/bookmarklist", { bookId = book_id })
    local reviews_resp = client:gateway("/review/list/mine", { bookid = book_id, count = 30 })
    local chapters = chapter_names(bookmarks_resp)
    local count = 0

    for _, mark in ipairs((bookmarks_resp or {}).updated or {}) do
        count = count + 1
        local chapter_uid = trim(mark.chapterUid)
        emit({
            state = "row",
            kind = "highlight",
            bookId = book_id,
            chapterUid = chapter_uid,
            chapter = chapters[chapter_uid] or "",
            range = trim(mark.range),
            colorStyle = trim(mark.colorStyle),
            text = truncate(mark.markText, 220),
            createTime = number(mark.createTime),
        })
    end

    for _, wrapper in ipairs((reviews_resp or {}).reviews or {}) do
        local review = wrapper.review or wrapper
        count = count + 1
        local chapter_uid = trim(review.chapterUid)
        emit({
            state = "row",
            kind = "thought",
            bookId = book_id,
            chapterUid = chapter_uid,
            chapter = trim(review.chapterName) ~= "" and trim(review.chapterName) or (chapters[chapter_uid] or ""),
            range = trim(review.range),
            thought = truncate(review.content or review.htmlContent, 220),
            star = number(review.star),
            createTime = number(review.createTime),
        })
    end

    emit({ state = "done", mode = "book", count = count })
end

local function review_text(row)
    local review = row
    if type(row) == "table" and type(row.review) == "table" then
        review = row.review
        if type(review.review) == "table" then
            review = review.review
        end
    end
    return truncate((review or {}).content or (review or {}).htmlContent or (review or {}).abstract, 180)
end

local function review_author(row)
    if type(row) == "table" and type(row.author) == "table" then
        return trim(row.author.name or row.author.userName)
    end
    local review = row
    if type(row) == "table" and type(row.review) == "table" then
        review = row.review
        if type(review.review) == "table" then
            review = review.review
        end
    end
    if type(review) == "table" and type(review.author) == "table" then
        return trim(review.author.name or review.author.userName)
    end
    return trim((review or {}).userName)
end

local function range_text_fallback(xhtml, range)
    local start_s, end_s = tostring(range or ""):match("(%d+)%s*[-:]%s*(%d+)")
    local start_i = tonumber(start_s or "")
    local end_i = tonumber(end_s or "")
    if not start_i or not end_i or end_i <= start_i or type(xhtml) ~= "string" or xhtml == "" then
        return ""
    end
    local function clean_anchor(value)
        local clean = strip_html(value)
        local lower = clean:lower()
        if clean == "" or not valid_utf8(clean) or clean:find("<", 1, true)
            or lower:find("class=", 1, true) or lower:find("src=", 1, true)
            or lower:find("alt=", 1, true) or lower:find("data-", 1, true)
            or lower:find(".jpg", 1, true) or lower:find(".png", 1, true) then
            return ""
        end
        return utf8_prefix(clean, 80)
    end
    local clean = clean_anchor(utf8_slice(xhtml, start_i, end_i))
    if clean ~= "" then
        return clean
    end
    local expanded = utf8_slice(xhtml, math.max(0, start_i - 24), end_i + 24)
    return clean_anchor(expanded)
end

local function plain_offsets_for_range(xhtml, range)
    local start_s, end_s = tostring(range or ""):match("(%d+)%s*[-:]%s*(%d+)")
    local start_i = tonumber(start_s or "")
    local end_i = tonumber(end_s or "")
    if not start_i or not end_i or end_i <= start_i or type(xhtml) ~= "string" or xhtml == "" then
        return nil, nil
    end
    local prefix = strip_html(utf8_slice(xhtml, 0, start_i))
    local through = strip_html(utf8_slice(xhtml, 0, end_i))
    local plain_start = utf8_len(prefix)
    local plain_end = utf8_len(through)
    if plain_end <= plain_start then
        return nil, nil
    end
    return plain_start, plain_end
end

local function chapter_names_from_bestmarks(bestmarks_resp)
    local out = {}
    for _, chapter in ipairs((bestmarks_resp or {}).chapters or {}) do
        local uid = trim(chapter.chapterUid)
        if uid ~= "" then
            out[uid] = trim(chapter.title)
        end
    end
    return out
end

local function run_popular_marks(client)
    book_id = trim(book_id)
    if book_id == "" then
        error("empty book id")
    end

    local bestmarks_resp = client:gateway("/book/bestbookmarks", {
        bookId = book_id,
        chapterUid = 0,
        synckey = 0,
    })
    local chapters = chapter_names_from_bestmarks(bestmarks_resp)
    local count = 0
    local review_count = 0
    local max_marks = math.min(120, math.max(8, tonumber(os.getenv("RM_WEREAD_MARK_LIMIT") or "80") or 80))
    local skip_reviews = os.getenv("RM_WEREAD_SKIP_REVIEWS") == "1"

    for _, mark in ipairs((bestmarks_resp or {}).items or {}) do
        if count >= max_marks then
            break
        end
        local chapter_uid = trim(mark.chapterUid)
        local range = trim(mark.range)
        local mark_text = truncate(mark.markText, 180)
        local reviews = {}

        if mark_text ~= "" then
            count = count + 1
            emit({
                state = "row",
                kind = "popular_mark",
                bookId = book_id,
                chapterUid = chapter_uid,
                chapter = chapters[chapter_uid] or "",
                range = range,
                text = mark_text,
                totalCount = number(mark.totalCount),
                reviews = reviews,
            })
        end

        if not skip_reviews and chapter_uid ~= "" and range ~= "" then
            local ok, reviews_resp = pcall(function()
                return client:gateway("/book/readreviews", {
                    bookId = book_id,
                    chapterUid = tonumber(chapter_uid) or chapter_uid,
                    reviews = {
                        {
                            range = range,
                            maxIdx = 0,
                            count = 8,
                            synckey = 0,
                        },
                    },
                })
            end)
            if ok and type(reviews_resp) == "table" then
                for _, group in ipairs(reviews_resp.reviews or {}) do
                    for _, page_review in ipairs(group.pageReviews or {}) do
                        local content = review_text(page_review)
                        if content ~= "" then
                            review_count = review_count + 1
                            table.insert(reviews, {
                                author = review_author(page_review),
                                content = content,
                            })
                            emit({
                                state = "row",
                                kind = "popular_review",
                                bookId = book_id,
                                chapterUid = chapter_uid,
                                range = range,
                                author = review_author(page_review),
                                text = content,
                            })
                        end
                    end
                end
            end
        end

    end

    emit({ state = "done", mode = "popular", count = count, reviewCount = review_count })
end

local function run_range_reviews(client)
    book_id = trim(book_id)
    local chapter_uid = trim(arg and arg[3])
    local range = trim(arg and arg[4])
    if book_id == "" or chapter_uid == "" or range == "" then
        error("usage: fetch-notes.lua range_reviews <bookId> <chapterUid> <range>")
    end

    local response = client:gateway("/book/readreviews", {
        bookId = book_id,
        chapterUid = tonumber(chapter_uid) or chapter_uid,
        reviews = {
            {
                range = range,
                maxIdx = 0,
                count = 12,
                synckey = 0,
            },
        },
    })
    local review_count = 0
    for _, group in ipairs((response or {}).reviews or {}) do
        local response_range = trim(group.range)
        if response_range == "" then
            response_range = range
        end
        for _, page_review in ipairs(group.pageReviews or {}) do
            local content = review_text(page_review)
            if content ~= "" then
                review_count = review_count + 1
                emit({
                    state = "row",
                    kind = "popular_review",
                    bookId = book_id,
                    chapterUid = chapter_uid,
                    range = response_range,
                    author = review_author(page_review),
                    text = content,
                })
            end
        end
    end
    emit({ state = "done", mode = "range_reviews", count = review_count, reviewCount = review_count })
end

local function run_chapter_marks(client, settings)
    book_id = trim(book_id)
    local chapter_key = trim(arg and arg[3])
    local chapter_index_key = chapter_key:match("^index:(%d+)$")
    local page_start = tonumber(arg and arg[4])
    local page_end = tonumber(arg and arg[5])
    local chapter_index = math.max(1, number(chapter_index_key or chapter_key))
    if book_id == "" then
        error("empty book id")
    end

    local work_book = { bookId = book_id, book_id = book_id }
    Content.ensure_reader_state(client, work_book)
    local chapters = Content.fetch_catalog(client, work_book)
    local chapter = {}
    if not chapter_index_key then
        for index, row in ipairs(chapters or {}) do
            if trim(row.chapterUid or row.uid or row.chapter_uid) == chapter_key then
                chapter = row
                chapter_index = index
                break
            end
        end
    end
    if not chapter.chapterUid then
        chapter = chapters[chapter_index] or {}
    end
    local chapter_uid = trim(chapter.chapterUid or chapter.uid or chapter.chapter_uid)
    if chapter_uid == "" then
        emit({ state = "done", mode = "chapter", count = 0, reviewCount = 0, chapterIndex = chapter_index })
        return
    end

    local underline_resp = client:gateway("/book/underlines", {
        bookId = book_id,
        chapterUid = tonumber(chapter_uid) or chapter_uid,
    })
    local underlines = (underline_resp or {}).underlines or {}
    local chapter_xhtml = ""
    pcall(function()
        chapter_xhtml = Content.fetch_chapter_xhtml(client, settings, work_book, chapter)
    end)
    local ranges = {}
    local underlines_by_range = {}
    local count = 0
    local max_ranges = math.min(80, math.max(8, tonumber(os.getenv("RM_WEREAD_MARK_LIMIT") or "60") or 60))
    local function overlaps_page_window(plain_start, plain_end)
        if not page_start or not page_end or page_end <= page_start then
            return true
        end
        if not plain_start or not plain_end or plain_end <= plain_start then
            return false
        end
        local padding = 8
        return plain_start < page_end + padding and plain_end > page_start - padding
    end
    for _, underline in ipairs(underlines) do
        local range = trim(underline.range)
        local mark_text = truncate(underline.markText or underline.text or underline.abstract, 180)
        if mark_text == "" then
            mark_text = range_text_fallback(chapter_xhtml, range)
        end
        if mark_text:find("<", 1, true) or mark_text:find("class=", 1, true) then
            mark_text = ""
        end
        local range_text_fallback = mark_text == ""
        local plain_start, plain_end = plain_offsets_for_range(chapter_xhtml, range)
        if range ~= "" and overlaps_page_window(plain_start, plain_end) and count < max_ranges then
            count = count + 1
            table.insert(ranges, range)
            underlines_by_range[range] = underline
            emit({
                state = "row",
                kind = "popular_mark",
                bookId = book_id,
                chapterUid = chapter_uid,
                chapter = trim(chapter.title or chapter.chapterName),
                range = range,
                text = mark_text,
                anchorText = mark_text,
                plainStart = plain_start,
                plainEnd = plain_end,
                pageStart = page_start,
                pageEnd = page_end,
                rangeOnly = range_text_fallback,
                totalCount = number(underline.totalCount or underline.count),
                reviews = {},
            })
        end
    end

    local reviews_by_range = {}
    local review_count = 0
    local skip_reviews = os.getenv("RM_WEREAD_SKIP_REVIEWS") == "1"
    if skip_reviews then
        emit({ state = "done", mode = "chapter", count = count, reviewCount = 0, chapterIndex = chapter_index })
        return
    end
    if #ranges > 0 then
        local batch_size = 5
        for batch_start = 1, #ranges, batch_size do
            local requests = {}
            for index = batch_start, math.min(#ranges, batch_start + batch_size - 1) do
                local range = ranges[index]
                requests[#requests + 1] = {
                    range = range,
                    maxIdx = 0,
                    count = 8,
                    synckey = 0,
                }
            end
            local ok_reviews, reviews_resp = pcall(function()
                return client:gateway("/book/readreviews", {
                    bookId = book_id,
                    chapterUid = tonumber(chapter_uid) or chapter_uid,
                    reviews = requests,
                })
            end)
            if ok_reviews and type(reviews_resp) == "table" then
                for _, group in ipairs(reviews_resp.reviews or {}) do
                    local range = trim(group.range)
                    local bucket = reviews_by_range[range] or {}
                    for _, page_review in ipairs(group.pageReviews or {}) do
                        local content = review_text(page_review)
                        if content ~= "" then
                            review_count = review_count + 1
                            table.insert(bucket, {
                                author = review_author(page_review),
                                content = content,
                            })
                            emit({
                                state = "row",
                                kind = "popular_review",
                                bookId = book_id,
                                chapterUid = chapter_uid,
                                range = range,
                                author = review_author(page_review),
                                text = content,
                            })
                        end
                    end
                    reviews_by_range[range] = bucket
                end
            end
            if review_count >= 80 then
                break
            end
        end
    end

    emit({ state = "done", mode = "chapter", count = count, reviewCount = review_count, chapterIndex = chapter_index })
end
local ok, err = pcall(function()
    local config = ConfigBridge:new()
    if not config:is_api_configured() then
        error("api key missing")
    end

    local client = Client:new(config)
    if mode == "notebooks" then
        run_notebooks(client)
    elseif mode == "book" then
        run_book_notes(client)
    elseif mode == "popular" then
        run_popular_marks(client)
    elseif mode == "chapter" then
        run_chapter_marks(client, config)
    elseif mode == "range_reviews" then
        run_range_reviews(client)
    else
        error("usage: fetch-notes.lua notebooks|book|popular|chapter|range_reviews [bookId]")
    end
end)

if not ok then
    fail(err)
end
