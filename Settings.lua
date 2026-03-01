local _, ns = ...
local L = ns.L

local SettingsUI = {
    panel = nil,
    category = nil,
    controls = {},
}

ns.SettingsUI = SettingsUI

local function SetCheckboxText(checkbox, label)
    if checkbox.Text and checkbox.Text.SetText then
        checkbox.Text:SetText(label)
        return
    end

    local text = checkbox:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    text:SetPoint("LEFT", checkbox, "RIGHT", 4, 1)
    text:SetText(label)
    checkbox.Text = text
end

local function CreateCheckbox(parent, yOffset, label, getter, setter)
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", 16, yOffset)
    SetCheckboxText(checkbox, label)
    checkbox:SetScript("OnClick", function(self)
        setter(self:GetChecked() and true or false)
    end)

    checkbox.Refresh = function(self)
        self:SetChecked(getter())
    end

    table.insert(SettingsUI.controls, checkbox)
    return checkbox
end

local function CreateActionButton(parent, yOffset, width, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetPoint("TOPLEFT", 16, yOffset)
    button:SetWidth(width)
    button:SetHeight(22)
    button:SetScript("OnClick", onClick)

    table.insert(SettingsUI.controls, button)
    return button
end

function SettingsUI:Refresh()
    for _, control in ipairs(self.controls) do
        if control.Refresh then
            control:Refresh()
        end
    end
end

function SettingsUI:BuildPanel()
    local panel = CreateFrame("Frame", "AuralinGmProfSettingsPanel", UIParent)
    self.panel = panel

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("AuralinGmProf")

    local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetWidth(620)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetText(L["Modern profession launcher settings."])

    CreateCheckbox(panel, -64, L["Show minimap icon"], function()
        return not ns.DB:Get().minimap.hide
    end, function(value)
        ns.UI:SetMinimapShown(value)
    end)

    CreateCheckbox(panel, -92, L["Show secondary professions"], function()
        return ns.DB:Get().showSecondary
    end, function(value)
        ns.DB:Get().showSecondary = value
        ns.UI:RefreshBrokerText()
    end)

    CreateCheckbox(panel, -120, L["Sort primary professions first"], function()
        return ns.DB:Get().sortPrimaryFirst
    end, function(value)
        ns.DB:Get().sortPrimaryFirst = value
        ns.UI:RefreshBrokerText()
    end)

    CreateCheckbox(panel, -148, L["Remember last opened profession"], function()
        return ns.DB:Get().rememberLastProfession
    end, function(value)
        ns.DB:Get().rememberLastProfession = value
    end)

    CreateCheckbox(panel, -176, L["Enable ElvUI DataText integration"], function()
        return ns.DB:Get().enableElvUIDataText
    end, function(value)
        ns.DB:Get().enableElvUIDataText = value
        if value and ns.ElvUIBridge then
            ns.ElvUIBridge:Register()
        end
        ns.UI:RefreshBrokerText()
    end)

    local modeButton = CreateActionButton(panel, -212, 260, function()
        local mode = ns.UI:CycleDataTextMode()
        ns.UI:Print(string.format(L["DataText mode: %s"], ns.UI:GetDataTextModeLabel(mode)))
        SettingsUI:Refresh()
    end)

    modeButton.Refresh = function(self)
        local mode = ns.DB:Get().datatext.mode
        self:SetText(string.format(L["DataText Mode: %s"], ns.UI:GetDataTextModeLabel(mode)))
    end

    CreateCheckbox(panel, -244, L["Show concentration as percent"], function()
        return ns.DB:Get().datatext.showPercent
    end, function(value)
        ns.DB:Get().datatext.showPercent = value
        ns.UI:RefreshBrokerText()
    end)

    local help = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    help:SetPoint("TOPLEFT", 16, -278)
    help:SetWidth(680)
    help:SetJustifyH("LEFT")
    help:SetText(
        L["Click actions: /agmp left|right|middle open|tooltip|spellbook"] .. "\n"
            .. L["DataText mode: /agmp datatext focused|lowest|portfolio|count"] .. "\n"
            .. L["Low concentration warning threshold: /agmp warn <number>"]
    )

    panel:SetScript("OnShow", function()
        SettingsUI:Refresh()
    end)

    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        self.category = Settings.RegisterCanvasLayoutCategory(panel, "AuralinGmProf")
        Settings.RegisterAddOnCategory(self.category)
    elseif InterfaceOptions_AddCategory then
        panel.name = "AuralinGmProf"
        InterfaceOptions_AddCategory(panel)
    end
end

function SettingsUI:Initialize()
    if self.panel then
        return
    end
    self:BuildPanel()
end

function SettingsUI:Open()
    if self.category and Settings and Settings.OpenToCategory then
        local categoryID = self.category.GetID and self.category:GetID() or self.category.ID
        if categoryID then
            local ok = pcall(Settings.OpenToCategory, categoryID)
            if ok then
                return
            end
        end

        local ok = pcall(Settings.OpenToCategory, self.category)
        if ok then
            return
        end
    end

    if self.panel and InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(self.panel)
        InterfaceOptionsFrame_OpenToCategory(self.panel)
    end
end
