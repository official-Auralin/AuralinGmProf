local _, ns = ...

local DB = {}
ns.DB = DB

DB.defaults = {
    minimap = {
        hide = false,
    },
    showSecondary = true,
    sortPrimaryFirst = true,
    rememberLastProfession = true,
    enableElvUIDataText = true,
    clickActions = {
        left = "open_last_or_first",
        right = "show_tooltip",
        middle = "open_spellbook",
    },
    lastSkillLineID = nil,
}

local function CopyDefaults(defaults, target)
    for key, value in pairs(defaults) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then
                target[key] = {}
            end
            CopyDefaults(value, target[key])
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

function DB:Init()
    if type(AuralinGmProfDB) ~= "table" then
        AuralinGmProfDB = {}
    end

    CopyDefaults(self.defaults, AuralinGmProfDB)
    self.data = AuralinGmProfDB
end

function DB:Get()
    return self.data
end

function DB:Reset()
    AuralinGmProfDB = {}
    self:Init()
end
