local Blitbuffer = require("ffi/blitbuffer")
local Device = require("device")
local Font = require("ui/font")
local Geom = require("ui/geometry")
local ImageWidget = require("ui/widget/imagewidget")
local TextWidget = require("ui/widget/textwidget")

local DEFAULT_ROOT = "/home/root/.local/share/rm-weread"

local ViewHelpers = {}

ViewHelpers.palette = {
    background = Blitbuffer.COLOR_WHITE,
    text = Blitbuffer.COLOR_BLACK,
    muted = Blitbuffer.COLOR_BLACK,
    border = Blitbuffer.COLOR_GRAY,
    panel = Blitbuffer.COLOR_GRAY_E or Blitbuffer.COLOR_LIGHT_GRAY,
    light = Blitbuffer.COLOR_LIGHT_GRAY,
}

function ViewHelpers.screen_size()
    local screen = Device.screen
    return Geom:new{
        x = 0,
        y = 0,
        w = screen:getWidth(),
        h = screen:getHeight(),
    }
end

function ViewHelpers.text_font(size, bold)
    return Font:getFace("cfont", size or 18), bold == true
end

function ViewHelpers.safe_text(value, fallback)
    value = tostring(value or "")
    if value == "" then return fallback or "" end
    return value
end

function ViewHelpers.truncate(value, max_len)
    value = ViewHelpers.safe_text(value, "")
    max_len = max_len or 24
    local chars = {}
    local count = 0
    local byte_count = 0
    for char in value:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        if count >= max_len then break end
        table.insert(chars, char)
        count = count + 1
        byte_count = byte_count + #char
    end
    if byte_count >= #value then
        return value
    end
    return table.concat(chars)
end

function ViewHelpers.wrap_text(value, max_chars, max_lines)
    value = ViewHelpers.safe_text(value, "")
    max_chars = max_chars or 28
    max_lines = max_lines or 2
    local lines = {}
    local current = {}
    local count = 0
    for char in value:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        if char == "\n" or count >= max_chars then
            table.insert(lines, table.concat(current))
            current = {}
            count = 0
            if #lines >= max_lines then break end
            if char ~= "\n" then
                table.insert(current, char)
                count = 1
            end
        else
            table.insert(current, char)
            count = count + 1
        end
    end
    if #lines < max_lines and #current > 0 then
        table.insert(lines, table.concat(current))
    end
    if #lines == 0 then
        table.insert(lines, "")
    end
    return lines
end

function ViewHelpers.draw_text(bb, x, y, text, size, bold, color, max_width)
    local face, adjusted_bold = ViewHelpers.text_font(size, bold)
    local widget = TextWidget:new{
        text = ViewHelpers.safe_text(text, ""),
        face = face,
        bold = adjusted_bold,
        fgcolor = color or ViewHelpers.palette.text,
        max_width = max_width,
    }
    widget:paintTo(bb, x, y)
    return widget:getSize()
end

function ViewHelpers.draw_centered_text(bb, x, y, w, h, text, size, bold, color, max_width)
    local face, adjusted_bold = ViewHelpers.text_font(size, bold)
    local widget = TextWidget:new{
        text = ViewHelpers.safe_text(text, ""),
        face = face,
        bold = adjusted_bold,
        fgcolor = color or ViewHelpers.palette.text,
        max_width = max_width or w,
    }
    local text_size = widget:getSize()
    local text_w = text_size and text_size.w or 0
    local text_h = text_size and text_size.h or (size or 16)
    local draw_x = x + math.max(0, math.floor((w - text_w) / 2))
    local draw_y = y + math.max(0, math.floor((h - text_h) / 2))
    widget:paintTo(bb, draw_x, draw_y)
    return text_size
end

local function control_variant(variant, opts)
    opts = opts or {}
    variant = variant or "secondary"
    local disabled = opts.disabled == true
    if disabled then
        return {
            border = ViewHelpers.palette.light,
            fill = ViewHelpers.palette.background,
            fg = ViewHelpers.palette.muted,
            shadow = false,
            bold = false,
        }
    end
    if variant == "primary" then
        return {
            border = ViewHelpers.palette.text,
            fill = ViewHelpers.palette.text,
            fg = ViewHelpers.palette.background,
            shadow = true,
            bold = true,
        }
    end
    if variant == "ghost" then
        return {
            border = ViewHelpers.palette.light,
            fill = ViewHelpers.palette.background,
            fg = ViewHelpers.palette.text,
            shadow = false,
            bold = opts.bold == true,
        }
    end
    if variant == "danger" then
        return {
            border = ViewHelpers.palette.border,
            fill = ViewHelpers.palette.panel,
            fg = ViewHelpers.palette.text,
            shadow = false,
            bold = false,
        }
    end
    return {
        border = ViewHelpers.palette.border,
        fill = ViewHelpers.palette.panel,
        fg = ViewHelpers.palette.text,
        shadow = true,
        bold = opts.bold ~= false,
    }
