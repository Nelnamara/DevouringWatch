-- DevouringWatch
-- Void Assault zone event tracker for WoW Midnight 12.0.7+
-- Author: Nelnamara
--
-- Automatically scans the current map for timed zone events (Void Assaults, Void Strikes,
-- etc.) using C_AreaPoiInfo. No hardcoded POI IDs required — works on day 1 of any patch.
-- Use /dw scan to print discovered POI IDs for reporting.

DevouringWatch = {}
local DW = DevouringWatch

DW.version = "1.0.0"

-- Currency IDs confirmed for 12.0.7
local CURRENCY_FIELD_ACCOLADE = 3405
local CURRENCY_VOIDLIGHT_MARL = 3316

-- One-time unlock quest from Ranger Captain Lilatha in Silvermoon City
local INTRO_QUEST = 96080

-- Weekly Void Assault quests — one per zone, rotate weekly
local WEEKLY_ASSAULT_QUESTS = {
    { id = 94385, zone = "Eversong Woods" },
    { id = 94386, zone = "Zul'Aman"       },
}

local DEFAULTS = {
    x      = -400,
    y      =  200,
    scale  = 1.0,
    locked = false,
    alpha  = 0.9,
}

local function FormatCountdown(secs)
    if not secs or secs <= 0 then return "|cFFFF3333ENDED|r" end
    local h = math.floor(secs / 3600)
    local m = math.floor((secs % 3600) / 60)
    local s = math.floor(secs % 60)
    if h > 0 then
        return string.format("|cFFFFCC00%d:%02d:%02d|r", h, m, s)
    else
        return string.format("|cFFFFCC00%d:%02d|r", m, s)
    end
end

function DW:GetMapEvents()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return {} end

    local poiIDs = C_AreaPoiInfo.GetEventsForMap(mapID) or {}
    local results = {}

    for _, poiID in ipairs(poiIDs) do
        local info      = C_AreaPoiInfo.GetAreaPOIInfo(mapID, poiID)
        local secsLeft  = C_AreaPoiInfo.GetAreaPOISecondsLeft(poiID)
        if info then
            results[#results + 1] = {
                id       = poiID,
                name     = info.name or ("Zone Event #" .. poiID),
                secsLeft = secsLeft,
            }
        end
    end

    return results
end

function DW:GetTaskQuests()
    local results = {}
    local numEntries = C_QuestLog.GetNumQuestLogEntries()
    for i = 1, numEntries do
        local info = C_QuestLog.GetInfo(i)
        if info and info.isTask and not info.isHeader and not info.isHidden then
            local pct = GetQuestProgressBarPercent(info.questID) or 0
            results[#results + 1] = {
                questID = info.questID,
                title   = info.title or ("Quest #" .. info.questID),
                pct     = pct,
                done    = info.isComplete,
            }
        end
    end
    return results
end

function DW:GetCurrencies()
    local function safe(id)
        local info = C_CurrencyInfo.GetCurrencyInfo(id)
        return info and info.quantity or 0
    end
    return {
        accolade = safe(CURRENCY_FIELD_ACCOLADE),
        marl     = safe(CURRENCY_VOIDLIGHT_MARL),
    }
end

-- Returns the active weekly Void Assault quest state, or a "locked/none" sentinel.
-- Weekly quest IDs are proper weekly quests (not isTask), so GetTaskQuests() misses
-- them — we check explicitly by questID here.
function DW:GetWeeklyAssaultQuest()
    local unlocked = C_QuestLog.IsQuestFlaggedCompleted(INTRO_QUEST)
    if not unlocked then
        return { locked = true }
    end

    local numEntries = C_QuestLog.GetNumQuestLogEntries()
    for _, q in ipairs(WEEKLY_ASSAULT_QUESTS) do
        -- First check quest log (in progress this week)
        for i = 1, numEntries do
            local info = C_QuestLog.GetInfo(i)
            if info and not info.isHeader and info.questID == q.id then
                local pct = GetQuestProgressBarPercent(q.id) or 0
                return { zone = q.zone, inLog = true, done = false, pct = pct }
            end
        end
        -- Then check if completed this reset
        if C_QuestLog.IsQuestFlaggedCompleted(q.id) then
            return { zone = q.zone, inLog = false, done = true }
        end
    end

    return { locked = false, none = true }
