local Json = require("json_util")

local DEFAULT_ROOT = "/home/root/.local/share/rm-weread"

local ShelfCache = {}
ShelfCache.__index = ShelfCache

local function join_path(left, right)
    if left:sub(-1) == "/" then
        return left .. right
    end
    return left .. "/" .. right
end

local function shell_quote(value)
    return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function read_all(path)
    local file = io.open(path, "r")
    if not file then
        return nil
    end
    local text = file:read("*a")
    file:close()
    return text
end

local function write_all_atomic(path, text)
    local tmp_path = path .. ".tmp." .. tostring(os.time()) .. "." .. tostring(math.random(1000000))
    local file, err = io.open(tmp_path, "w")
    if not file then
        error("Could not write " .. tmp_path .. ": " .. tostring(err))
    end
    local ok
    ok, err = file:write(text)
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

local function safe_name(value)
    local name = tostring(value or ""):gsub("[^%w%._%-]", "_")
    if name == "" then
        name = "unknown"
    end
    return name
end

function ShelfCache:new(root)
    return setmetatable({
        root = root or DEFAULT_ROOT,
    }, self)
end

function ShelfCache:covers_dir()
    return join_path(self.root, "covers")
end

function ShelfCache:shelf_path()
    return join_path(self.root, "shelf.json")
end

function ShelfCache:ensure()
    os.execute("mkdir -p " .. shell_quote(self.root))
    os.execute("mkdir -p " .. shell_quote(self:covers_dir()))
end

function ShelfCache:load_shelf()
    local text = read_all(self:shelf_path())
    if not text or text == "" then
        return nil
    end
    local ok, data = pcall(function()
        return Json.decode(text)
    end)
    if not ok or type(data) ~= "table" then
        return nil
    end
    return data
end

function ShelfCache:save_shelf(books)
    self:ensure()
    write_all_atomic(self:shelf_path(), Json.encode({
        version = 1,
        savedAt = os.time(),
        books = books or {},
    }))
end

function ShelfCache:cover_path(book_id)
    return join_path(self:covers_dir(), safe_name(book_id) .. ".jpg")
end

return ShelfCache
