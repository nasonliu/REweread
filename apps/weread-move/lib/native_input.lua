local ffi = require("ffi")
local bit = require("bit")

ffi.cdef[[
struct input_event {
  long tv_sec;
  long tv_usec;
  unsigned short type;
  unsigned short code;
  int value;
};
struct pollfd {
  int fd;
  short events;
  short revents;
};
int open(const char *, int, ...);
int close(int);
long read(int, void *, size_t);
int poll(struct pollfd *, unsigned long, int);
char *strerror(int);
]]

local C = ffi.C
local O_RDONLY = 0
local O_NONBLOCK = 2048
local O_CLOEXEC = 524288
local POLLIN = 1

local NativeInput = {
    EV_SYN = 0,
    EV_KEY = 1,
    EV_ABS = 3,
    SYN_REPORT = 0,
    BTN_TOUCH = 330,
    ABS_X = 0,
    ABS_Y = 1,
    ABS_PRESSURE = 24,
    ABS_MT_POSITION_X = 53,
    ABS_MT_POSITION_Y = 54,
    ABS_MT_PRESSURE = 58,
}
NativeInput.__index = NativeInput

local EVENT_SIZE = ffi.sizeof("struct input_event")

local function read_all(path)
    local file = io.open(path, "rb")
    if not file then return nil end
    local text = file:read("*a")
    file:close()
    if text then
        text = text:gsub("%s+$", "")
    end
    return text
end

local function basename(path)
    return tostring(path or ""):match("([^/]+)$") or tostring(path or "")
end

local function shell_quote(value)
    return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function resolved_event_name(device)
    local handle = io.popen("readlink -f " .. shell_quote(device) .. " 2>/dev/null")
    if handle then
        local resolved = handle:read("*l")
        handle:close()
        if resolved and resolved ~= "" then
            return basename(resolved)
        end
    end
    return basename(device)
end

local function event_sysfs_dir(device)
    return "/sys/class/input/" .. resolved_event_name(device) .. "/device"
end

function NativeInput.device_info(device)
    device = device or "/dev/input/touchscreen0"
    local sysfs = event_sysfs_dir(device)
    return {
        device = device,
        name = read_all(sysfs .. "/name") or "",
        properties = read_all(sysfs .. "/properties") or "",
        ev = read_all(sysfs .. "/capabilities/ev") or read_all(sysfs .. "/ev") or "",
        key = read_all(sysfs .. "/capabilities/key") or read_all(sysfs .. "/key") or "",
        abs = read_all(sysfs .. "/capabilities/abs") or read_all(sysfs .. "/abs") or "",
    }
end

function NativeInput.parse_event(event)
    return {
        sec = tonumber(event.tv_sec),
        usec = tonumber(event.tv_usec),
        type = tonumber(event.type),
        code = tonumber(event.code),
        value = tonumber(event.value),
    }
end

function NativeInput:open(device)
    device = device or "/dev/input/touchscreen0"
    local fd = C.open(device, bit.bor(O_RDONLY, O_NONBLOCK, O_CLOEXEC))
    if fd < 0 then
        error("Could not open " .. tostring(device) .. ": " .. ffi.string(C.strerror(ffi.errno())))
    end
    return setmetatable({
        fd = fd,
        device = device,
        state = {
            touching = false,
            x = nil,
            y = nil,
            pressure = nil,
        },
        event_buffer = ffi.new("struct input_event[1]"),
    }, self)
end

function NativeInput:close()
    if self.fd and self.fd >= 0 then
        C.close(self.fd)
        self.fd = -1
    end
end

function NativeInput:apply_event(parsed)
    if parsed.type == self.EV_KEY and parsed.code == self.BTN_TOUCH then
        self.state.touching = parsed.value ~= 0
    elseif parsed.type == self.EV_ABS then
        if parsed.code == self.ABS_MT_POSITION_X or parsed.code == self.ABS_X then
            self.state.x = parsed.value
        elseif parsed.code == self.ABS_MT_POSITION_Y or parsed.code == self.ABS_Y then
            self.state.y = parsed.value
        elseif parsed.code == self.ABS_MT_PRESSURE or parsed.code == self.ABS_PRESSURE then
            self.state.pressure = parsed.value
        end
    elseif parsed.type == self.EV_SYN and parsed.code == self.SYN_REPORT then
        if self.state.x and self.state.y then
            return {
                type = self.state.touching and "touch" or "release",
                x = self.state.x,
                y = self.state.y,
                pressure = self.state.pressure,
            }
        end
    end
    return nil
end

function NativeInput:read_event(timeout_ms)
    local pfd = ffi.new("struct pollfd[1]")
    pfd[0].fd = self.fd
    pfd[0].events = POLLIN
    local ready = C.poll(pfd, 1, timeout_ms or 0)
    if ready <= 0 then
        return nil
    end
    local n = C.read(self.fd, self.event_buffer, EVENT_SIZE)
    if n ~= EVENT_SIZE then
        return nil
    end
    local parsed = NativeInput.parse_event(self.event_buffer[0])
    return self:apply_event(parsed), parsed
end

return NativeInput
