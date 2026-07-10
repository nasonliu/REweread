local ok_json, json = pcall(require, "json")
if not ok_json then
    ok_json, json = pcall(require, "rapidjson")
end

local Json = {}

local function utf8_char(code)
    if code < 0x80 then
        return string.char(code)
    elseif code < 0x800 then
        return string.char(
            0xC0 + math.floor(code / 0x40),
            0x80 + (code % 0x40)
        )
    elseif code < 0x10000 then
        return string.char(
            0xE0 + math.floor(code / 0x1000),
            0x80 + (math.floor(code / 0x40) % 0x40),
            0x80 + (code % 0x40)
        )
    end
    return "?"
end

local function decode_without_module(text)
    text = tostring(text or "")
    local index = 1

    local function error_at(message)
        error(message .. " at byte " .. tostring(index))
    end

    local function skip_ws()
        while true do
            local char = text:sub(index, index)
            if char == " " or char == "\n" or char == "\r" or char == "\t" then
                index = index + 1
            else
                break
            end
        end
    end

    local parse_value

    local function parse_string()
        if text:sub(index, index) ~= '"' then
            error_at("expected string")
        end
        index = index + 1
        local out = {}
        while index <= #text do
            local char = text:sub(index, index)
            if char == '"' then
                index = index + 1
                return table.concat(out)
            elseif char == "\\" then
                local esc = text:sub(index + 1, index + 1)
                if esc == '"' or esc == "\\" or esc == "/" then
                    table.insert(out, esc)
                    index = index + 2
                elseif esc == "b" then
                    table.insert(out, "\b")
                    index = index + 2
                elseif esc == "f" then
                    table.insert(out, "\f")
                    index = index + 2
                elseif esc == "n" then
                    table.insert(out, "\n")
                    index = index + 2
                elseif esc == "r" then
                    table.insert(out, "\r")
                    index = index + 2
                elseif esc == "t" then
                    table.insert(out, "\t")
                    index = index + 2
                elseif esc == "u" then
                    -- unicode escape fallback handles BMP escapes used by JSON encoders.
                    local hex = text:sub(index + 2, index + 5)
                    local code = tonumber(hex, 16)
                    if not code then
                        error_at("invalid unicode escape")
                    end
                    table.insert(out, utf8_char(code))
                    index = index + 6
                else
                    error_at("invalid escape")
                end
            else
                table.insert(out, char)
                index = index + 1
            end
        end
        error_at("unterminated string")
    end

    local function parse_number()
        local start = index
        local char = text:sub(index, index)
        if char == "-" then
            index = index + 1
        end
        while text:sub(index, index):match("%d") do
            index = index + 1
        end
        if text:sub(index, index) == "." then
            index = index + 1
            while text:sub(index, index):match("%d") do
                index = index + 1
            end
        end
        char = text:sub(index, index)
        if char == "e" or char == "E" then
            index = index + 1
            char = text:sub(index, index)
            if char == "+" or char == "-" then
                index = index + 1
            end
            while text:sub(index, index):match("%d") do
                index = index + 1
            end
        end
        local value = tonumber(text:sub(start, index - 1))
        if value == nil then
            error_at("invalid number")
        end
        return value
    end

    local function parse_array()
        index = index + 1
        local out = {}
        skip_ws()
        if text:sub(index, index) == "]" then
            index = index + 1
            return out
        end
        while true do
            table.insert(out, parse_value())
            skip_ws()
            local char = text:sub(index, index)
            if char == "]" then
                index = index + 1
                return out
            elseif char ~= "," then
                error_at("expected array comma")
            end
            index = index + 1
        end
    end

    local function parse_object()
        index = index + 1
        local out = {}
        skip_ws()
        if text:sub(index, index) == "}" then
            index = index + 1
            return out
        end
        while true do
            skip_ws()
            local key = parse_string()
            skip_ws()
            if text:sub(index, index) ~= ":" then
                error_at("expected object colon")
            end
            index = index + 1
            out[key] = parse_value()
            skip_ws()
            local char = text:sub(index, index)
            if char == "}" then
                index = index + 1
                return out
            elseif char ~= "," then
                error_at("expected object comma")
            end
            index = index + 1
        end
    end

    function parse_value()
        skip_ws()
        local char = text:sub(index, index)
        if char == '"' then
            return parse_string()
        elseif char == "{" then
            return parse_object()
        elseif char == "[" then
            return parse_array()
        elseif char == "-" or char:match("%d") then
            return parse_number()
        elseif text:sub(index, index + 3) == "true" then
            index = index + 4
            return true
        elseif text:sub(index, index + 4) == "false" then
            index = index + 5
            return false
        elseif text:sub(index, index + 3) == "null" then
            index = index + 4
            return nil
        end
        error_at("unexpected value")
    end

    local value = parse_value()
    skip_ws()
    if index <= #text then
        error_at("trailing data")
    end
    return value
end

function Json.encode(value)
    if not ok_json then
        error("JSON module is not available")
    end
    if json.encode then
        return json.encode(value)
    end
    return json:encode(value)
end

function Json.decode(text)
    if ok_json and json.decode then
        return json.decode(text)
    end
    if ok_json then
        return json:decode(text)
    end
    return decode_without_module(text)
end

return Json
