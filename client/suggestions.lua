--[[ Chat-Vorschläge: Normalisierung, Merge, Rebuild → NUI ]]

local function normalizeCommandName(commandName)
    if type(commandName) ~= "string" then
        return nil
    end

    if commandName:sub(1, 1) == "/" then
        return commandName:sub(2):lower()
    end

    return commandName:lower()
end

function EcChat.NormalizeCommandName(commandName)
    return normalizeCommandName(commandName)
end

--- Platzhalter von ec_chat / Server-Listing — dürfen keine bessere Hilfe (z. B. ESX) überschreiben
local function isGenericFillHelp(help)
    if type(help) ~= "string" or help == "" then
        return true
    end
    return help == "Server-Befehl." or help == "Registrierter Befehl."
end

--- Frühere Versionen speicherten diesen Text als help — für Merge wie „leer“ behandeln.
local function normalizeStoredHelp(help)
    if type(help) ~= "string" then
        return ""
    end
    if help == "Keine Beschreibung vorhanden." then
        return ""
    end
    return help
end

function EcChat.UpsertSuggestion(commandName, helpText, params)
    local normalized = normalizeCommandName(commandName)
    if not normalized or normalized == "" then
        return
    end

    local suggestions = EcChat.client.suggestions
    local existing = suggestions[normalized]

    local exHelp = ""
    local exParams = nil
    if existing then
        exHelp = normalizeStoredHelp(existing.help)
        exParams = existing.params
    end

    local finalHelp = helpText
    if type(finalHelp) ~= "string" then
        finalHelp = ""
    end

    --- Leer: vorhandene (nicht-leere) Hilfe behalten; sonst intern "" (Anzeige-Text liefert die NUI).
    if finalHelp == "" then
        if exHelp ~= "" then
            finalHelp = exHelp
        else
            finalHelp = ""
        end
    elseif isGenericFillHelp(finalHelp) then
        --- Generischer Fill nur durch „echten“ bestehenden Text ersetzen (nicht durch andere Generika).
        if exHelp ~= "" and not isGenericFillHelp(exHelp) then
            finalHelp = exHelp
        end
    end

    local finalParams = params
    if type(finalParams) ~= "table" or #finalParams == 0 then
        if exParams and type(exParams) == "table" and #exParams > 0 then
            finalParams = exParams
        else
            finalParams = {}
        end
    end

    suggestions[normalized] = {
        name = normalized,
        help = finalHelp,
        params = finalParams
    }
end

function EcChat.RebuildSuggestions()
    local suggestions = EcChat.client.suggestions
    local list = {}

    for _, suggestion in pairs(suggestions) do
        list[#list + 1] = suggestion
    end

    table.sort(list, function(a, b)
        return a.name < b.name
    end)

    EcChat.SendUi("setSuggestions", list)
end

--- Nach Resource-Restart feuern ESX & Co. oft kein zweites chat:addSuggestion — KVP hält gemergte Vorschläge.
local SUGGESTIONS_KVP_KEY = "ec_chat_theme_suggestions_cache"

function EcChat.SaveSuggestionsToKvp()
    local suggestions = EcChat.client.suggestions
    local n = 0
    for _ in pairs(suggestions) do
        n = n + 1
    end
    if n == 0 then
        return
    end

    local list = {}
    for _, s in pairs(suggestions) do
        if type(s) == "table" and type(s.name) == "string" and s.name ~= "" then
            list[#list + 1] = {
                name = s.name,
                help = type(s.help) == "string" and s.help or "",
                params = type(s.params) == "table" and s.params or {},
            }
        end
    end

    table.sort(list, function(a, b)
        return a.name < b.name
    end)

    local ok, encoded = pcall(json.encode, list)
    if ok and type(encoded) == "string" and encoded ~= "" then
        SetResourceKvp(SUGGESTIONS_KVP_KEY, encoded)
    end
end

function EcChat.LoadSuggestionsFromKvp()
    local raw = GetResourceKvpString(SUGGESTIONS_KVP_KEY)
    if not raw or raw == "" then
        return
    end

    local ok, list = pcall(json.decode, raw)
    if not ok or type(list) ~= "table" then
        return
    end

    for _, entry in ipairs(list) do
        if type(entry) == "table" and type(entry.name) == "string" and entry.name ~= "" then
            EcChat.UpsertSuggestion(entry.name, entry.help, entry.params or {})
        end
    end
end

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end
    EcChat.SaveSuggestionsToKvp()
end)