end

local ROW_H   = 18
local FRAME_W = 290
local TITLE_H = 20
local PAD     = 6

function DW:BuildUI()
    local db = self.db

    local frame = CreateFrame("Frame", "DWMainFrame", UIParent, "BackdropTemplate")
    frame:SetSize(FRAME_W, TITLE_H + ROW_H * 6 + PAD * 2)
    frame:SetPoint("CENTER", UIParent, "CENTER", db.x, db.y)
    frame:SetScale(db.scale)
    frame:SetAlpha(db.alpha)
    frame:SetFrameStrata("MEDIUM")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 32, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0.05, 0.02, 0.10, 0.88)
    frame:SetBackdropBorderColor(0.55, 0.25, 0.70, 0.85)

    frame:SetScript("OnMouseDown", function(self, btn)
        if btn == "LeftButton" and not DW.db.locked then self:StartMoving() end
    end)
    frame:SetScript("OnMouseUp", function(self)
        self:StopMovingOrSizing()
        DW:SavePosition()
    end)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOP", frame, "TOP", 0, -5)
    title:SetText("|cFF9966FFDevouringWatch|r  |cFF888888" .. DW.version .. "|r")

    local divider = frame:CreateTexture(nil, "BACKGROUND")
    divider:SetSize(FRAME_W - 16, 1)
    divider:SetPoint("TOP", frame, "TOP", 0, -(TITLE_H - 2))
    divider:SetColorTexture(0.45, 0.20, 0.60, 0.6)

    self.linePool = {}
    for i = 1, 24 do
        local fs = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD + 4, -(TITLE_H + (i - 1) * ROW_H + 4))
        fs:SetWidth(FRAME_W - PAD * 2 - 8)
        fs:SetJustifyH("LEFT")
        fs:SetWordWrap(false)
        fs:Hide()
        self.linePool[i] = fs
    end

    self.sepPool = {}
    for i = 1, 5 do
        local sep = frame:CreateTexture(nil, "BACKGROUND")
        sep:SetSize(FRAME_W - 20, 1)
        sep:SetColorTexture(0.35, 0.15, 0.50, 0.5)
        sep:Hide()
        self.sepPool[i] = sep
    end

    frame:Show()
    self.frame = frame

    C_Timer.NewTicker(1, function()
        if DW.frame and DW.frame:IsShown() then DW:Refresh() end
    end)
end

