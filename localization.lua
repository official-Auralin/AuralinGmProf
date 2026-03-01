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

    L["Focused"] = "Fokussiert"
    L["Lowest"] = "Niedrigste"
    L["Portfolio"] = "Portfolio"
    L["Count"] = "Anzahl"
    L["LOW"] = "NIEDRIG"

    L["DataText mode"] = "DataText-Modus"
    L["Available modes: %s"] = "Verfuegbare Modi: %s"
    L["Invalid DataText mode. Available: %s"] = "Ungueltiger DataText-Modus. Verfuegbar: %s"
    L["DataText mode set to %s."] = "DataText-Modus auf %s gesetzt."
    L["Usage: /agmp warn <number>"] = "Verwendung: /agmp warn <zahl>"
    L["Low concentration warning threshold set to %d."] = "Warnschwelle fuer niedrige Konzentration auf %d gesetzt."
    L["Concentration percentage display: ON"] = "Konzentrationsanzeige: EIN"
    L["Concentration percentage display: OFF"] = "Konzentrationsanzeige: AUS"
    L["DataText mode: %s"] = "DataText-Modus: %s"
    L["DataText Mode: %s"] = "DataText-Modus: %s"

    L["/agmp datatext focused|lowest|portfolio|count"] = "/agmp datatext focused|lowest|portfolio|count"
    L["/agmp warn <number> - low concentration alert threshold"] = "/agmp warn <zahl> - Warnschwelle fuer niedrige Konzentration"
    L["/agmp percent - toggle concentration percentage display"] = "/agmp percent - Konzentrationsanzeige umschalten"

    L["Modern profession launcher settings."] = "Moderne Einstellungen fuer den Berufsstarter."
    L["Click actions: /agmp left|right|middle open|tooltip|spellbook"] = "Klickaktionen: /agmp left|right|middle open|tooltip|spellbook"
    L["DataText mode: /agmp datatext focused|lowest|portfolio|count"] = "DataText-Modus: /agmp datatext focused|lowest|portfolio|count"
    L["Low concentration warning threshold: /agmp warn <number>"] = "Warnschwelle fuer niedrige Konzentration: /agmp warn <zahl>"
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

    L["Focused"] = "Focalizzata"
    L["Lowest"] = "Piu bassa"
    L["Portfolio"] = "Portafoglio"
    L["Count"] = "Conteggio"
    L["LOW"] = "BASSA"

    L["DataText mode"] = "Modalita DataText"
    L["Available modes: %s"] = "Modalita disponibili: %s"
    L["Invalid DataText mode. Available: %s"] = "Modalita DataText non valida. Disponibili: %s"
    L["DataText mode set to %s."] = "Modalita DataText impostata su %s."
    L["Usage: /agmp warn <number>"] = "Uso: /agmp warn <numero>"
    L["Low concentration warning threshold set to %d."] = "Soglia avviso concentrazione bassa impostata a %d."
    L["Concentration percentage display: ON"] = "Visualizzazione percentuale concentrazione: ON"
    L["Concentration percentage display: OFF"] = "Visualizzazione percentuale concentrazione: OFF"
    L["DataText mode: %s"] = "Modalita DataText: %s"
    L["DataText Mode: %s"] = "Modalita DataText: %s"

    L["/agmp datatext focused|lowest|portfolio|count"] = "/agmp datatext focused|lowest|portfolio|count"
    L["/agmp warn <number> - low concentration alert threshold"] = "/agmp warn <numero> - soglia avviso concentrazione bassa"
    L["/agmp percent - toggle concentration percentage display"] = "/agmp percent - alterna visualizzazione percentuale concentrazione"

    L["Modern profession launcher settings."] = "Impostazioni moderne del launcher professioni."
    L["Click actions: /agmp left|right|middle open|tooltip|spellbook"] = "Azioni click: /agmp left|right|middle open|tooltip|spellbook"
    L["DataText mode: /agmp datatext focused|lowest|portfolio|count"] = "Modalita DataText: /agmp datatext focused|lowest|portfolio|count"
    L["Low concentration warning threshold: /agmp warn <number>"] = "Soglia avviso concentrazione bassa: /agmp warn <numero>"
    return
end
