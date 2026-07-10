io.stdout:setvbuf("line")
os.setlocale("C", "numeric")

local app_dir = os.getenv("RM_WEREAD_APP_DIR") or "/home/root/xovi/exthome/appload/weread-move"
local koreader_dir = os.getenv("KO_DIR") or "/home/root/xovi/exthome/appload/koreader"
package.path = app_dir .. "/?.lua;" .. app_dir .. "/lib/?.lua;" .. app_dir .. "/views/?.lua;" .. app_dir .. "/tools/?.lua;" .. package.path
package.path =
    app_dir .. "/../../third_party/weread.koplugin/?.lua;" ..
    app_dir .. "/../../third_party/weread.koplugin/lib/?.lua;" ..
    "/home/root/xovi/exthome/appload/koreader/plugins/weread.koplugin/?.lua;" ..
    "/home/root/xovi/exthome/appload/koreader/plugins/weread.koplugin/lib/?.lua;" ..
    package.path

local KoreaderPaths = require("koreader_paths")
KoreaderPaths.append(koreader_dir)

local ConfigBridge = require("config_bridge")
local Client = require("lib.client")
local Cookie = require("lib.cookie")
local Json = require("json_util")

local ok_socket, socket = pcall(require, "socket")
local login_log_path = os.getenv("RM_WEREAD_LOGIN_LOG") or ""
local debug_login = os.getenv("RM_WEREAD_LOGIN_DEBUG") == "1"

local function emit(row)
    print(Json.encode(row))
    if login_log_path == "" then
        return
    end
    local file = io.open(login_log_path, "a")
    if file then
        file:write(Json.encode(row))
        file:write("\n")
        file:close()
    end
end

local function debug_emit(row)
    if debug_login then
        emit(row)
    end
end

local function endpoint(path)
    return "https://weread.qq.com" .. path
end

local function urlencode(value)
    return tostring(value or ""):gsub("([^%w%-_%.~])", function(char)
        return string.format("%%%02X", string.byte(char))
    end)
end

local function request_id()
    math.randomseed(os.time() + math.floor(os.clock() * 1000000))
    return string.format(
        "rm-%08x%08x",
        math.random(0, 0x7fffffff),
        math.random(0, 0x7fffffff)
    )
end

local function response_data(response)
    if type(response) ~= "table" then
        return {}
    end
    if type(response.data) == "table" then
        return response.data
    end
    return response
end

local function has_text(value)
    return type(value) == "string" and value:match("%S") ~= nil
end

local function header_value(headers, name)
    if not headers then
        return nil
    end
    local target = name:lower()
    for key, value in pairs(headers) do
        if tostring(key):lower() == target then
            return value
        end
    end
    return nil
end

local function response_vid(response, client)
    local candidates = {
        response.webLoginVid,
        response.vid,
        response.userVid,
        response.user_vid,
        response.openid,
    }
    for _, value in ipairs(candidates) do
        if has_text(value) then
            return tostring(value)
        end
    end
    local cookies = client.settings:get("cookies", {})
    if has_text(cookies.wr_vid) then
        return tostring(cookies.wr_vid)
    end
    return ""
end

