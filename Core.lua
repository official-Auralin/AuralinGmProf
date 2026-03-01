local ADDON, ns = ...
local L = ns.L

local Core = CreateFrame("Frame")
ns.Core = Core

local initialized = false

local ACTION_ALIASES = {
    open = "open_last_or_first",
    tooltip = "show_tooltip",
    spellbook = "open_spellbook",
}

local function Trim(value)
    return (value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function PrintMessage(message)
    if ns.UI and ns.UI.Print then
        ns.UI:Print(message)
    end
end

local function JoinModes()
    return table.concat(ns.DB:GetDataTextModeList(), ", ")
end

local function PrintHelp()
    PrintMessage("/agmp help")
    PrintMessage("/agmp open - open last or first profession")
    PrintMessage("/agmp spellbook - open spellbook/profession fallback")
    PrintMessage("/agmp minimap - toggle minimap icon")
    PrintMessage("/agmp config - open options")
    PrintMessage("/agmp left|right|middle open|tooltip|spellbook")
    PrintMessage(L["/agmp datatext focused|lowest|portfolio|count"])
    PrintMessage(L["/agmp warn <number> - low concentration alert threshold"])
    PrintMessage(L["/agmp percent - toggle concentration percentage display"])
end

local function SetClickAction(button, actionAlias)
    local action = ACTION_ALIASES[actionAlias]
    if not action then
        PrintMessage("Action must be one of: open, tooltip, spellbook.")
        return
    end

    local db = ns.DB:Get()
    db.clickActions[button] = action
    PrintMessage(string.format("Set %s click action to %s.", button, actionAlias))
end

local function HandleDataTextCommand(argument)
    local db = ns.DB:Get()
    local mode = string.lower(argument or "")

    if mode == "" then
        PrintMessage(string.format("%s: %s", L["DataText mode"], ns.UI:GetDataTextModeLabel(db.datatext.mode)))
        PrintMessage(string.format(L["Available modes: %s"], JoinModes()))
        return
    end

    if not ns.DB:IsValidDataTextMode(mode) then
        PrintMessage(string.format(L["Invalid DataText mode. Available: %s"], JoinModes()))
        return
    end

    ns.UI:SetDataTextMode(mode)
    PrintMessage(string.format(L["DataText mode set to %s."], ns.UI:GetDataTextModeLabel(mode)))
end

local function HandleWarnCommand(argument)
    local value = tonumber(argument)
    if not value then
        PrintMessage(L["Usage: /agmp warn <number>"])
        return
    end

    value = math.floor(value + 0.5)
    if value < 0 then
        value = 0
    end

    ns.DB:Get().datatext.warnThreshold = value
    ns.UI:RefreshBrokerText()
    PrintMessage(string.format(L["Low concentration warning threshold set to %d."], value))
end

local function RegisterSlashCommands()
    SLASH_AURALINGMPROF1 = "/agmp"
    SLASH_AURALINGMPROF2 = "/auralingmprof"

    SlashCmdList["AURALINGMPROF"] = function(message)
        local input = Trim(message)
        local command, rest = input:match("^(%S*)%s*(.-)$")
        command = string.lower(command or "")
        rest = Trim(rest)

        if command == "" or command == "help" then
            PrintHelp()
            return
        end

        if command == "open" then
            ns.UI:OpenPreferredProfession()
            return
        end

        if command == "spellbook" then
            ns.UI:OpenSpellbook()
            return
        end

        if command == "config" or command == "options" then
            ns.SettingsUI:Open()
            return
        end

        if command == "minimap" then
            local db = ns.DB:Get()
            ns.UI:SetMinimapShown(db.minimap.hide)
            return
        end

        if command == "reset" then
            ns.DB:Reset()
            ns.UI:RefreshMinimapIcon()
            ns.UI:RefreshBrokerText()
            PrintMessage("Profile reset.")
            return
        end

        if command == "left" or command == "right" or command == "middle" then
            SetClickAction(command, string.lower(rest))
            return
        end

        if command == "datatext" then
            HandleDataTextCommand(rest)
            return
        end

        if command == "warn" or command == "threshold" then
            HandleWarnCommand(rest)
            return
        end

        if command == "percent" then
            local dt = ns.DB:Get().datatext
            dt.showPercent = not dt.showPercent
            ns.UI:RefreshBrokerText()
            if dt.showPercent then
                PrintMessage(L["Concentration percentage display: ON"])
            else
                PrintMessage(L["Concentration percentage display: OFF"])
            end
            return
        end

        PrintMessage(L["Unknown command. Type /agmp help"])
    end
end

function Core:Initialize()
    if initialized then
        return
    end

    ns.DB:Init()
    ns.UI:Initialize()
    ns.SettingsUI:Initialize()
    RegisterSlashCommands()

    ns.UI:RefreshBrokerText()
    if ns.ElvUIBridge then
        ns.ElvUIBridge:Register()
    end

    initialized = true
end

function Core:ADDON_LOADED(addonName)
    if addonName == ADDON then
        self:Initialize()
    elseif addonName == "ElvUI" and initialized and ns.ElvUIBridge then
        ns.ElvUIBridge:Register()
    end
end

function Core:PLAYER_LOGIN()
    if initialized then
        ns.UI:RefreshBrokerText()
        if ns.ElvUIBridge then
            ns.ElvUIBridge:Register()
        end
    end
end

function Core:SKILL_LINES_CHANGED()
    if initialized then
        ns.UI:RefreshBrokerText()
    end
end

function Core:TRADE_SKILL_SHOW()
    if initialized then
        ns.UI:RefreshBrokerText()
    end
end

function Core:CURRENCY_DISPLAY_UPDATE()
    if initialized then
        ns.UI:RefreshBrokerText()
    end
end

Core:SetScript("OnEvent", function(self, event, ...)
    if self[event] then
        self[event](self, ...)
    end
end)

Core:RegisterEvent("ADDON_LOADED")
Core:RegisterEvent("PLAYER_LOGIN")
Core:RegisterEvent("SKILL_LINES_CHANGED")
Core:RegisterEvent("TRADE_SKILL_SHOW")
Core:RegisterEvent("CURRENCY_DISPLAY_UPDATE")

function _G.AuralinGmProf_AddonCompartmentClick(addonName, buttonName, menuButtonFrame)
    if addonName and addonName ~= ADDON then
        return
    end
    if ns.UI then
        ns.UI:HandleCompartmentClick(buttonName or "LeftButton", menuButtonFrame)
    end
end

function _G.AuralinGmProf_AddonCompartmentOnEnter(addonName, menuButtonFrame)
    if addonName and addonName ~= ADDON then
        return
    end
    if ns.UI then
        ns.UI:HandleCompartmentEnter(menuButtonFrame)
    end
end

function _G.AuralinGmProf_AddonCompartmentOnLeave(addonName, menuButtonFrame)
    if addonName and addonName ~= ADDON then
        return
    end
    if ns.UI then
        ns.UI:HandleCompartmentLeave(menuButtonFrame)
    end
end
