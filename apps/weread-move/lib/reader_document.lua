local ReaderDocument = {}

local function html_unescape(text)
    text = tostring(text or "")
    local entities = {
        amp = "&",
        lt = "<",
        gt = ">",
        quot = '"',
        apos = "'",
        nbsp = " ",
    }
    text = text:gsub("&#(%d+);", function(code)
        code = tonumber(code)
        if not code then return "" end
        if code < 128 then return string.char(code) end
        return ""
    end)
    text = text:gsub("&([%a]+);", function(name)
        return entities[name] or ""
    end)
    return text
end

local function normalize_space(text)
    text = tostring(text or "")
    text = text:gsub("\r", "\n")
    text = text:gsub("%s+", " ")
    text = text:gsub("^%s+", "")
    text = text:gsub("%s+$", "")
    return text
end

local function strip_tags(html)
    html = tostring(html or "")
    html = html:gsub("<br%s*/?>", "\n")
    html = html:gsub("<[^>]+>", "")
    return normalize_space(html_unescape(html))
end

local function tag_attr(tag, name)
    local value = tag:match(name .. '%s*=%s*"([^"]+)"')
        or tag:match(name .. "%s*=%s*'([^']+)'")
        or tag:match(name .. "%s*=%s*([^%s/>]+)")
    return html_unescape(value or "")
end

local function append_images(blocks, html)
    for tag in tostring(html or ""):gmatch("<img[^>]->") do
        local src = tag_attr(tag, "src")
        if src ~= "" then
            table.insert(blocks, {
                type = "image",
                src = src,
                alt = tag_attr(tag, "alt"),
            })
        end
    end
end

local function append_text_block(blocks, kind, html)
    append_images(blocks, html)
    local text = strip_tags(html)
    if text ~= "" then
        table.insert(blocks, {
            type = kind,
            text = text,
        })
    end
end

local function next_match(xhtml, pos)
    local best
    local function consider(kind, start_pos, end_pos, body, level)
        if start_pos and (not best or start_pos < best.start_pos) then
            best = {
                kind = kind,
                start_pos = start_pos,
                end_pos = end_pos,
                body = body,
                level = level,
            }
        end
    end

    local hs, he, level, hbody = xhtml:find("<h([1-6])[^>]*>(.-)</h%1>", pos)
    consider("heading", hs, he, hbody, tonumber(level))
    local ps, pe, pbody = xhtml:find("<p[^>]*>(.-)</p>", pos)
    consider("paragraph", ps, pe, pbody)
    local ds, de, dbody = xhtml:find("<div[^>]*>(.-)</div>", pos)
    consider("paragraph", ds, de, dbody)
    local is, ie, itag = xhtml:find("(<img[^>]->)", pos)
    consider("image_tag", is, ie, itag)
    return best
end

local function utf8_chars(text)
    local chars = {}
    for char in tostring(text or ""):gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        table.insert(chars, char)
    end
    return chars
end

local function wrap_text(text, max_chars)
    max_chars = math.max(1, tonumber(max_chars or 24) or 24)
    local lines = {}
    local current = {}
    local count = 0

    local function flush()
        if #current > 0 then
            table.insert(lines, table.concat(current))
            current = {}
            count = 0
        end
    end

    local function append_token(token, token_len)
        token_len = token_len or 1
        if token == " " and count == 0 then
            return
        end
        if count > 0 and count + token_len > max_chars then
            flush()
        end
        if token_len > max_chars then
            for _, char in ipairs(utf8_chars(token)) do
                append_token(char, 1)
            end
        else
            table.insert(current, token)
            count = count + token_len
        end
    end

    local chars = utf8_chars(text)
    local i = 1
    while i <= #chars do
        local char = chars[i]
        if char == "\n" then
            flush()
            i = i + 1
        elseif char:match("[%w%p]") then
            local latin_word = {}
            while i <= #chars and chars[i]:match("[%w%p]") do
                table.insert(latin_word, chars[i])
                i = i + 1
            end
            append_token(table.concat(latin_word), #latin_word)
        elseif char:match("%s") then
            append_token(" ", 1)
            i = i + 1
        else
            append_token(char, 1)
            i = i + 1
        end
    end

    if #current > 0 then
        table.insert(lines, table.concat(current))
    end
    if #lines == 0 then
        table.insert(lines, "")
    end
    return lines
end

function ReaderDocument.from_xhtml(xhtml)
    local blocks = {}
    local pos = 1
    xhtml = tostring(xhtml or "")
    while pos <= #xhtml do
        local match = next_match(xhtml, pos)
        if not match then break end
        if match.kind == "heading" then
            append_text_block(blocks, "heading", match.body)
        elseif match.kind == "image_tag" then
            append_images(blocks, match.body)
        else
            append_text_block(blocks, "paragraph", match.body)
        end
        pos = match.end_pos + 1
    end
    return {
        blocks = blocks,
    }
end

local function block_lines(block, opts)
    if block.type == "image" then
        return {
            type = "image",
            src = block.src,
            alt = block.alt,
            line_count = opts.image_lines,
        }
    end
    local max_chars = block.type == "heading" and opts.heading_chars or opts.chars_per_line
    local lines = wrap_text(block.text, max_chars)
    return {
        type = block.type,
        text = block.text,
        lines = lines,
        line_count = #lines + (block.type == "heading" and 1 or 0),
    }
end

function ReaderDocument.paginate(document, opts)
    opts = opts or {}
    opts.chars_per_line = opts.chars_per_line or 24
    opts.heading_chars = opts.heading_chars or 18
    opts.lines_per_page = opts.lines_per_page or 20
    opts.image_lines = opts.image_lines or 8

    local pages = {}
    local current = { items = {}, used_lines = 0 }
    local function flush()
        if #current.items == 0 then return end
        table.insert(pages, current)
        current = { items = {}, used_lines = 0 }
    end

    for _, block in ipairs((document and document.blocks) or {}) do
        local item = block_lines(block, opts)
        if current.used_lines > 0 and current.used_lines + item.line_count > opts.lines_per_page then
            flush()
        end
        table.insert(current.items, item)
        current.used_lines = current.used_lines + item.line_count
    end
    flush()
    if #pages == 0 then
        table.insert(pages, { items = {}, used_lines = 0 })
    end
    return pages
end

return ReaderDocument
