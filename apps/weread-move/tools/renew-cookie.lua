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
local Json = require("json_util")

local function emit(row)
    print(Json.encode(row))
end

local function missing_login_message()
    return "微信读书登录 Cookie 未配置。请在微信读书 App 的账号页使用扫码登录，或点续期 Cookie 后再重试。"
end

local ok, result = pcall(function()
    local config = ConfigBridge:new()
    if not config:is_cookie_configured() then
        error(missing_login_message())
    end

    local client = Client:new(config)
    client:renew_cookie()
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
