local ADDON, ns = ...
local L = ns.L

local LibStub = _G.LibStub
local LibQTip = LibStub and LibStub("LibQTip-1.0", true) or nil
local LibDataBroker = LibStub and LibStub("LibDataBroker-1.1", true) or nil
local LibDBIcon = LibStub and LibStub("LibDBIcon-1.0", true) or nil

local LeftButtonIcon = " |TInterface\\TUTORIALFRAME\\UI-TUTORIAL-FRAME:13:11:0:-1:512:512:12:66:230:307|t "
local RightButtonIcon = " |TInterface\\TUTORIALFRAME\\UI-TUTORIAL-FRAME:13:11:0:-1:512:512:12:66:333:411|t "
local MiddleButtonIcon = " |TInterface\\TUTORIALFRAME\\UI-TUTORIAL-FRAME:13:11:0:-1:512:512:12:66:127:204|t "

local DATATEXT_MODE_LABELS = {
    focused = "Focused",
    lowest = "Lowest",
    portfolio = "Portfolio",
    count = "Count",
}

local UI = {
    tooltip = nil,
    dataObject = nil,
    minimapRegistered = false,
}

ns.UI = UI

local function PrintMessage(message)
    local text = "|cff33ccffAuralinGmProf|r: " .. tostring(message)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(text)
    else
        print(text)
    end
end

local function GetHeaderLabel()
    return _G.PROFESSIONS_CRAFTING_HEADER or _G.TRADE_SKILLS or L["Professions"]
end

