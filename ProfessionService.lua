local _, ns = ...

---@class ProfessionEntry
---@field id number
---@field name string
---@field icon number|string|nil
---@field rank number
---@field maxRank number
---@field kind "primary"|"secondary"
---@field skillLineID number|nil
---@field isExpandedLine boolean
---@field professionIndex number|nil
---@field parentSkillLineID number|nil

---@class LaunchResult
---@field ok boolean
---@field reason string|nil

local Service = {}
ns.ProfessionService = Service

local function BuildBaseEntries()
    local entries = {}
    local bySkillLine = {}

    if type(GetProfessions) ~= "function" or type(GetProfessionInfo) ~= "function" then
        return entries, bySkillLine
    end

    local slots = { GetProfessions() }

    for slot = 1, 6 do
        local professionIndex = slots[slot]
        if professionIndex then
            local name, icon, rank, maxRank, _, _, skillLineID = GetProfessionInfo(professionIndex)
            if name then
                local kind = (slot <= 2) and "primary" or "secondary"
                local entry = {
                    id = professionIndex,
                    name = name,
                    icon = icon,
                    rank = rank or 0,
                    maxRank = maxRank or 0,
                    kind = kind,
                    skillLineID = skillLineID,
                    isExpandedLine = false,
                    professionIndex = professionIndex,
                }
                table.insert(entries, entry)
                if skillLineID then
                    bySkillLine[skillLineID] = entry
                end
            end
        end
    end

    return entries, bySkillLine
end

local function AddRetailChildSkillLines(entries, bySkillLine)
    if not C_TradeSkillUI then
        return
    end

    if type(C_TradeSkillUI.GetAllProfessionTradeSkillLines) ~= "function" then
        return
    end

    if type(C_TradeSkillUI.GetProfessionInfoBySkillLineID) ~= "function" then
        return
    end

    local ok, skillLineIDs = pcall(C_TradeSkillUI.GetAllProfessionTradeSkillLines)
    if not ok or type(skillLineIDs) ~= "table" then
        return
    end

    for _, skillLineID in ipairs(skillLineIDs) do
        if skillLineID and not bySkillLine[skillLineID] then
            local okInfo, info = pcall(C_TradeSkillUI.GetProfessionInfoBySkillLineID, skillLineID)
            if okInfo and type(info) == "table" then
                local parentSkillLineID = info.parentProfessionID or info.parentSkillLineID or info.parentProfessionSkillLineID
                local parent = parentSkillLineID and bySkillLine[parentSkillLineID] or nil

                if parent then
                    local name = info.professionName or info.name or info.skillLineName
                    if name then
                        local entry = {
                            id = skillLineID,
                            name = name,
                            icon = info.professionIcon or info.iconFileID or info.icon or parent.icon,
                            rank = info.skillLevel or info.currentSkillLevel or info.currentSkill or 0,
                            maxRank = info.maxSkillLevel or info.maxSkillLevelCap or info.maxSkill or 0,
                            kind = parent.kind,
                            skillLineID = skillLineID,
                            isExpandedLine = true,
                            professionIndex = nil,
                            parentSkillLineID = parentSkillLineID,
                        }
                        table.insert(entries, entry)
                        bySkillLine[skillLineID] = entry
                    end
                end
            end
        end
    end
end

local function ComparePrimaryFirst(a, b)
    if a.kind ~= b.kind then
        return a.kind == "primary"
    end

    if a.isExpandedLine ~= b.isExpandedLine then
        return not a.isExpandedLine
    end

    local aName = string.lower(a.name or "")
    local bName = string.lower(b.name or "")
    if aName ~= bName then
        return aName < bName
    end

    return (a.skillLineID or 0) < (b.skillLineID or 0)
end

local function CompareAlphabetical(a, b)
    local aName = string.lower(a.name or "")
    local bName = string.lower(b.name or "")
    if aName ~= bName then
        return aName < bName
    end
    return (a.skillLineID or 0) < (b.skillLineID or 0)
end

function Service:GetProfessionEntries(config)
    config = config or {}

    local entries, bySkillLine = BuildBaseEntries()
    AddRetailChildSkillLines(entries, bySkillLine)

    local filtered = {}
    for _, entry in ipairs(entries) do
        if config.showSecondary ~= false or entry.kind == "primary" then
            table.insert(filtered, entry)
        end
    end

    if config.sortPrimaryFirst == false then
        table.sort(filtered, CompareAlphabetical)
    else
        table.sort(filtered, ComparePrimaryFirst)
    end

    return filtered
end

function Service:GetPreferredEntry(entries, lastSkillLineID)
    if type(lastSkillLineID) == "number" then
        for _, entry in ipairs(entries) do
            if entry.skillLineID == lastSkillLineID then
                return entry
            end
        end
    end

    return entries[1]
end

local function OpenSpellBookFallback()
    local professionBookType = _G.BOOKTYPE_PROFESSION

    if type(ToggleProfessionsBook) == "function" then
        local ok = pcall(ToggleProfessionsBook)
        if ok then
            return true
        end
    end

    if C_SpellBook and type(C_SpellBook.OpenSpellBook) == "function" then
        local ok = pcall(C_SpellBook.OpenSpellBook, professionBookType)
        if ok then
            return true
        end
    end

    if type(ToggleSpellBook) == "function" then
        local ok = pcall(ToggleSpellBook, professionBookType)
        if ok then
            return true
        end
    end

    return false
end

function Service:OpenSpellBook()
    if InCombatLockdown and InCombatLockdown() then
        return { ok = false, reason = "combat" }
    end

    if OpenSpellBookFallback() then
        return { ok = true, reason = "spellbook_fallback" }
    end

    return { ok = false, reason = "no_api" }
end

local function OpenLegacyProfessionSpell(professionIndex)
    if type(GetProfessionInfo) ~= "function" or type(CastSpell) ~= "function" then
        return false
    end

    local spellOffset = select(6, GetProfessionInfo(professionIndex))
    if not spellOffset then
        return false
    end

    local ok = pcall(CastSpell, spellOffset + 1, _G.BOOKTYPE_PROFESSION)
    return ok
end

function Service:OpenEntry(entry)
    if InCombatLockdown and InCombatLockdown() then
        return { ok = false, reason = "combat" }
    end

    if not entry then
        return { ok = false, reason = "no_professions" }
    end

    if entry.skillLineID and C_TradeSkillUI and type(C_TradeSkillUI.OpenTradeSkill) == "function" then
        local ok = pcall(C_TradeSkillUI.OpenTradeSkill, entry.skillLineID)
        if ok then
            return { ok = true }
        end
    end

    if entry.professionIndex and OpenLegacyProfessionSpell(entry.professionIndex) then
        return { ok = true }
    end

    local fallback = self:OpenSpellBook()
    if fallback.ok then
        return fallback
    end

    return { ok = false, reason = "no_api" }
end
