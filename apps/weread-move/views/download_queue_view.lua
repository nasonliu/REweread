local Device = require("device")
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local InputContainer = require("ui/widget/container/inputcontainer")
local UIManager = require("ui/uimanager")
local ViewHelpers = require("view_helpers")

local DownloadQueueView = InputContainer:extend{
    name = "DownloadQueueView",
    jobs = nil,
    on_back = nil,
    on_download_open = nil,
    jobs_per_page = 12,
}

function DownloadQueueView:init()
    self.jobs = self.jobs or {}
    self.dimen = ViewHelpers.screen_size()
    self.page = self.page or 1
    if Device:isTouchDevice() then
        self.ges_events.Tap = {
            GestureRange:new{
                ges = "tap",
                range = Geom:new{ x = 0, y = 0, w = self.dimen.w, h = self.dimen.h },
            },
        }
    end
end

function DownloadQueueView:onShow()
    UIManager:setDirty(self, function()
        return "full", self.dimen
    end)
    return true
end

function DownloadQueueView:setJobs(jobs)
    self.jobs = jobs or {}
    self:clampPage()
    UIManager:setDirty(self, function()
        return "ui", self.dimen
    end)
end

function DownloadQueueView:pageCount()
    return math.max(1, math.ceil(#(self.jobs or {}) / self.jobs_per_page))
end

function DownloadQueueView:clampPage()
    local page_count = self:pageCount()
    if self.page < 1 then self.page = 1 end
    if self.page > page_count then self.page = page_count end
end

function DownloadQueueView:pageOffset()
    self:clampPage()
    return (self.page - 1) * self.jobs_per_page
end

function DownloadQueueView:nextPage()
    if self.page < self:pageCount() then
        self.page = self.page + 1
        UIManager:setDirty(self, "ui")
    end
end

function DownloadQueueView:prevPage()
    if self.page > 1 then
        self.page = self.page - 1
        UIManager:setDirty(self, "ui")
    end
end

function DownloadQueueView:statusLabel(job)
    if job.staleFile then return "文件缺失" end
    local state = tostring(job.downloadState or "")
    if state == "full" then return "已下载" end
    if state == "partial" then
        if job.fullFile and job.fullFile ~= "" then return "已下载部分" end
        return "已缓存首章"
    end
    if state == "downloading" then
        local progress = tonumber(job.downloadProgress or 0) or 0
        local total = tonumber(job.downloadTotal or 0) or 0
        if total > 0 then
            return "下载中 " .. tostring(progress) .. "/" .. tostring(total)
        end
        return "下载中"
    end
    if state == "failed" then return "失败" end
    if state == "special" then return "暂不可下载" end
    if job.fullFile and job.fullFile ~= "" then return "已下载" end
    if job.cachedFile and job.cachedFile ~= "" then return "已缓存" end
    return "远程"
end

function DownloadQueueView:filePath(job)
    if not job then return "" end
    local full_file = tostring(job.fullFile or "")
    if full_file ~= "" then return full_file end
    local cached_file = tostring(job.cachedFile or "")
    if cached_file ~= "" then return cached_file end
    return ""
end

function DownloadQueueView:drawHeader(bb)
    bb:paintRect(0, 0, self.dimen.w, 80, ViewHelpers.palette.background)
    ViewHelpers.draw_button(bb, 32, 20, 110, 38, "< 书架", "ghost", { size = 14 })
    ViewHelpers.draw_text(bb, 150, 20, "下载", 28, true, ViewHelpers.palette.text, 160)
    ViewHelpers.draw_button(bb, self.dimen.w - 148, 22, 104, 34, tostring(#(self.jobs or {})) .. " 项", "ghost", { size = 13, disabled = true })
    bb:paintRect(32, 76, self.dimen.w - 64, 1, ViewHelpers.palette.light)
end

function DownloadQueueView:drawJobRow(bb, job, index, y)
    local x = 44
    local w = self.dimen.w - 88
    local state = tostring(job.downloadState or "")
    local marker = ViewHelpers.palette.light
    if state == "full" then marker = ViewHelpers.palette.text end
    if state == "failed" or state == "special" or job.staleFile then marker = ViewHelpers.palette.border end
    bb:paintRect(x, y + 12, 8, 58, marker)
    local meta = self:statusLabel(job)
    local status_variant = state == "full" and "primary" or "ghost"
    if state == "failed" or state == "special" or job.staleFile then
        status_variant = "danger"
    end
    ViewHelpers.draw_button(bb, x + w - 150, y + 6, 150, 34, meta, status_variant, { size = 12, disabled = job.staleFile == true })
    ViewHelpers.draw_text(bb, x + 24, y + 6, ViewHelpers.truncate(job.title or job.bookId, 22), 18, true, ViewHelpers.palette.text, w - 190)
    if tonumber(job.chapterCount or 0) > 0 then
        meta = meta .. "  ·  " .. tostring(job.chapterCount) .. "章"
    end
    ViewHelpers.draw_text(bb, x + 24, y + 38, meta, 14, false, ViewHelpers.palette.muted, w - 24)
    local path = self:filePath(job)
    if path ~= "" and not job.staleFile then
        ViewHelpers.draw_text(bb, x + 24, y + 64, ViewHelpers.truncate(path:gsub("^.*/", ""), 38), 12, false, ViewHelpers.palette.muted, w - 24)
    elseif job.lastError and job.lastError ~= "" then
        ViewHelpers.draw_text(bb, x + 24, y + 64, ViewHelpers.truncate(job.lastError, 42), 12, false, ViewHelpers.palette.muted, w - 24)
    end
    bb:paintRect(x, y + 92, w, 1, ViewHelpers.palette.light)
end

function DownloadQueueView:rowIndexAt(y)
    if y < 104 or y > self.dimen.h - 78 then return nil end
    local index = self:pageOffset() + math.floor((y - 104) / 104) + 1
    if index >= 1 and index <= #(self.jobs or {}) then
        return index
    end
    return nil
end

function DownloadQueueView:onTap(_, ges)
    local y = ges.pos.y
    if y < 82 then
        if self.on_back then self.on_back() else UIManager:close(self) end
        return true
    end
    if y > self.dimen.h - 74 then
        local x = ges.pos.x
        if x < 170 then self:prevPage(); return true end
        if x > self.dimen.w - 170 then self:nextPage(); return true end
        return true
    end
    local index = self:rowIndexAt(y)
    local job = index and self.jobs[index]
    if job and not job.staleFile and self.on_download_open and self:filePath(job) ~= "" then
        self.on_download_open(job)
        return true
    end
    return true
end

function DownloadQueueView:drawFooter(bb)
    local footer_y = self.dimen.h - 72
    bb:paintRect(0, footer_y, self.dimen.w, 72, ViewHelpers.palette.background)
    bb:paintRect(32, footer_y, self.dimen.w - 64, 1, ViewHelpers.palette.light)
    local page_text = "Page " .. tostring(self.page) .. " / " .. tostring(self:pageCount())
    ViewHelpers.draw_centered_text(bb, 0, footer_y + 18, self.dimen.w, 34, page_text, 15, false, ViewHelpers.palette.muted, 220)
    ViewHelpers.draw_button(bb, 32, footer_y + 15, 120, 40, "< Prev", "ghost", { size = 15, disabled = self.page <= 1 })
    ViewHelpers.draw_button(bb, self.dimen.w - 152, footer_y + 15, 120, 40, "Next >", "ghost", { size = 15, disabled = self.page >= self:pageCount() })
end

function DownloadQueueView:paintTo(bb)
    bb:paintRect(0, 0, self.dimen.w, self.dimen.h, ViewHelpers.palette.background)
    self:drawHeader(bb)
    if #(self.jobs or {}) == 0 then
        ViewHelpers.draw_text(bb, 44, 128, "暂无下载记录", 18, false, ViewHelpers.palette.muted, self.dimen.w - 88)
        self:drawFooter(bb)
        return
    end
    local offset = self:pageOffset()
    for visible_index = 1, self.jobs_per_page do
        local index = offset + visible_index
        local job = (self.jobs or {})[index]
        if not job then break end
        self:drawJobRow(bb, job, index, 104 + (visible_index - 1) * 104)
    end
    self:drawFooter(bb)
end

return DownloadQueueView