function DW:Refresh()
    if not self.frame then return end

    local events = self:GetMapEvents()
    local quests = self:GetTaskQuests()
    local currs  = self:GetCurrencies()

    local lines = {}

    -- Zone events with timers
    local hasEvents = false
    for _, ev in ipairs(events) do
        hasEvents = true
        local timerStr = ev.secsLeft and FormatCountdown(ev.secsLeft) or "|cFF888888(no timer)|r"
        lines[#lines + 1] = "|cFFCC99FF" .. ev.name .. "|r  " .. timerStr
    end

    if not hasEvents then
        lines[#lines + 1] = "|cFF666666No zone events active|r"
    end

    -- Weekly Void Assault quest (proper weekly, not isTask — checked explicitly)
    lines[#lines + 1] = "sep"
    local wa = self:GetWeeklyAssaultQuest()
    if wa.locked then
        lines[#lines + 1] = "|cFF666666Void Assaults locked — pick up intro quest in Silvermoon|r"
    elseif wa.done then
        lines[#lines + 1] = "|cFF66FF66Weekly Assault: " .. wa.zone .. " — DONE|r"
    elseif wa.inLog then
        local pctStr = wa.pct > 0 and string.format(" |cFFFFDD88%.0f%%|r", wa.pct) or ""
        lines[#lines + 1] = "|cFFCC99FFWeekly Assault: " .. wa.zone .. "|r" .. pctStr
    elseif wa.none then
        lines[#lines + 1] = "|cFF888888Weekly Assault: no quest active this week|r"
    end

    -- Task quest progress (Void Strikes etc.)
    if #quests > 0 then
        lines[#lines + 1] = "sep"
        for _, q in ipairs(quests) do
            local statusStr
            if q.done then
                statusStr = "|cFF66FF66DONE|r"
            else
                statusStr = string.format("|cFFFFDD88%.0f%%|r", q.pct)
            end
            lines[#lines + 1] = "|cFFAA88FF" .. q.title .. "|r  " .. statusStr
        end
    end

    -- Currency totals
    lines[#lines + 1] = "sep"
    lines[#lines + 1] = string.format("|cFFFFD700Field Accolade:|r  %d", currs.accolade)
    lines[#lines + 1] = string.format("|cFFAA88FFVoidlight Marl:|r   %d", currs.marl)

    self:RenderLines(lines)
end

function DW:RenderLines(lines)
    local sepIdx  = 1
    local lineIdx = 0
    local yOff    = 0

    for _, entry in ipairs(lines) do
        if entry == "sep" then
            local sep = self.sepPool[sepIdx]
            if sep then
                sep:SetPoint("TOPLEFT", self.frame, "TOPLEFT", PAD + 4,
                    -(TITLE_H + yOff + ROW_H / 2))
                sep:Show()
                sepIdx = sepIdx + 1
                yOff = yOff + ROW_H / 2
            end
        else
            lineIdx = lineIdx + 1
            local fs = self.linePool[lineIdx]
            if fs then
                fs:SetPoint("TOPLEFT", self.frame, "TOPLEFT", PAD + 4,
                    -(TITLE_H + yOff + 4))
                fs:SetText(entry)
                fs:Show()
                yOff = yOff + ROW_H
            end
        end
    end

    for i = lineIdx + 1, #self.linePool do self.linePool[i]:Hide() end
    for i = sepIdx, #self.sepPool do self.sepPool[i]:Hide() end

    self.frame:SetHeight(TITLE_H + yOff + PAD * 2)
end

function DW:SavePosition()
    if not self.frame then return end
    local x, y   = self.frame:GetCenter()
    local ux, uy = UIParent:GetCenter()
    if x and y and ux and uy then
        self.db.x, self.db.y = x - ux, y - uy
    end
end

local ef = CreateFrame("Frame", "DWEventFrame")
ef:RegisterEvent("ADDON_LOADED")
ef:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" and ... == "DevouringWatch" then
        if not DevouringWatchDB then DevouringWatchDB = CopyTable(DEFAULTS) end
        DW.db = DevouringWatchDB
        for k, v in pairs(DEFAULTS) do
            if DW.db[k] == nil then DW.db[k] = v end
        end
        DW:BuildUI()
        DW:Refresh()
        self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        self:RegisterEvent("QUEST_LOG_UPDATE")
        self:RegisterEvent("PLAYER_LOGOUT")
    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "QUEST_LOG_UPDATE" then
        DW:Refresh()
    elseif event == "PLAYER_LOGOUT" then
        DW:SavePosition()
    end
end)

SLASH_DEVOURINGWATCH1 = "/dw"
SlashCmdList["DEVOURINGWATCH"] = function(msg)
    local cmd = (msg or ""):match("^%s*(%S*)"):lower()
    if cmd == "scan" then
        print("|cFF9966FFDevouringWatch|r zone event scan:")
        local events = DW:GetMapEvents()
        if #events == 0 then
            print("  No timed events found on current map.")
        else
            for _, ev in ipairs(events) do
                print(string.format("  POI #%d  %s  secsLeft=%s",
                    ev.id, ev.name, tostring(ev.secsLeft)))
            end
        end
    elseif cmd == "lock" then
        DW.db.locked = true
        print("|cFF9966FFDevouringWatch|r locked.")
    elseif cmd == "unlock" then
        DW.db.locked = false
        print("|cFF9966FFDevouringWatch|r unlocked.")
    elseif cmd == "reset" then
        DW.db.x, DW.db.y = -400, 200
        DW.frame:ClearAllPoints()
        DW.frame:SetPoint("CENTER", UIParent, "CENTER", -400, 200)
    else
        DW.frame:SetShown(not DW.frame:IsShown())
    end
end