local function get_public_json(client, path, query, timeout)
    local parts = {}
    for key, value in pairs(query or {}) do
        if value ~= nil and tostring(value) ~= "" then
            parts[#parts + 1] = urlencode(key) .. "=" .. urlencode(value)
        end
    end
    table.sort(parts)
    local url = endpoint(path)
    if #parts > 0 then
        url = url .. "?" .. table.concat(parts, "&")
    end
    local text, code, headers = client:request({
        url = url,
        method = "GET",
        timeout = timeout,
        headers = {
            ["Accept"] = "application/json, text/plain, */*",
            ["Origin"] = "https://weread.qq.com",
            ["Referer"] = "https://weread.qq.com/",
            ["X-SSR-Request-Id"] = request_id(),
        }
    })
    local set_cookie = header_value(headers, "set-cookie")
    if set_cookie then
        local cookies = client.settings:get("cookies", {})
        client.settings:set("cookies", Cookie.merge_set_cookie(cookies, set_cookie))
        client.settings:flush()
    end
    if code and code >= 200 and code < 300 then
        return client:json_decode(text or ""), code, headers
    end
    error("HTTP " .. tostring(code or "nil") .. " from " .. path)
end

local function sleep_seconds(seconds)
    if ok_socket and socket.sleep then
        socket.sleep(seconds)
    else
        os.execute("sleep " .. tostring(seconds))
    end
end

local function make_fingerprint(uid)
    math.randomseed(os.time() + math.floor(os.clock() * 1000000))
    local base = tostring(uid or ""):gsub("[^%w]", "")
    local suffix = {}
    for _ = 1, 16 do
        suffix[#suffix + 1] = string.format("%x", math.random(0, 15))
    end
    return "rmweread" .. base:sub(1, 16) .. table.concat(suffix)
end

local function request_uid(client)
    local response = response_data(get_public_json(client, "/api/auth/getLoginUid", {}, 20))
    if not has_text(response.uid) then
        error("login uid missing")
    end
    return response.uid
end

local function poll_login_info(client, uid, timeout_seconds)
    local deadline = os.time() + timeout_seconds
    while os.time() <= deadline do
        emit({ state = "waiting", stage = "phone", message = "waiting for phone confirmation" })
        local response = response_data(get_public_json(client, "/api/auth/getLoginInfo", { uid = uid, otp = "" }, 70))
        local vid = response_vid(response, client)
        debug_emit({
            state = "debug",
            step = "getLoginInfo",
            succeed = response.succeed == true,
            logic_code = tostring(response.logicCode or ""),
            has_web_login_vid = has_text(response.webLoginVid),
            has_vid = has_text(response.vid),
            has_user_vid = has_text(response.userVid),
            has_cookie_vid = has_text(client.settings:get("cookies", {}).wr_vid),
            has_access_token = has_text(response.accessToken),
        })
        if response.succeed == true and has_text(vid) and has_text(response.accessToken) then
            response.resolvedVid = vid
            return response
        end
        local logic_code = tostring(response.logicCode or "")
        if logic_code == "NEED_OTP" then
            error("login requires phone OTP verification, which is not yet supported on Move")
        elseif logic_code == "OTP_EXPIRED" or logic_code == "OTP_NOT_MATCH" then
            error("login OTP verification failed: " .. logic_code)
        elseif logic_code ~= "" and logic_code ~= "LOGIN_TIMEOUT" then
            error("login confirmation failed: " .. logic_code)
        end
        sleep_seconds(1)
    end
    error("login timed out")
end

local function initialize_session(client, login_result)
    local cookies = client.settings:get("cookies", {})
    cookies.wr_vid = tostring(login_result.resolvedVid or login_result.webLoginVid or login_result.vid or login_result.userVid)
    cookies.wr_skey = tostring(login_result.accessToken)
    client.settings:set("logged_out", false)
    client.settings:set("cookies", cookies)
    client.settings:set("wr_ticket", "")
    client.settings:set("wr_wrpa", "")
    local ok_renew = pcall(function()
        client:renew_cookie()
    end)
    if not ok_renew then
        client.settings:flush()
    end
end

local ok, result = pcall(function()
    local config = ConfigBridge:new()
    local client = Client:new(config)
    local timeout_seconds = tonumber(os.getenv("RM_WEREAD_LOGIN_TIMEOUT") or "120") or 120

    local uid = request_uid(client)
    local confirm_url = "https://weread.qq.com/web/confirm?uid=" .. uid
    emit({ state = "qr", uid = uid, confirm_url = confirm_url })
    if os.getenv("RM_WEREAD_LOGIN_ONCE") == "1" then
        return { state = "waiting", message = "login not completed" }
    end

    local login_result = poll_login_info(client, uid, timeout_seconds)
    emit({ state = "waiting", stage = "session", message = "confirmed" })

    initialize_session(client, login_result)
    config:flush()

    local status = config:redacted_status()
    status.state = "done"
    status.cookie_valid = config:is_cookie_configured()
    return status
end)

if ok then
    emit(result)
else
    emit({ state = "error", message = tostring(result or "unknown") })
    os.exit(1)
end
