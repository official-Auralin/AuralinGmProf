local _, ns = ...

local ElvUIBridge = {
    registered = false,
}

ns.ElvUIBridge = ElvUIBridge

local function IsAddOnLoadedCompat(addonName)
    if C_AddOns and type(C_AddOns.IsAddOnLoaded) == "function" then
        return C_AddOns.IsAddOnLoaded(addonName)
    end

    if type(_G.IsAddOnLoaded) == "function" then
        return _G.IsAddOnLoaded(addonName)
    end

    return false
end

local function DataText_OnEvent(panel)
    if panel and panel.text and ns.UI and ns.UI.GetBrokerText then
        panel.text:SetText(ns.UI:GetBrokerText())
    end
end

local function DataText_OnClick(panel, button)
    if ns.UI then
        ns.UI:HandleClick(panel, button or "LeftButton")
    end
end

local function DataText_OnEnter(panel)
    if ns.UI then
        ns.UI:ShowTooltip(panel)
    end
end

local function DataText_OnLeave()
    if ns.UI then
        ns.UI:HideTooltip()
    end
end

function ElvUIBridge:Register()
    if self.registered then
        return
    end

    local db = ns.DB:Get()
    if not (db and db.enableElvUIDataText) then
        return
    end

    if not IsAddOnLoadedCompat("ElvUI") then
        return
    end

    local engine = _G.ElvUI
    if type(engine) ~= "table" then
        return
    end

    local E = unpack(engine)
    if type(E) ~= "table" or type(E.GetModule) ~= "function" then
        return
    end

    local DT = E:GetModule("DataTexts", true)
    if not DT or type(DT.RegisterDatatext) ~= "function" then
        return
    end

    local events = {
        "PLAYER_ENTERING_WORLD",
        "SKILL_LINES_CHANGED",
        "TRADE_SKILL_SHOW",
        "CURRENCY_DISPLAY_UPDATE",
    }

    local ok = pcall(
        DT.RegisterDatatext,
        DT,
        "AuralinGmProf",
        events,
        DataText_OnEvent,
        nil,
        DataText_OnClick,
        DataText_OnEnter,
        DataText_OnLeave,
        "AuralinGmProf"
    )

    if ok then
        self.registered = true
    end
end
