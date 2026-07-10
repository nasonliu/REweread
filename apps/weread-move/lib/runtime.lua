local Runtime = {}
Runtime.__index = Runtime

local KoreaderPaths = require("koreader_paths")

function Runtime:init(opts)
    opts = opts or {}
    local koreader_dir = os.getenv("KO_DIR") or "/home/root/xovi/exthome/appload/koreader"
    KoreaderPaths.append(koreader_dir)

    require("ffi/loadlib")

    G_defaults = require("luadefaults"):open()
    local DataStorage = require("datastorage")
    G_reader_settings = require("luasettings"):open(DataStorage:getDataDir() .. "/settings.reader.lua")

    local lang_locale = G_reader_settings:readSetting("language")
    local gettext = require("gettext")
    if lang_locale then
        gettext.changeLang(lang_locale)
    end

    local Device = require("device")
    local CanvasContext = require("document/canvascontext")
    CanvasContext:init(Device)

    local Version = require("version")
    Version:getCurrentRevision()
    Version:updateVersionLog(Device.model)

    local Bidi = require("ui/bidi")
    Bidi.setup(lang_locale)

    local UIManager = require("ui/uimanager")

    self.app_dir = opts.app_dir or "."
    self.koreader_dir = koreader_dir
    self.Device = Device
    self.UIManager = UIManager
    self.CanvasContext = CanvasContext
    return self
end

function Runtime:exit()
    if self.Device and self.Device.exit then
        self.Device:exit()
    end
end

return setmetatable({}, Runtime)
