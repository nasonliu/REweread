local InfoMessage = require("ui/widget/infomessage")
local ErrorView = {}

function ErrorView.show(UIManager, text)
    UIManager:show(InfoMessage:new{
        text = tostring(text or "Unknown error"),
    })
end

return ErrorView
