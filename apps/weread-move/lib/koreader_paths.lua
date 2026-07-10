local KoreaderPaths = {}

function KoreaderPaths.append(koreader_dir)
    koreader_dir = koreader_dir or os.getenv("KO_DIR") or "/home/root/xovi/exthome/appload/koreader"
    package.path =
        koreader_dir .. "/?.lua;" ..
        koreader_dir .. "/common/?.lua;" ..
        koreader_dir .. "/frontend/?.lua;" ..
        koreader_dir .. "/plugins/exporter.koplugin/?.lua;" ..
        package.path
    package.cpath =
        koreader_dir .. "/common/?.so;" ..
        koreader_dir .. "/common/?.dll;" ..
        "/usr/lib/lua/?.so;" ..
        package.cpath
    return koreader_dir
end

return KoreaderPaths
