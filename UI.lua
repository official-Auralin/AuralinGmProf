local ADDON, ns = ...
local L = ns.L

local LibStub = _G.LibStub
local LibQTip = LibStub and LibStub("LibQTip-1.0", true) or nil
local LibDataBroker = LibStub and LibStub("LibDataBroker-1.1", true) or nil
local LibDBIcon = LibStub and LibStub("LibDBIcon-1.0", true) or nil

local LeftButtonIcon = " |TInterface\\TUTORIALFRAME\\UI-TUTORIAL-FRAME:13:11:0:-1:512:512:12:66:230:307|t "
local RightButtonIcon = " |TInterface\\TUTORIALFRAME\\UI-TUTORIAL-FRAME:13:11:0:-1:512:512:12:66:333:411|t "
local MiddleButtonIcon = " |TInterface\\TUTORIALFRAME\\UI-TUTORIAL-FRAME:13:11:0:-1:512:512:12:66:127:204|t "

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

function UI:Print(message)
    PrintMessage(message)
end

function UI:GetBrokerText()
    local label = _G.PROFESSIONS_CRAFTING_HEADER or _G.TRADE_SKILLS or L["Professions"]
    local db = ns.DB:Get()
    if not db then
        return label
    end

    local entries = ns.ProfessionService:GetProfessionEntries(db)
    if #entries == 0 then
        return label
    end

    return string.format("%s (%d)", label, #entries)
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

    local title = _G.PROFESSIONS_CRAFTING_HEADER or _G.TRADE_SKILLS or L["Professions"]
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
