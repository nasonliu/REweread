io.stdout:setvbuf("line")

local app_dir = os.getenv("RM_WEREAD_APP_DIR") or (arg and arg[0] and arg[0]:match("^(.*)/[^/]+$")) or "."
package.path = app_dir .. "/?.lua;" .. app_dir .. "/lib/?.lua;" .. app_dir .. "/tools/?.lua;" .. package.path

local ChapterCache = require("chapter_cache")
local NativeFramebuffer = require("native_framebuffer")
local NativeInput = require("native_input")
local NativePaginator = require("native_paginator")
local NativeRaster = require("native_raster")
local NativeShelf = require("native_shelf")
local ReaderDocument = require("reader_document")

local RASTER_WIDTH = 360
local RASTER_HEIGHT = 540

local function env_number(name, fallback, min_value, max_value)
    local value = tonumber(os.getenv(name) or "")
    if not value then
        value = fallback
    end
    if min_value and value < min_value then
        value = min_value
    end
    if max_value and value > max_value then
        value = max_value
    end
    return math.floor(value)
end

function reader_typography()
    local font_size = env_number("RM_WEREAD_FONT_SIZE", 18, 14, 32)
    local heading_size = env_number("RM_WEREAD_HEADING_SIZE", font_size + 4, font_size, 40)
    local line_height = env_number("RM_WEREAD_LINE_HEIGHT", 24, font_size + 2, 48)
    local heading_line_height = env_number("RM_WEREAD_HEADING_LINE_HEIGHT", 26, heading_size + 2, 54)
    local margin = env_number("RM_WEREAD_MARGIN", 22, 12, 64)
    return {
        font_size = font_size,
        heading_size = heading_size,
        line_height = line_height,
        heading_line_height = heading_line_height,
        margin = margin,
        paragraph_gap = env_number("RM_WEREAD_PARAGRAPH_GAP", 10, 0, 32),
    }
end

local function typography_label(typography)
    return "font_size=" .. tostring(typography.font_size)
        .. ",line_height=" .. tostring(typography.line_height)
        .. ",margin=" .. tostring(typography.margin)
end

local function load_book(book_id, typography)
    local cache = ChapterCache:new()
    local path = cache:first_cached_chapter_path(book_id)
    if not path then
        error("no cached chapter for " .. tostring(book_id))
    end
    local xhtml = cache:read_chapter(path)
    local document = ReaderDocument.from_xhtml(xhtml)
    local pages = NativePaginator.paginate(document, {
        page_width = RASTER_WIDTH,
        page_height = RASTER_HEIGHT,
        font_size = typography.font_size,
        heading_size = typography.heading_size,
        body_line_height = typography.line_height,
        heading_line_height = typography.heading_line_height,
        margin = typography.margin,
        paragraph_gap = typography.paragraph_gap,
        image_height = typography.image_height,
    })
    local image_root = cache:images_dir(book_id)
    return path, pages, image_root
end

