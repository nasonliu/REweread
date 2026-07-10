local NativeRaster = {}
NativeRaster.__index = NativeRaster

local NativeImage = require("native_cover_image")
local NativeFont = require("native_font")

local WHITE = { 255, 255, 255 }
local BLACK = { 0, 0, 0 }
local GRAY = { 210, 210, 210 }
local LIGHT = { 238, 238, 238 }

local function clamp(value, min_value, max_value)
    value = tonumber(value) or 0
    if value < min_value then return min_value end
    if value > max_value then return max_value end
    return value
end

local function utf8_len(text)
    local count = 0
    for _ in tostring(text or ""):gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        count = count + 1
    end
    return count
end

local function hash_text(text)
    local hash = 0
    for i = 1, #tostring(text or "") do
        hash = (hash * 33 + tostring(text):byte(i)) % 9973
    end
    return hash
end

local function cover_color(book)
    local palette = {
        { 32, 96, 170 },
        { 160, 54, 54 },
        { 38, 126, 96 },
        { 148, 88, 32 },
        { 112, 76, 150 },
        { 46, 120, 146 },
        { 168, 120, 24 },
        { 92, 104, 50 },
    }
    return palette[(hash_text(book and book.bookId or book and book.title or "") % #palette) + 1]
end

local function local_cover_path(book)
    if not book then return nil end
    if book.localCover and book.localCover ~= "" then
        return book.localCover
    end
    if not book.bookId then return nil end
    return "/home/root/.local/share/rm-weread/covers/" .. tostring(book.bookId):gsub("[^%w%._%-]", "_") .. ".jpg"
end

function NativeRaster:new(opts)
    opts = opts or {}
    local width = tonumber(opts.width or 320) or 320
    local height = tonumber(opts.height or 480) or 480
    local pixels = {}
    local obj = setmetatable({
        width = width,
        height = height,
        pixels = pixels,
    }, self)
    obj:clear(WHITE)
    return obj
end

function NativeRaster:clear(color)
    color = color or WHITE
    for y = 1, self.height do
        local row = {}
        for x = 1, self.width do
            row[x] = color
        end
        self.pixels[y] = row
    end
end

function NativeRaster:rect(x, y, w, h, color)
    color = color or BLACK
    local x1 = clamp(math.floor(x or 1), 1, self.width)
    local y1 = clamp(math.floor(y or 1), 1, self.height)
    local x2 = clamp(math.floor((x or 1) + (w or 0) - 1), 1, self.width)
    local y2 = clamp(math.floor((y or 1) + (h or 0) - 1), 1, self.height)
    for py = y1, y2 do
        local row = self.pixels[py]
        for px = x1, x2 do
            row[px] = color
        end
    end
end

function NativeRaster:set_pixel(x, y, color)
    x = math.floor(x or 1)
    y = math.floor(y or 1)
    if x < 1 or x > self.width or y < 1 or y > self.height then
        return
    end
    self.pixels[y][x] = color or BLACK
end

function NativeRaster:line_bar(x, y, max_w, text, opts)
    opts = opts or {}
    local char_w = opts.char_w or 7
    local h = opts.h or 4
    local min_w = opts.min_w or 18
    local len = utf8_len(text)
    local w = math.min(max_w, math.max(min_w, len * char_w))
    self:rect(x, y, w, h, opts.color or BLACK)
end

local function font_options(opts, size_key, default_size)
    opts = opts or {}
    return {
        size = opts[size_key] or default_size,
        eink_contrast = opts.eink_contrast ~= false,
        embolden = opts.embolden,
        alpha_gamma = opts.alpha_gamma,
        alpha_floor = opts.alpha_floor,
    }
end

function NativeRaster:draw_footer_text(text, opts)
    opts = opts or {}
    local margin = opts.margin or 22
    local footer_font = NativeFont:new(font_options(opts, "footer_size", 13))
    if not footer_font then
        return 0
    end
    local footer_text = tostring(text or "")
    local measured = footer_font:measure_text(footer_text)
    local footer_x = math.floor((self.width - measured.width) / 2)
    footer_x = clamp(footer_x, margin, self.width - margin)
    local footer_y = opts.y or (self.height - 30)
    local result = footer_font:draw_text(self, footer_x, footer_y, footer_text, {
        max_x = self.width - margin,
        color = BLACK,
    })
    return result.glyphs or 0
end

function NativeRaster:resolve_reader_image_path(src, opts)
    opts = opts or {}
    src = tostring(src or "")
    if src == "" or src:match("^https?://") or src:match("^//") then
        return nil
    end
    if src:sub(1, 1) == "/" then
        return src
    end
    local filename = src:match("^%.%./images/([^/]+)$") or src:match("^images/([^/]+)$")
    if filename and opts.image_root then
        return tostring(opts.image_root):gsub("/+$", "") .. "/" .. filename:gsub("[^%w%._%-]", "_")
    end
    return nil
end

function NativeRaster:draw_reader_image(item, x, y, w, h, opts)
    local image_path = self:resolve_reader_image_path(item and item.src, opts)
    if image_path then
        local ok = self:draw_cover_image(image_path, x, y, w, h)
        if ok then
            return true, image_path
        end
    end
    self:rect(x, y, w, h, LIGHT)
    self:rect(x + 8, y + 8, w - 16, h - 16, WHITE)
    self:rect(x + 18, y + 28, w - 36, 2, BLACK)
    self:rect(x + 18, y + 42, math.floor((w - 36) * 0.66), 2, BLACK)
    return false, image_path
end

function NativeRaster:draw_reader_page(page, opts)
    opts = opts or {}
    self:clear(WHITE)
    local margin = opts.margin or 22
    local y = opts.top or 34
    local font = NativeFont:new(font_options(opts, "font_size", 18))
    local heading_font = NativeFont:new(font_options(opts, "heading_size", 22))
    local body_line_height = opts.body_line_height or opts.line_height or 24
    local heading_line_height = opts.heading_line_height or 26
    local paragraph_gap = opts.paragraph_gap or 10
    local image_height = opts.image_height or 84
    local font_glyphs = 0
    local reader_images = 0
    self:rect(margin, y - 18, self.width - margin * 2, 1, GRAY)
    for _, item in ipairs((page and page.items) or {}) do
        if item.type == "image" then
            local ok = self:draw_reader_image(item, margin, y, self.width - margin * 2, image_height - paragraph_gap, opts)
            if ok then
                reader_images = reader_images + 1
            end
            y = y + image_height
        elseif item.type == "heading" then
            for _, line in ipairs(item.lines or {}) do
                if heading_font then
                    for _, wrapped in ipairs(heading_font:wrap_text(line, self.width - margin * 2)) do
                        local result = heading_font:draw_text(self, margin, y, wrapped, {
                            max_x = self.width - margin,
                            color = BLACK,
                        })
                        font_glyphs = font_glyphs + (result.glyphs or 0)
                        y = y + heading_line_height
                    end
                else
                    self:line_bar(margin, y, self.width - margin * 2, line, { char_w = 11, h = 9, min_w = 80 })
                    y = y + heading_line_height
                end
            end
            y = y + paragraph_gap
        else
            for _, line in ipairs(item.lines or {}) do
                if font then
                    for _, wrapped in ipairs(font:wrap_text(line, self.width - margin * 2)) do
                        local result = font:draw_text(self, margin, y, wrapped, {
                            max_x = self.width - margin,
                            color = BLACK,
                        })
                        font_glyphs = font_glyphs + (result.glyphs or 0)
                        y = y + body_line_height
                    end
                else
                    self:line_bar(margin, y, self.width - margin * 2, line, { char_w = 8, h = 5, min_w = 35 })
                    y = y + body_line_height
                end
            end
            y = y + paragraph_gap
        end
        if y > self.height - 34 then
            break
        end
    end
    self:rect(margin, self.height - 24, self.width - margin * 2, 1, GRAY)
    local footer_glyphs = 0
    if opts.page_number then
        footer_glyphs = self:draw_footer_text(opts.page_number, {
            margin = margin,
            footer_size = opts.footer_size,
        })
    end
    return {
        fontGlyphs = font_glyphs,
        footerGlyphs = footer_glyphs,
        readerImages = reader_images,
    }
end

function NativeRaster:draw_cover_image(path, x, y, w, h)
    local image, err = NativeImage.open(path)
    if not image then
        return false, err
    end
    for py = 0, h - 1 do
        local sy = math.floor(py * image.height / h) + 1
        for px = 0, w - 1 do
            local sx = math.floor(px * image.width / w) + 1
            local color = NativeImage.sample(image, sx, sy)
            if color then
                self:set_pixel(x + px, y + py, color)
            end
        end
    end
    return true
end

function NativeRaster:draw_shelf(books, opts)
    opts = opts or {}
    books = books or {}
    self:clear(WHITE)
    self:rect(18, 36, self.width - 36, 1, GRAY)

    local margin = 18
    local top = 48
    local gap = 20
    local row_gap = 10
    local card_w = 92
    local card_h = 146
    local cover_h = 136
    local max_books = math.min(9, #books)
    local cover_images = 0
    local cover_error = nil

    for index = 1, max_books do
        local book = books[index]
        local col = (index - 1) % 3
        local row = math.floor((index - 1) / 3)
        local x = margin + col * (card_w + gap)
        local y = top + row * (card_h + row_gap)
        local color = cover_color(book)
        local ok, err = self:draw_cover_image(local_cover_path(book), x, y, card_w, cover_h)
        if ok then
            cover_images = cover_images + 1
        else
            cover_error = cover_error or err
            self:rect(x, y, card_w, cover_h, color)
            self:rect(x + 8, y + 8, card_w - 16, cover_h - 16, WHITE)
            self:rect(x + 16, y + 18, card_w - 32, cover_h - 36, color)
        end
        self:rect(x, y + cover_h + 10, card_w, 1, GRAY)
    end

    self:rect(18, self.height - 34, self.width - 36, 1, GRAY)
    return {
        coverImages = cover_images,
        coverError = cover_error or "",
    }
end

function NativeRaster:write_ppm(path)
    local file, err = io.open(path, "wb")
    if not file then
        error("Could not write " .. tostring(path) .. ": " .. tostring(err))
    end
    file:write("P6\n", tostring(self.width), " ", tostring(self.height), "\n255\n")
    for y = 1, self.height do
        for x = 1, self.width do
            local c = self.pixels[y][x] or WHITE
            file:write(string.char(c[1], c[2], c[3]))
        end
    end
    file:close()
    return path
end

return NativeRaster
