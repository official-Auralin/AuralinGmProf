local _, ns = ...

local DB = {}
ns.DB = DB

local CURRENT_DB_VERSION = 3

local DATATEXT_MODE_LIST = { "focused", "lowest", "portfolio", "count" }

local VALID_DATATEXT_MODES = {}
for _, mode in ipairs(DATATEXT_MODE_LIST) do
    VALID_DATATEXT_MODES[mode] = true
end

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
    datatext = {
        mode = "focused",
        warnThreshold = 200,
        showPercent = false,
        portfolioCount = 2,
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

local function NormalizeDataTextConfig(db)
    if type(db.datatext) ~= "table" then
        db.datatext = {}
    end

    local dt = db.datatext

    if not VALID_DATATEXT_MODES[dt.mode] then
        dt.mode = DB.defaults.datatext.mode
    end

    local threshold = tonumber(dt.warnThreshold)
    if not threshold then
        threshold = DB.defaults.datatext.warnThreshold
    end
    if threshold < 0 then
        threshold = 0
    end
    dt.warnThreshold = math.floor(threshold + 0.5)

    if type(dt.showPercent) ~= "boolean" then
        dt.showPercent = DB.defaults.datatext.showPercent
    end

    local portfolioCount = tonumber(dt.portfolioCount)
    if not portfolioCount then
        portfolioCount = DB.defaults.datatext.portfolioCount
    end
    portfolioCount = math.floor(portfolioCount)
    if portfolioCount < 2 then
        portfolioCount = 2
    elseif portfolioCount > 4 then
        portfolioCount = 4
    end
    dt.portfolioCount = portfolioCount
end

function DB:IsValidDataTextMode(mode)
    return VALID_DATATEXT_MODES[mode] == true
end

function DB:GetDataTextModeList()
    return DATATEXT_MODE_LIST
end

function DB:Init()
    if type(AuralinGmProfDB) ~= "table" then
        AuralinGmProfDB = {}
    end

    MigrateLegacyClickActions(AuralinGmProfDB)
    CopyDefaults(self.defaults, AuralinGmProfDB)
    NormalizeDataTextConfig(AuralinGmProfDB)

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