local function GetLegacyCountText(entries)
    return string.format("%s (%d)", GetHeaderLabel(), #entries)
end

local function FormatIcon(icon)
    if not icon then
        return ""
    end
    return string.format("|T%s:0|t", tostring(icon))
end

local function ResolveCurrencyIcon(info, fallbackIcon)
    if type(info) == "table" then
        if type(info.iconFileID) == "number" and info.iconFileID > 0 then
            return info.iconFileID
        end

        if type(info.iconFileID) == "string" and info.iconFileID ~= "" then
            return info.iconFileID
        end

        if type(info.icon) == "number" and info.icon > 0 then
            return info.icon
        end

        if type(info.icon) == "string" and info.icon ~= "" then
            return info.icon
        end
    end

    return fallbackIcon
end

local function GetFillRatio(snapshot)
    if snapshot.maxQuantity and snapshot.maxQuantity > 0 then
        return snapshot.quantity / snapshot.maxQuantity
    end
    return snapshot.quantity
end

local function CompareByFillThenQuantity(a, b)
    local aFill = GetFillRatio(a)
    local bFill = GetFillRatio(b)
    if aFill ~= bFill then
        return aFill < bFill
    end

    if a.quantity ~= b.quantity then
        return a.quantity < b.quantity
    end

    local aName = string.lower(a.entry.name or "")
    local bName = string.lower(b.entry.name or "")
    return aName < bName
end

local function GetConcentrationValueText(snapshot, showPercent)
    if showPercent and snapshot.maxQuantity and snapshot.maxQuantity > 0 then
        local pct = math.floor((snapshot.quantity / snapshot.maxQuantity) * 100 + 0.5)
        return string.format("%d%%", pct)
    end

    if snapshot.maxQuantity and snapshot.maxQuantity > 0 then
        return string.format("%d/%d", snapshot.quantity, snapshot.maxQuantity)
    end

    return tostring(snapshot.quantity)
end

local function CloneAndSortSnapshots(snapshots)
    local sorted = {}
    for _, snapshot in ipairs(snapshots) do
        table.insert(sorted, snapshot)
    end
    table.sort(sorted, CompareByFillThenQuantity)
    return sorted
end

function UI:Print(message)
    PrintMessage(message)
end

function UI:GetDataTextModeLabel(mode)
    return DATATEXT_MODE_LABELS[mode] or DATATEXT_MODE_LABELS.count
end

function UI:SetDataTextMode(mode)
    if not ns.DB:IsValidDataTextMode(mode) then
        return false
    end

    ns.DB:Get().datatext.mode = mode
    self:RefreshBrokerText()
    return true
end

function UI:CycleDataTextMode()
    local db = ns.DB:Get()
    local modes = ns.DB:GetDataTextModeList()
    local current = db.datatext.mode

    local index = 1
    for i, mode in ipairs(modes) do
        if mode == current then
            index = i
            break
        end
    end

    local nextIndex = index + 1
    if nextIndex > #modes then
        nextIndex = 1
    end

    local mode = modes[nextIndex]
    db.datatext.mode = mode
    self:RefreshBrokerText()
    return mode
end

function UI:GetConcentrationSnapshots(entries)
    local snapshots = {}

    if not (C_TradeSkillUI and type(C_TradeSkillUI.GetConcentrationCurrencyID) == "function") then
        return snapshots
    end

    if not (C_CurrencyInfo and type(C_CurrencyInfo.GetCurrencyInfo) == "function") then
        return snapshots
    end

    local seenCurrency = {}

    for _, entry in ipairs(entries) do
        if entry.skillLineID then
            local okCurrency, currencyID = pcall(C_TradeSkillUI.GetConcentrationCurrencyID, entry.skillLineID)
            if okCurrency and type(currencyID) == "number" and currencyID > 0 and not seenCurrency[currencyID] then
                local okInfo, info = pcall(C_CurrencyInfo.GetCurrencyInfo, currencyID)
                if okInfo and type(info) == "table" then
                    local quantity = tonumber(info.quantity) or 0
                    local maxQuantity = tonumber(info.maxQuantity) or 0

                    table.insert(snapshots, {
                        entry = entry,
                        currencyID = currencyID,
                        quantity = quantity,
                        maxQuantity = maxQuantity,
                        icon = ResolveCurrencyIcon(info, entry.icon),
                        currencyName = info.name,
                    })

                    seenCurrency[currencyID] = true
                end
            end
        end
    end

    return snapshots
end

function UI:GetFocusedSnapshot(snapshots, lastSkillLineID)
    if type(lastSkillLineID) == "number" then
        for _, snapshot in ipairs(snapshots) do
            if snapshot.entry.skillLineID == lastSkillLineID or snapshot.entry.parentSkillLineID == lastSkillLineID then
                return snapshot
            end
        end
    end

    return snapshots[1]
end

function UI:IsLowConcentration(snapshot, db)
    local threshold = db.datatext.warnThreshold or 0
    return snapshot.quantity <= threshold
end

function UI:GetBrokerText()
    local db = ns.DB:Get()
    if not db then
        return GetHeaderLabel()
    end

    local entries = ns.ProfessionService:GetProfessionEntries(db)
    if #entries == 0 then
        return GetHeaderLabel()
    end

    local mode = db.datatext.mode
    if mode == "count" then
        return GetLegacyCountText(entries)
    end

    local snapshots = self:GetConcentrationSnapshots(entries)
    if #snapshots == 0 then
        return GetLegacyCountText(entries)
    end

    if mode == "lowest" then
        local lowest = CloneAndSortSnapshots(snapshots)[1]
        local value = GetConcentrationValueText(lowest, db.datatext.showPercent)
        local alert = self:IsLowConcentration(lowest, db) and " !" or ""
        return string.format("LOW %s %s%s", FormatIcon(lowest.icon), value, alert)
    end

    if mode == "portfolio" then
        local sorted = CloneAndSortSnapshots(snapshots)
        local maxItems = db.datatext.portfolioCount or 2
        local parts = {}

        for i = 1, math.min(maxItems, #sorted) do
            local snapshot = sorted[i]
            local value = GetConcentrationValueText(snapshot, db.datatext.showPercent)
            local alert = self:IsLowConcentration(snapshot, db) and "!" or ""
            table.insert(parts, string.format("%s %s%s", FormatIcon(snapshot.icon), value, alert))
        end

        return table.concat(parts, " | ")
    end

    local focused = self:GetFocusedSnapshot(snapshots, db.lastSkillLineID)
    if focused then
        local value = GetConcentrationValueText(focused, db.datatext.showPercent)
        local alert = self:IsLowConcentration(focused, db) and " !" or ""
        return string.format("%s %s%s", FormatIcon(focused.icon), value, alert)
    end

    return GetLegacyCountText(entries)
end

function UI:RefreshBrokerText()
    if self.dataObject then
        self.dataObject.text = self:GetBrokerText()
    end
end

function UI:RefreshMinimapIcon()
    if not (LibDBIcon and self.minimapRegistered) then
        return
    end

    local db = ns.DB:Get()
    if db and db.minimap and db.minimap.hide then
        LibDBIcon:Hide(ADDON)
    else
        LibDBIcon:Show(ADDON)
    end
end

function UI:SetMinimapShown(show)
    local db = ns.DB:Get()
    db.minimap.hide = not show
    self:RefreshMinimapIcon()
end

local function GetKindLabel(kind)
    if kind == "secondary" then
        return "|cffffd200" .. L["Secondary"] .. "|r"
    end
    return "|cff00ff7f" .. L["Primary"] .. "|r"
end

local function GetLaunchMessage(reason)
    if reason == "combat" then
        return L["Action blocked while in combat."]
    end
    if reason == "no_professions" then
        return L["No professions were found."]
    end
    return "Unable to open a profession UI with the available APIs."
end

function UI:HandleOpenResult(entry, result)
    if result.ok then
        if result.reason == "spellbook_fallback" then
            self:Print(L["Opened spellbook fallback."])
        end

        if entry and entry.skillLineID then
            local db = ns.DB:Get()
            if db.rememberLastProfession then
                db.lastSkillLineID = entry.skillLineID
            end
        end

        self:RefreshBrokerText()
    else
        self:Print(GetLaunchMessage(result.reason))
    end
end

function UI:OpenEntry(entry)
    local result = ns.ProfessionService:OpenEntry(entry)
    self:HandleOpenResult(entry, result)
end

function UI:OpenPreferredProfession()
    local db = ns.DB:Get()
    local entries = ns.ProfessionService:GetProfessionEntries(db)
    local entry = ns.ProfessionService:GetPreferredEntry(entries, db.lastSkillLineID)
    if not entry then
        self:Print(L["No professions were found."])
        return
    end
    self:OpenEntry(entry)
end

function UI:OpenSpellbook()
    local result = ns.ProfessionService:OpenSpellBook()
    self:HandleOpenResult(nil, result)
end

local function TooltipLine_OnMouseDown(_, entry, button)
    if not entry then
        return
    end
    if button == "RightButton" then
        UI:OpenSpellbook()
    else
        UI:OpenEntry(entry)
    end
    UI:HideTooltip()
end

function UI:HideTooltip()
    if self.tooltip and LibQTip then
        LibQTip:Release(self.tooltip)
    end
    self.tooltip = nil
end

function UI:ShowTooltip(anchor)
    if not LibQTip then
        return
    end

    self:HideTooltip()

    local tooltip = LibQTip:Acquire(ADDON .. "Tooltip", 3, "LEFT", "RIGHT", "LEFT")
    self.tooltip = tooltip

    local owner = anchor or UIParent
    tooltip:SmartAnchorTo(owner)
    tooltip:EnableMouse(true)
    tooltip:SetAutoHideDelay(0.2, owner)
    tooltip.OnRelease = function()
        UI.tooltip = nil
    end

    local title = GetHeaderLabel()
    tooltip:AddHeader("|cffffd200" .. title .. "|r", "|cffffd200" .. L["Current"] .. "|r", "")
    tooltip:AddSeparator()

    local entries = ns.ProfessionService:GetProfessionEntries(ns.DB:Get())
    if #entries == 0 then
        tooltip:AddLine(L["No professions were found."], "", "")
    else
        for _, entry in ipairs(entries) do
            local name = entry.name or "?"
            if entry.isExpandedLine then
                name = "   " .. name
            end

            local icon = ""
            if entry.icon then
                icon = string.format("|T%s:0|t ", tostring(entry.icon))
            end

            local rank = "-"
            if entry.maxRank and entry.maxRank > 0 then
                rank = string.format("%d/%d", entry.rank or 0, entry.maxRank)
            end

            local row = tooltip:AddLine(icon .. name, rank, GetKindLabel(entry.kind))
            tooltip:SetLineScript(row, "OnMouseDown", TooltipLine_OnMouseDown, entry)
            if entry.maxRank and entry.maxRank > 0 and entry.rank == entry.maxRank then
                tooltip:SetLineTextColor(row, 0, 1, 0, 1)
            end
        end
    end

    tooltip:AddSeparator()
    tooltip:AddLine(
        LeftButtonIcon .. L["Open"],
        RightButtonIcon .. L["Spellbook"],
        MiddleButtonIcon .. L["Toggle tooltip"]
    )
    tooltip:Show()
end

function UI:ToggleTooltip(anchor)
    if self.tooltip then
        self:HideTooltip()
    else
        self:ShowTooltip(anchor)
    end
end

function UI:RunAction(action, anchor)
    if action == "show_tooltip" then
        self:ToggleTooltip(anchor)
    elseif action == "open_spellbook" then
        self:OpenSpellbook()
    else
        self:OpenPreferredProfession()
    end
end

function UI:HandleClick(anchor, button)
    local db = ns.DB:Get()
    local action = db.clickActions.left
    if button == "RightButton" then
        action = db.clickActions.right
    elseif button == "MiddleButton" then
        action = db.clickActions.middle
    end
    self:RunAction(action, anchor)
end

function UI:HandleCompartmentClick(buttonName, anchor)
    self:HandleClick(anchor or _G.AddonCompartmentFrame or UIParent, buttonName or "LeftButton")
end

function UI:HandleCompartmentEnter(anchor)
    self:ShowTooltip(anchor or _G.AddonCompartmentFrame or UIParent)
end

function UI:HandleCompartmentLeave()
    self:HideTooltip()
end

function UI:Initialize()
    if LibDataBroker then
        local dataObject = LibDataBroker:GetDataObjectByName(ADDON)
        if not dataObject then
            dataObject = LibDataBroker:NewDataObject(ADDON, {
                type = "data source",
                icon = "Interface\\Minimap\\Tracking\\Repair",
                text = self:GetBrokerText(),
            })
        end

        self.dataObject = dataObject
        self.dataObject.icon = "Interface\\Minimap\\Tracking\\Repair"
        self.dataObject.text = self:GetBrokerText()
        self.dataObject.OnClick = function(frame, button)
            UI:HandleClick(frame, button)
        end
        self.dataObject.OnEnter = function(frame)
            UI:ShowTooltip(frame)
        end
        self.dataObject.OnLeave = function()
            -- Some LDB displays expect OnLeave to exist even when unused.
        end
    else
        self:Print("LibDataBroker-1.1 is missing. LDB launcher is disabled.")
    end

    if LibDBIcon and self.dataObject then
        if not self.minimapRegistered then
            LibDBIcon:Register(ADDON, self.dataObject, ns.DB:Get().minimap)
            self.minimapRegistered = true
        end
        self:RefreshMinimapIcon()
    end
end

