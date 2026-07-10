local DEFAULT_ROOT = "/home/root/.local/share/rm-weread/books"

local ChapterCache = {}
ChapterCache.__index = ChapterCache

local function join_path(left, right)
    if left:sub(-1) == "/" then
        return left .. right
    end
    return left .. "/" .. right
end

local function shell_quote(value)
    return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function safe_name(value)
    local name = tostring(value or ""):gsub("[^%w%._%-]", "_")
    if name == "" then
        name = "unknown"
    end
    return name
end

local function write_all_atomic(path, text)
    local tmp_path = path .. ".tmp." .. tostring(os.time()) .. "." .. tostring(math.random(1000000))
    local file, err = io.open(tmp_path, "w")
    if not file then
        error("Could not write " .. tmp_path .. ": " .. tostring(err))
    end
    local ok
    ok, err = file:write(text or "")
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

local function write_binary_atomic(path, data)
    local tmp_path = path .. ".tmp." .. tostring(os.time()) .. "." .. tostring(math.random(1000000))
    local file, err = io.open(tmp_path, "wb")
    if not file then
        error("Could not write " .. tmp_path .. ": " .. tostring(err))
    end
    local ok
    ok, err = file:write(data or "")
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

local function read_all(path)
    local file = io.open(path, "rb")
    if not file then
        return nil
    end
    local text = file:read("*a")
    file:close()
    return text
end

function ChapterCache:new(opts)
    opts = opts or {}
    return setmetatable({
        root = opts.root or DEFAULT_ROOT,
    }, self)
end

function ChapterCache:book_dir(book_id)
    return join_path(self.root, safe_name(book_id))
end

function ChapterCache:chapters_dir(book_id)
    return join_path(self:book_dir(book_id), "chapters")
end

function ChapterCache:images_dir(book_id)
    return join_path(self:book_dir(book_id), "images")
end

function ChapterCache:ensure(book_id)
    os.execute("mkdir -p " .. shell_quote(self:chapters_dir(book_id)))
    os.execute("mkdir -p " .. shell_quote(self:images_dir(book_id)))
end

function ChapterCache:chapter_path(book_id, chapter_uid)
    return join_path(self:chapters_dir(book_id), safe_name(chapter_uid) .. ".xhtml")
end

function ChapterCache:first_cached_chapter_path(book_id)
    local dir = self:chapters_dir(book_id)
    local handle = io.popen("find " .. shell_quote(dir) .. " -type f -name '*.xhtml' 2>/dev/null | sort | sed -n '1p'")
    if not handle then
        return nil
    end
    local path = handle:read("*l")
    handle:close()
    if path and path ~= "" then
        return path
    end
    return nil
end

function ChapterCache:read_chapter(path)
    return read_all(path)
end

function ChapterCache:write_chapter(book_id, chapter, xhtml)
    local chapter_uid = chapter and (chapter.chapterUid or chapter.chapter_uid or chapter.uid)
    chapter_uid = chapter_uid or "chapter"
    self:ensure(book_id)
    local path = self:chapter_path(book_id, chapter_uid)
    write_all_atomic(path, xhtml or "")
    return path
end

function ChapterCache:write_chapter_assets(book_id, assets)
    self:ensure(book_id)
    local count = 0
    for _, asset in ipairs(assets or {}) do
        local href = tostring(asset.href or "")
        local filename = href:match("([^/]+)$")
        if filename and filename ~= "" and asset.data then
            local path = join_path(self:images_dir(book_id), safe_name(filename))
            write_binary_atomic(path, asset.data)
            count = count + 1
        end
    end
    return count
end

return ChapterCache
