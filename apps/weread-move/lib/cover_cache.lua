local Client = require("lib.client")

local COVER_ACCEPT = "image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8"
local MIN_COVER_BYTES = 1

local CoverCache = {}
CoverCache.__index = CoverCache

local function cached_file_exists(path)
    local file = io.open(path, "rb")
    if not file then
        return false
    end
    local size = file:seek("end") or 0
    file:close()
    return size >= MIN_COVER_BYTES
end

local function write_binary_atomic(path, data)
    local tmp_path = path .. ".tmp." .. tostring(os.time()) .. "." .. tostring(math.random(1000000))
    local file, err = io.open(tmp_path, "wb")
    if not file then
        error("Could not write " .. tmp_path .. ": " .. tostring(err))
    end
    local ok
    ok, err = file:write(data)
    if not ok then
        file:close()
        os.remove(tmp_path)
        error("Could not write " .. tmp_path .. ": " .. tostring(err))
    end
    ok, err = file:close()
    if not ok then
        os.remove(tmp_path)
        error("Could not close " .. tmp_path .. ": " .. tostring(err))
    end
    ok, err = os.rename(tmp_path, path)
    if not ok then
        os.remove(tmp_path)
        error("Could not replace " .. path .. ": " .. tostring(err))
    end
end

local function allowed_cover_host(host)
    host = tostring(host or ""):lower()
    return host == "cdn.weread.qq.com"
        or host == "res.weread.qq.com"
        or host == "weread-1258476243.file.myqcloud.com"
        or host:match("%.file%.myqcloud%.com$") ~= nil
        or host:match("%.image%.myqcloud%.com$") ~= nil
        or host:match("%.qpic%.cn$") ~= nil
        or host:match("%.qq%.com$") ~= nil
end

local function validate_cover_url(url)
    local host = tostring(url or ""):match("^https?://([^/:?#]+)")
    if not host then
        return nil, "unsupported cover url"
    end
    if not allowed_cover_host(host) then
        return nil, "unsupported cover host"
    end
    return true
end

local function header_value(headers, name)
    if not headers then
        return nil
    end
    local target = name:lower()
    for key, value in pairs(headers) do
        if tostring(key):lower() == target then
            if type(value) == "table" then
                for _, item in pairs(value) do
                    return tostring(item)
                end
                return nil
            end
            return value
        end
    end
    return nil
end

local function absolute_url(base_url, location)
    if not location or location == "" then
        return nil
    end
    if location:match("^https?://") then
        return location
    end

    local scheme, host = base_url:match("^(https?)://([^/]+)")
    if not scheme then
        return nil
    end
    if location:sub(1, 2) == "//" then
        return scheme .. ":" .. location
    end
    if location:sub(1, 1) == "/" then
        return scheme .. "://" .. host .. location
    end

    local prefix = base_url:match("^(https?://.*/)") or (scheme .. "://" .. host .. "/")
    return prefix .. location
end

local function is_redirect(code)
    return code == 301 or code == 302 or code == 303 or code == 307 or code == 308
end

local function public_request_follow(client, url, max_redirects)
    local current_url = url
    max_redirects = max_redirects or 5

    for _ = 1, max_redirects + 1 do
        local ok, err = validate_cover_url(current_url)
        if not ok then
            error(err)
        end

        local data, code, resp_headers = client:request({
            url = current_url,
            method = "GET",
            headers = {
                ["Accept"] = COVER_ACCEPT,
                ["Referer"] = "https://weread.qq.com/",
            },
        })
        if is_redirect(code) then
            local next_url = absolute_url(current_url, header_value(resp_headers, "location"))
            if not next_url then
                error("cover redirect missing target")
            end
            ok, err = validate_cover_url(next_url)
            if not ok then
                error("unsupported cover redirect")
            end
            current_url = next_url
        else
            return data, code
        end
    end
    error("too many cover redirects")
end

local function public_fetch_binary(client, url)
    local data, code = public_request_follow(client, url, 5)
    if code and code >= 200 and code < 300 then
        return data, code
    end
    error("HTTP " .. tostring(code) .. ", body_bytes=" .. tostring(#(data or "")))
end

function CoverCache:new(settings, shelf_cache)
    return setmetatable({
        client = Client:new(settings),
        shelf_cache = shelf_cache,
    }, self)
end

function CoverCache:ensure_cover(book)
    if type(book) ~= "table" then
        return nil, "missing book"
    end
    if not book.cover or book.cover == "" then
        return nil, "missing cover url"
    end
    if not book.bookId or book.bookId == "" then
        return nil, "missing book id"
    end

    self.shelf_cache:ensure()
    local path = self.shelf_cache:cover_path(book.bookId)
    if cached_file_exists(path) then
        book.localCover = path
        return path
    end

    local data = public_fetch_binary(self.client, book.cover)
    if #(data or "") < MIN_COVER_BYTES then
        return nil, "empty cover response"
    end
    write_binary_atomic(path, data)
    book.localCover = path
    return path
end

function CoverCache:ensure_first_covers(books, limit)
    local count = 0
    local max_count = limit or 24
    for index, book in ipairs(books or {}) do
        if index > max_count then
            break
        end
        local ok, path = pcall(function()
            return self:ensure_cover(book)
        end)
        if ok and path then
            count = count + 1
        end
    end
    return count
end

return CoverCache
