--[[ Regeln aus Config.SQL für das NUI (ohne Tabellennamen) + Auslieferung der Server-Ergebnisse.
    Standard: **`giveitem`** (_items_) + optional Präfix-Bridge ⇒ **weapons**, optional **`giveweapon`**. Ox: **`giveitem`** nur **items**. ]]

EcChat = EcChat or {}

function EcChat.ItemAutocompleteUiRules()
    local sqlCfg = Config.SQL
    if type(sqlCfg) ~= "table" or sqlCfg.enabled ~= true then
        return nil
    end

    local cmds = {}

    local itemsTbl = sqlCfg.tables and sqlCfg.tables.items
    local ac = itemsTbl and itemsTbl.autocomplete
    if type(ac) == "table" and ac.enabled == true and type(ac.commands) == "table" then
        for _, row in ipairs(ac.commands) do
            if type(row) == "table" and type(row.aliases) == "table" and tonumber(row.completeParamIndex) then
                cmds[#cmds + 1] = {
                    aliases = row.aliases,
                    completeParamIndex = math.floor(row.completeParamIndex + 0.5)
                }
            end
        end
    end

    if EcChat.SqlWeaponsAutocompleteActive() then
        local weaponsTbl = sqlCfg.tables and sqlCfg.tables.weapons
        local wac = weaponsTbl and weaponsTbl.autocomplete
        if type(wac) == "table" and wac.enabled == true and type(wac.commands) == "table" then
            for _, row in ipairs(wac.commands) do
                if type(row) == "table" and type(row.aliases) == "table" and tonumber(row.completeParamIndex) then
                    cmds[#cmds + 1] = {
                        aliases = row.aliases,
                        completeParamIndex = math.floor(row.completeParamIndex + 0.5)
                    }
                end
            end
        end
    end

    if #cmds == 0 then
        return nil
    end

    local inv = EcChat.SqlInventoryFlavor()
    local giveitemSuggestWeaponsPrefix = EcChat.GiveitemSuggestWeaponsPrefixNormalized()
    return {
        enabled = true,
        minSuggestionChars = tonumber(sqlCfg.minSuggestionChars) or 1,
        itemSuggestDebounceMs = tonumber(sqlCfg.itemSuggestDebounceMs) or 180,
        maxSuggestionResults = tonumber(sqlCfg.maxSuggestionResults) or 30,
        commands = cmds,
        inventoryFlavor = inv,
        giveweaponAutocompleteConfigured = EcChat.SqlWeaponsAutocompleteActive(),
        giveitemSuggestWeaponsPrefix = giveitemSuggestWeaponsPrefix,
        oxInventoryMode = (inv == "ox_inventory"),
    }
end

RegisterNetEvent("ec_chat_theme:itemSuggestResponse", function(requestId, matches)
    if type(requestId) ~= "string" or type(matches) ~= "table" then
        matches = matches or {}
    end
    EcChat.SendUi("itemSuggestResult", {
        requestId = requestId,
        matches = matches,
    })
end)

RegisterNUICallback("itemSuggest", function(body, cb)
    if type(body) ~= "table" then
        body = {}
    end
    TriggerServerEvent("ec_chat_theme:itemSuggestRequest", body)
    if cb then
        cb({ ok = true })
    end
end)