local function render_page(fb, pages, page_index, typography, image_root)
    local raster = NativeRaster:new{ width = RASTER_WIDTH, height = RASTER_HEIGHT }
    local page_render = raster:draw_reader_page(pages[page_index] or { items = {} }, {
        page_number = tostring(page_index) .. "/" .. tostring(#pages),
        font_size = typography.font_size,
        heading_size = typography.heading_size,
        body_line_height = typography.line_height,
        heading_line_height = typography.heading_line_height,
        margin = typography.margin,
        paragraph_gap = typography.paragraph_gap,
        image_height = typography.image_height,
        image_root = image_root,
    })
    fb:blit_raster(raster)
    fb:refresh()
    return page_render or {}
end

local function event_to_raster(event, fb)
    return {
        x = math.floor((tonumber(event.x) or 0) * RASTER_WIDTH / math.max(1, fb.width)),
        y = math.floor((tonumber(event.y) or 0) * RASTER_HEIGHT / math.max(1, fb.height)),
    }
end

local function render_book(book_id)
    local typography = reader_typography()
    local path, pages, image_root = load_book(book_id, typography)

    local fb = NativeFramebuffer:open("/dev/fb0")
    local page_index = 1
    local font_glyphs = 0
    local footer_glyphs = 0
    local reader_images = 0
    local ok, err = pcall(function()
        local page_render = render_page(fb, pages, page_index, typography, image_root)
        font_glyphs = page_render.fontGlyphs or 0
        footer_glyphs = page_render.footerGlyphs or 0
        reader_images = page_render.readerImages or 0
        local loop_seconds = tonumber(os.getenv("RM_WEREAD_NATIVE_LOOP_SECONDS") or "0") or 0
        if loop_seconds > 0 then
            local input = NativeInput:open("/dev/input/touchscreen0")
            local deadline = os.time() + loop_seconds
            while os.time() < deadline do
                local event = input:read_event(250)
                if event and event.type == "release" then
                    if event.x and event.x > 0 then
                        if event.x > 500 and page_index < #pages then
                            page_index = page_index + 1
                            page_render = render_page(fb, pages, page_index, typography, image_root)
                            font_glyphs = page_render.fontGlyphs or font_glyphs
                            footer_glyphs = page_render.footerGlyphs or footer_glyphs
                            reader_images = page_render.readerImages or reader_images
                        elseif event.x <= 500 and page_index > 1 then
                            page_index = page_index - 1
                            page_render = render_page(fb, pages, page_index, typography, image_root)
                            font_glyphs = page_render.fontGlyphs or font_glyphs
                            footer_glyphs = page_render.footerGlyphs or footer_glyphs
                            reader_images = page_render.readerImages or reader_images
                        end
                    end
                end
            end
            input:close()
        end
    end)
    local info = fb:info()
    if not ok then
        fb:close()
        error(err)
    end
    return {
        framebufferHandle = fb,
        path = path,
        pages = #pages,
        page = page_index,
        fontGlyphs = font_glyphs,
        footerGlyphs = footer_glyphs,
        readerImages = reader_images,
        typography = typography_label(typography),
        framebuffer = tostring(info.width) .. "x" .. tostring(info.height) .. "x" .. tostring(info.bpp),
    }
end

local function render_shelf()
    local shelf = NativeShelf:new(os.getenv("RM_WEREAD_CACHE_ROOT"))
    local data = shelf:load()
    local fb = NativeFramebuffer:open("/dev/fb0")
    local selected_book_id = data.books[1] and data.books[1].bookId or ""
    local ok, err = pcall(function()
        local raster = NativeRaster:new{ width = RASTER_WIDTH, height = RASTER_HEIGHT }
        local shelf_render = raster:draw_shelf(data.books)
        data.coverImages = shelf_render and shelf_render.coverImages or 0
        data.coverError = shelf_render and shelf_render.coverError or ""
        fb:blit_raster(raster)
        fb:refresh()
        local loop_seconds = tonumber(os.getenv("RM_WEREAD_NATIVE_LOOP_SECONDS") or "0") or 0
        if loop_seconds > 0 then
            local input = NativeInput:open("/dev/input/touchscreen0")
            local deadline = os.time() + loop_seconds
            while os.time() < deadline do
                local event = input:read_event(250)
                if event and event.type == "release" then
                    local point = event_to_raster(event, fb)
                    local book = shelf:book_at(data.books, point.x, point.y)
                    if book then
                        selected_book_id = book.bookId
                        break
                    end
                end
            end
            input:close()
        end
    end)
    local info = fb:info()
    if not ok then
        fb:close()
        error(err)
    end
    return {
        framebufferHandle = fb,
        books = #data.books,
        coverImages = data.coverImages or 0,
        coverError = data.coverError or "",
        selectedBookId = selected_book_id,
        framebuffer = tostring(info.width) .. "x" .. tostring(info.height) .. "x" .. tostring(info.bpp),
    }
end

local screen = os.getenv("RM_WEREAD_NATIVE_SCREEN") or "shelf"
local input_info = NativeInput.device_info("/dev/input/touchscreen0")
local held_framebuffer = nil
print("native_app=ok")
print("screen=" .. tostring(screen))
print("qtfbKey=" .. tostring(os.getenv("QTFB_KEY") or ""))
print("qtfbMode=" .. tostring(os.getenv("QTFB_SHIM_MODE") or ""))
if screen == "reader" or os.getenv("RM_WEREAD_NATIVE_BOOK_ID") then
    local book_id = os.getenv("RM_WEREAD_NATIVE_BOOK_ID") or ""
    if book_id == "" then
        error("RM_WEREAD_NATIVE_BOOK_ID is required for the legacy reader screen")
    end
    local result = render_book(book_id)
    held_framebuffer = result.framebufferHandle
    print("bookId=" .. tostring(book_id))
    print("chapter=" .. tostring(result.path))
    print("pages=" .. tostring(result.pages))
    print("page=" .. tostring(result.page))
    print("fontGlyphs=" .. tostring(result.fontGlyphs))
    print("footerGlyphs=" .. tostring(result.footerGlyphs))
    print("readerImages=" .. tostring(result.readerImages))
    print("typography=" .. tostring(result.typography))
    print("framebuffer=" .. tostring(result.framebuffer))
else
    local result = render_shelf()
    held_framebuffer = result.framebufferHandle
    print("books=" .. tostring(result.books))
    print("coverImages=" .. tostring(result.coverImages))
    print("coverError=" .. tostring(result.coverError))
    print("selectedBookId=" .. tostring(result.selectedBookId))
    print("framebuffer=" .. tostring(result.framebuffer))
end
print("touchscreen=" .. tostring(input_info.name))

local sleep_seconds = tonumber(os.getenv("RM_WEREAD_NATIVE_SLEEP") or "3600") or 3600
if sleep_seconds > 0 then
    os.execute("sleep " .. tostring(math.floor(sleep_seconds)))
end
if held_framebuffer then
    held_framebuffer:close()
end
