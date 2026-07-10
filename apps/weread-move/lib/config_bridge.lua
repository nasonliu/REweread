local Cookie = require("lib.cookie")
local Json = require("json_util")

local DEFAULT_CONFIG_PATH = "/home/root/xovi/exthome/appload/koreader/plugins/weread.koplugin/config.lua"
local DEFAULT_SESSION_PATH = "/home/root/.local/share/rm-weread/session.json"

local ConfigBridge = {}
ConfigBridge.__index = ConfigBridge

local defaults = {
    api_key = "",
    cookies = {},
    wr_ticket = "",
    wr_wrpa = "",
    curl_payload = {},
    shelf = {
        sort_order = "time_desc",
    },
}

local function deepcopy(value)
    if type(value) ~= "table" then
        return value
    end
    local out = {}
    for key, item in pairs(value) do
        out[key] = deepcopy(item)
    end
    return out
end

local function has_text(value)
    return type(value) == "string" and value:match("%S") ~= nil
end

local function merge_cookie_tables(current, updates)
    current = current or {}
    for key, value in pairs(updates or {}) do
        current[key] = value
    end
    return current
end

local function shell_quote(value)
    return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function ensure_parent_dir(path)
    local parent = tostring(path or ""):match("^(.*)/[^/]+$")
    if parent and parent ~= "" then
        os.execute("mkdir -p " .. shell_quote(parent))
    end
end

local function load_config(path)
    local file = io.open(path, "r")
    if not file then
        return {}, nil
    end
    file:close()

    local chunk = loadfile(path)
    if not chunk then
        return {}, "config.lua could not be loaded"
    end
    local ok, config = pcall(chunk)
    if not ok then
        return {}, "config.lua could not be evaluated"
    end
    if type(config) ~= "table" then
        return {}, "config.lua must return a table"
    end
    return config, nil
end

local function load_session(path)
    local file = io.open(path, "r")
    if not file then
        return {}
    end
    local text = file:read("*a")
    file:close()
    local ok, session = pcall(Json.decode, text or "")
    if ok and type(session) == "table" then
        return session
    end
    return {}
end

local function save_session(path, values)
    ensure_parent_dir(path)
    local session = {
        cookies = type(values.cookies) == "table" and values.cookies or {},
        wr_ticket = has_text(values.wr_ticket) and values.wr_ticket or "",
        wr_wrpa = has_text(values.wr_wrpa) and values.wr_wrpa or "",
        logged_out = values.logged_out == true,
        updated_at = os.time(),
    }
    local file = assert(io.open(path, "w"))
    file:write(Json.encode(session))
    file:write("\n")
    file:close()
    os.execute("chmod 600 " .. shell_quote(path))
end

local function cookies_from_config(config)
    local imported = {}
    local raw_cookie = ""

    if has_text(config.curl) then
        raw_cookie = Cookie.extract_from_curl(config.curl)
    elseif has_text(config.cookie) then
        raw_cookie = config.cookie
    end

    if has_text(raw_cookie) then
        local cookies = Cookie.parse_cookie_header(raw_cookie)
        if Cookie.has_login_cookie(cookies) then
            imported = merge_cookie_tables(imported, cookies)
        end
    end

    if has_text(config.mp_curl) then
        local mp_cookie = Cookie.extract_from_curl(config.mp_curl)
        if has_text(mp_cookie) then
            local cookies = Cookie.parse_cookie_header(mp_cookie)
            if Cookie.has_login_cookie(cookies) then
                imported = merge_cookie_tables(imported, cookies)
            end
        end
    end

    return imported
end

function ConfigBridge:new(opts)
    opts = opts or {}
    local obj = {
        config_path = opts.config_path or DEFAULT_CONFIG_PATH,
        session_path = opts.session_path or os.getenv("RM_WEREAD_SESSION_PATH") or DEFAULT_SESSION_PATH,
        values = {},
    }
    setmetatable(obj, self)
    obj:reload()
    return obj
end

function ConfigBridge:reload()
    self.config, self.load_error = load_config(self.config_path)
    self.session = load_session(self.session_path)
    local session = self.session
    self.values = {}
    self.values.api_key = has_text(self.config.api_key) and self.config.api_key or ""
    self.values.logged_out = session.logged_out == true
    self.values.cookies = {}
    self.values.wr_ticket = ""
    self.values.wr_wrpa = ""
    if not self.values.logged_out then
        self.values.cookies = cookies_from_config(self.config)
        self.values.wr_ticket = has_text(self.config.wr_ticket) and self.config.wr_ticket or ""
        self.values.wr_wrpa = has_text(self.config.wr_wrpa) and self.config.wr_wrpa or ""
        if type(session.cookies) == "table" then
            merge_cookie_tables(self.values.cookies, session.cookies)
        end
        if has_text(session.wr_ticket) then
            self.values.wr_ticket = session.wr_ticket
        end
        if has_text(session.wr_wrpa) then
            self.values.wr_wrpa = session.wr_wrpa
        end
    end
    self.values.shelf = type(self.config.shelf) == "table" and deepcopy(self.config.shelf) or deepcopy(defaults.shelf)
    return self
end

function ConfigBridge:get(key, default)
    if default == nil then
        default = defaults[key]
    end
    local value = self.values[key]
    if value == nil then
        return deepcopy(default)
    end
    return deepcopy(value)
end

function ConfigBridge:set(key, value)
    self.values[key] = value
end

function ConfigBridge:flush()
    save_session(self.session_path, self.values)
end

function ConfigBridge:is_api_configured()
    return has_text(self.values.api_key)
end

function ConfigBridge:is_cookie_configured()
    return Cookie.has_login_cookie(self.values.cookies)
end

function ConfigBridge:redacted_status()
    return {
        config_path = self.config_path,
        session_path = self.session_path,
        api_key = self:is_api_configured() and "configured" or "missing",
        cookies = self:is_cookie_configured() and "configured" or "missing",
        logged_out = self.values.logged_out == true,
    }
end

return ConfigBridge
