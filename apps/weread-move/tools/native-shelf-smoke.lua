io.stdout:setvbuf("line")

local app_dir = os.getenv("RM_WEREAD_APP_DIR") or "/home/root/xovi/exthome/appload/weread-move"
package.path = app_dir .. "/?.lua;" .. app_dir .. "/lib/?.lua;" .. app_dir .. "/tools/?.lua;" .. package.path

local NativeRaster = require("native_raster")
local NativeShelf = require("native_shelf")

local output = arg and arg[1] or "/tmp/weread-native-shelf.ppm"
local shelf = NativeShelf:new(os.getenv("RM_WEREAD_CACHE_ROOT"))
local data = shelf:load()
local raster = NativeRaster:new{ width = 360, height = 540 }
local rendered = raster:draw_shelf(data.books)
raster:write_ppm(output)

print("shelf_smoke=ok")
print("books=" .. tostring(#data.books))
print("coverImages=" .. tostring(rendered.coverImages or 0))
print("coverError=" .. tostring(rendered.coverError or ""))
print("out=" .. tostring(output))
