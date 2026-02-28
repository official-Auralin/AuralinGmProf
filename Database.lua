local _, ns = ...

local DB = {}
ns.DB = DB

local CURRENT_DB_VERSION = 2

DB.defaults = {
    dbVersion = CURRENT_DB_VERSION,
    minimap = {
        hide = false,
    },
    showSecondary = true,
    sortPrimaryFirst = true,
    rememberLastProfession = true,
    enableElvUIDataText = true,
    clickActions = {
        left = "open_last_or_first",
        right = "open_spellbook",
        middle = "show_tooltip",
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

local function MigrateLegacyClickActions(db)
    if type(db) ~= "table" then
        return
    end

    -- Only migrate pre-versioned profiles that still match the old defaults.
    if db.dbVersion ~= nil or type(db.clickActions) ~= "table" then
        return
    end

    if db.clickActions.left == "open_last_or_first"
        and db.clickActions.right == "show_tooltip"
        and db.clickActions.middle == "open_spellbook"
    then
        db.clickActions.right = "open_spellbook"
        db.clickActions.middle = "show_tooltip"
    end
end

function DB:Init()
    if type(AuralinGmProfDB) ~= "table" then
        AuralinGmProfDB = {}
    end

    MigrateLegacyClickActions(AuralinGmProfDB)
    CopyDefaults(self.defaults, AuralinGmProfDB)
    AuralinGmProfDB.dbVersion = CURRENT_DB_VERSION

    self.data = AuralinGmProfDB
end

function DB:Get()
    return self.data
end

function DB:Reset()
    AuralinGmProfDB = {}
    self:Init()
end