end

function ViewHelpers.draw_button(bb, x, y, w, h, label, variant, opts)
    opts = opts or {}
    local style = control_variant(variant, opts)
    local shadow = opts.shadow
    if shadow == nil then shadow = style.shadow end
    if shadow then
        bb:paintRect(x + 3, y + 4, w, h, ViewHelpers.palette.light)
    end
    bb:paintRect(x, y, w, h, style.border)
    bb:paintRect(x + 2, y + 2, w - 4, h - 4, style.fill)
    if opts.inner_line ~= false and h >= 34 and variant ~= "primary" then
        bb:paintRect(x + 4, y + h - 5, w - 8, 1, ViewHelpers.palette.light)
    end
    return ViewHelpers.draw_centered_text(
        bb,
        x + 4,
        y + 2,
        w - 8,
        h - 4,
        label,
        opts.size or 15,
        style.bold,
        style.fg,
        w - 18
    )
end

function ViewHelpers.draw_input_box(bb, x, y, w, h, value, placeholder, opts)
    opts = opts or {}
    local text = ViewHelpers.safe_text(value, "")
    local empty = text == ""
    if empty then
        text = ViewHelpers.safe_text(placeholder, "")
    end
    bb:paintRect(x, y, w, h, opts.border or ViewHelpers.palette.border)
    bb:paintRect(x + 2, y + 2, w - 4, h - 4, opts.fill or ViewHelpers.palette.background)
    bb:paintRect(x + 8, y + h - 5, w - 16, 1, ViewHelpers.palette.light)
    return ViewHelpers.draw_centered_text(
        bb,
        x + 10,
        y + 2,
        w - 20,
        h - 4,
        text,
        opts.size or 16,
        opts.bold == true,
        empty and (opts.placeholder_color or ViewHelpers.palette.muted) or (opts.color or ViewHelpers.palette.text),
        w - 28
    )
end

function ViewHelpers.draw_wrapped_text(bb, x, y, text, size, bold, color, max_width, max_chars, max_lines, line_height)
    local lines = ViewHelpers.wrap_text(text, max_chars, max_lines)
    line_height = line_height or math.floor((size or 16) * 1.55)
    for index, line in ipairs(lines) do
        ViewHelpers.draw_text(bb, x, y + (index - 1) * line_height, line, size, bold, color, max_width)
    end
    return #lines * line_height
end

function ViewHelpers.file_exists(path)
    if not path or path == "" then return false end
    local file = io.open(path, "rb")
    if not file then return false end
    local size = file:seek("end") or 0
    file:close()
    return size > 0
end

local function safe_name(value)
    local name = tostring(value or ""):gsub("[^%w%._%-]", "_")
    if name == "" then name = "unknown" end
    return name
end

function ViewHelpers.local_cover_path(book, root)
    if book and ViewHelpers.file_exists(book.localCover) then
        return book.localCover
    end
    local book_id = book and (book.bookId or book.book_id)
    if not book_id then return nil end
    return (root or DEFAULT_ROOT) .. "/covers/" .. safe_name(book_id) .. ".jpg"
end

function ViewHelpers.draw_image(bb, path, x, y, w, h)
    if not ViewHelpers.file_exists(path) then return false end
    local ok = pcall(function()
        local image = ImageWidget:new{
            file = path,
            width = w,
            height = h,
            scale_factor = 0,
            file_do_cache = true,
        }
        image:paintTo(bb, x, y)
    end)
    return ok
end

function ViewHelpers.cover_tone(book)
    local seed = 0
    local text = tostring(book and (book.bookId or book.title) or "weread")
    for i = 1, #text do seed = (seed + text:byte(i) * i) % 5 end
    local tones = {
        ViewHelpers.palette.text,
        ViewHelpers.palette.muted,
        ViewHelpers.palette.border,
        ViewHelpers.palette.light,
        ViewHelpers.palette.panel,
    }
    return tones[seed + 1] or ViewHelpers.palette.border
end

function ViewHelpers.rect(x, y, w, h)
    return Geom:new{ x = x, y = y, w = w, h = h }
end

return ViewHelpers
