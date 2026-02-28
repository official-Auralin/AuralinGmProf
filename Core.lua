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

local function PrintHelp()
    PrintMessage("/agmp help")
    PrintMessage("/agmp open - open last or first profession")
    PrintMessage("/agmp spellbook - open spellbook/profession fallback")
    PrintMessage("/agmp minimap - toggle minimap icon")
    PrintMessage("/agmp config - open options")
    PrintMessage("/agmp left|right|middle open|tooltip|spellbook")
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

Core:SetScript("OnEvent", function(self, event, ...)
    if self[event] then
        self[event](self, ...)
    end
end)

Core:RegisterEvent("ADDON_LOADED")
Core:RegisterEvent("PLAYER_LOGIN")
Core:RegisterEvent("SKILL_LINES_CHANGED")
Core:RegisterEvent("TRADE_SKILL_SHOW")

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
