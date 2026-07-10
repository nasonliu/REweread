local Json = require("json_util")

local DEFAULT_ROOT = "/home/root/.local/share/rm-weread"

local BookStatusStore = {}
BookStatusStore.__index = BookStatusStore

local function read_all(path)
    local file = io.open(path, "rb")
    if not file then return nil end
    local text = file:read("*a")
    file:close()
    return text
end

local function file_exists(path)
    if not path or path == "" then return false end
    local file = io.open(path, "rb")
    if not file then return false end
    local size = file:seek("end") or 0
    file:close()
    return size > 0
end

local function write_atomic(path, text)
    local tmp = path .. ".tmp." .. tostring(os.time()) .. "." .. tostring(math.random(1000000))
    local file, err = io.open(tmp, "wb")
    if not file then error("Could not write " .. tmp .. ": " .. tostring(err)) end
    local ok
    ok, err = file:write(text)
    if not ok then file:close(); os.remove(tmp); error("Could not write " .. tmp .. ": " .. tostring(err)) end
    ok, err = file:close()
    if not ok then os.remove(tmp); error("Could not close " .. tmp .. ": " .. tostring(err)) end
    ok, err = os.rename(tmp, path)
    if not ok then os.remove(tmp); error("Could not replace " .. path .. ": " .. tostring(err)) end
end

local function ensure_dir(path)
    os.execute("mkdir -p " .. string.format("%q", path))
end

function BookStatusStore:new(opts)
    opts = opts or {}
    return setmetatable({
        root = opts.root or DEFAULT_ROOT,
        statuses = nil,
    }, self)
end

function BookStatusStore:path()
    return self.root .. "/book-status.json"
end

function BookStatusStore:ensure()
    ensure_dir(self.root)
    ensure_dir(self.root .. "/books")
end

function BookStatusStore:load()
    if self.statuses then return self.statuses end
    local text = read_all(self:path())
    if not text or text == "" then
        self.statuses = {}
        return self.statuses
    end
    local ok, data = pcall(Json.decode, text)
    if ok and type(data) == "table" then
        self.statuses = data
    else
        self.statuses = {}
    end
    return self.statuses
end

function BookStatusStore:get(book_id)
    if not book_id or book_id == "" then return {} end
    local statuses = self:load()
    return statuses[tostring(book_id)] or {}
end

function BookStatusStore:update(book_id, patch)
    if not book_id or book_id == "" then return {} end
    self:ensure()
    local statuses = self:load()
    local current = statuses[tostring(book_id)] or {}
    for key, value in pairs(patch or {}) do
        current[key] = value
    end
    current.bookId = tostring(book_id)
    current.updatedAt = os.time()
    statuses[tostring(book_id)] = current
    write_atomic(self:path(), Json.encode(statuses))
    return current
end

function BookStatusStore:list_downloads()
    local statuses = self:load()
    local rows = {}
    for book_id, status in pairs(statuses or {}) do
        local state = tostring(status.downloadState or "")
        local has_file = (status.fullFile and status.fullFile ~= "") or (status.cachedFile and status.cachedFile ~= "")
        if state == "downloading" or state == "full" or state == "partial" or state == "failed" or state == "special" or has_file then
            local row = {}
            for key, value in pairs(status) do
                row[key] = value
            end
            row.bookId = tostring(book_id)
            row.title = row.title or tostring(book_id)
            local full_exists = file_exists(row.fullFile)
            local cached_exists = file_exists(row.cachedFile)
            if has_file and not full_exists and not cached_exists then
                row.staleFile = true
                row.downloadState = "missing"
                row.lastError = row.lastError or "本地文件已不存在"
            end
            table.insert(rows, row)
        end
    end
    table.sort(rows, function(a, b)
        return tonumber(a.updatedAt or 0) > tonumber(b.updatedAt or 0)
    end)
    return rows
end

function BookStatusStore:book_dir(book_id)
    local safe = tostring(book_id or "weread"):gsub("[^%w%._-]", "_")
    return self.root .. "/books/" .. safe
end

function BookStatusStore:review_path(book_id)
    return self:book_dir(book_id) .. "/reviews.json"
end

function BookStatusStore:load_reviews(book_id, review_filter)
    if not book_id or book_id == "" then return nil end
    local text = read_all(self:review_path(book_id))
    if not text or text == "" then return nil end
    local ok, data = pcall(Json.decode, text)
    if not ok or type(data) ~= "table" then return nil end
    if review_filter then
        if type(data[review_filter]) == "table" then
            return data[review_filter]
        end
        if data.type == review_filter then
            return data
        end
        return nil
    end
    return data.Recommended or data
end

function BookStatusStore:save_reviews(book_id, bundle)
    if not book_id or book_id == "" then return bundle end
    self:ensure()
    ensure_dir(self:book_dir(book_id))
    bundle = bundle or { type = "Recommended", reviews = {} }
    bundle.updatedAt = os.time()
    local text = read_all(self:review_path(book_id))
    local data = {}
    if text and text ~= "" then
        local ok, decoded = pcall(Json.decode, text)
        if ok and type(decoded) == "table" then
            data = decoded
        end
    end
    data[bundle.type or "Recommended"] = bundle
    data.updatedAt = os.time()
    write_atomic(self:review_path(book_id), Json.encode(data))
    self:update(book_id, {
        reviewState = "ready",
        reviewUpdatedAt = bundle.updatedAt,
    })
    return bundle
end

function BookStatusStore:mark_reviews_failed(book_id, err)
    if not book_id or book_id == "" then return end
    self:update(book_id, {
        reviewState = "failed",
        lastReviewError = tostring(err or "Reviews unavailable"),
    })
end

return BookStatusStore
