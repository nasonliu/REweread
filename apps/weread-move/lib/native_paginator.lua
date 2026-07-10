local NativeFont = require("native_font")

local NativePaginator = {}

local function new_page()
    return {
        items = {},
        used_px = 0,
    }
end

local function add_item(page, item)
    table.insert(page.items, item)
end

function NativePaginator.paginate(document, opts)
    opts = opts or {}
    local page_width = tonumber(opts.page_width or 360) or 360
    local page_height = tonumber(opts.page_height or 540) or 540
    local margin = tonumber(opts.margin or 22) or 22
    local top = tonumber(opts.top or 34) or 34
    local bottom = tonumber(opts.bottom or 34) or 34
    local body_line_height = tonumber(opts.body_line_height or 24) or 24
    local heading_line_height = tonumber(opts.heading_line_height or 26) or 26
    local paragraph_gap = tonumber(opts.paragraph_gap or 10) or 10
    local image_height = tonumber(opts.image_height or 84) or 84
    local max_y = page_height - bottom
    local max_text_width = page_width - margin * 2

    local font = assert(NativeFont:new{ size = opts.font_size or 18 })
    local heading_font = assert(NativeFont:new{ size = opts.heading_size or 22 })

    local pages = {}
    local page = new_page()
    local y = top

    local function flush()
        if #page.items > 0 then
            page.used_px = y - top
            table.insert(pages, page)
        end
        page = new_page()
        y = top
    end

    local function ensure_space(height)
        if #page.items > 0 and y + height > max_y then
            flush()
        end
    end

    local function add_text_block(kind, lines, line_height)
        local item = nil
        for _, line in ipairs(lines) do
            ensure_space(line_height)
            if not item or y == top then
                item = {
                    type = kind,
                    lines = {},
                }
                add_item(page, item)
            end
            table.insert(item.lines, line)
            y = y + line_height
        end
        y = y + paragraph_gap
    end

    for _, block in ipairs((document and document.blocks) or {}) do
        if block.type == "image" then
            ensure_space(image_height)
            add_item(page, {
                type = "image",
                src = block.src,
                alt = block.alt,
                lines = {},
            })
            y = y + image_height
        elseif block.type == "heading" then
            local lines = heading_font:wrap_text(block.text or "", max_text_width)
            add_text_block("heading", lines, heading_line_height)
        else
            local lines = font:wrap_text(block.text or "", max_text_width)
            add_text_block("paragraph", lines, body_line_height)
        end
    end

    flush()
    if #pages == 0 then
        table.insert(pages, new_page())
    end
    return pages
end

return NativePaginator
