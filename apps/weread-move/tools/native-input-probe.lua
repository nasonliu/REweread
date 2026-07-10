io.stdout:setvbuf("line")

local app_dir = os.getenv("RM_WEREAD_APP_DIR") or "/home/root/xovi/exthome/appload/weread-move"
package.path = app_dir .. "/?.lua;" .. app_dir .. "/lib/?.lua;" .. app_dir .. "/tools/?.lua;" .. package.path

local NativeInput = require("native_input")

local devices = {
    arg and arg[1] or "/dev/input/touchscreen0",
    "/dev/input/event2",
}

for _, device in ipairs(devices) do
    local info = NativeInput.device_info(device)
    print("device=" .. tostring(info.device))
    print("name=" .. tostring(info.name))
    print("properties=" .. tostring(info.properties))
    print("ev=" .. tostring(info.ev))
    print("key=" .. tostring(info.key))
    print("abs=" .. tostring(info.abs))
end
