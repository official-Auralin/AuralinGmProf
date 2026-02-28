-- Thanks to Phanx for the localization tutorial:
-- https://phanx.net/addons/tutorials/localize

local _, ns = ...

local L = setmetatable({}, {
    __index = function(t, k)
        local v = tostring(k)
        rawset(t, k, v)
        return v
    end,
})

ns.L = L

local locale = GetLocale()

if locale == "enUS" or locale == "enGB" then
    return
end

if locale == "deDE" then
    L["Left-Click"] = "Linksklick"
    L["Right-Click"] = "Rechtsklick"
    L["Middle-Click"] = "Mittelklick"
    L["Primary"] = "Primaer"
    L["Secondary"] = "Sekundaer"
    L["No professions were found."] = "Keine Berufe gefunden."
    L["Action blocked while in combat."] = "Aktion im Kampf blockiert."
    L["Opened spellbook fallback."] = "Zauberbuch-Fallback geoeffnet."
    L["Unknown command. Type /agmp help"] = "Unbekannter Befehl. Tippe /agmp help"
    return
end

if locale == "itIT" then
    L["Left-Click"] = "Click Sinistro"
    L["Right-Click"] = "Click Destro"
    L["Middle-Click"] = "Click Centrale"
    L["Primary"] = "Primaria"
    L["Secondary"] = "Secondaria"
    L["No professions were found."] = "Nessuna professione trovata."
    L["Action blocked while in combat."] = "Azione bloccata in combattimento."
    L["Opened spellbook fallback."] = "Aperto fallback del grimorio."
    L["Unknown command. Type /agmp help"] = "Comando sconosciuto. Digita /agmp help"
    return
end
