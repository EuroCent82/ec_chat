--[[ Server: Slash-Autocomplete — **`giveitem`** → **`tables.items`** (**optional**: Präfix trifft → **`tables.weapons`**, wenn **`giveitemSuggestPrefix`** am **`weapons`**-Objekt oder Alt‑**`giveitemSuggestWeaponsPrefix`** unter **`items.autocomplete`**).
    **`giveweapon`** → **`tables.weapons`** nur wenn `weapons.autocomplete` aktiv (**Standard**/ESX).
    Bei **`ox_inventory`** bleiben Waffennamen im **Items**-Katalog.
    Groß-/Kleinschreibung im Präfix wird normalisiert (z. B. **`WEAPON_*`** → **`weapon_*`**). ]]

EcChat = EcChat or {}

local function normSlashCmd(alias)
    if type(alias) ~= "string" then
        return ""
    end
    return alias:lower():gsub("^/+", ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function prefixSanitize(s)
    if type(s) ~= "string" then
        return ""
    end
    s = s:lower():sub(1, 48):gsub("[^%w_%-]", "")
    return s
end

function EcChat.ItemSuggestAceAllowed(playerSrc, aliasList)
    local grpList = Config.SQL and Config.SQL.itemSuggestAceGroups
    if type(grpList) == "table" then
        for _, g in ipairs(grpList) do
            if type(g) == "string" and g ~= "" and IsPlayerAceAllowed(playerSrc, ("group.%s"):format(g)) then
                return true
            end
        end
    end

    if type(aliasList) ~= "table" then
        return false
    end
    for _, a in ipairs(aliasList) do
        local n = normSlashCmd(a)
        if n ~= "" and IsPlayerAceAllowed(playerSrc, ("command.%s"):format(n)) then
            return true
        end
    end
    return false
end

--- @return integer|nil completeParamIndex, table|nil aliasList für ACE (**`giveitem`**, …).
function EcChat.ResolveItemAutocompleteRule(cmdLower)
    local sqlCfg = Config.SQL
    local items = sqlCfg and sqlCfg.tables and sqlCfg.tables.items
    local ac = items and items.autocomplete
    if type(ac) ~= "table" or type(ac.commands) ~= "table" then
        return nil, nil
    end

    local c = normSlashCmd(cmdLower)
    if c == "" then
        return nil, nil
    end

    for _, row in ipairs(ac.commands) do
        local al = row.aliases
        if type(al) == "table" then
            for _, alias in ipairs(al) do
                if normSlashCmd(alias) == c then
                    local idx = tonumber(row.completeParamIndex)
                    return idx, al
                end
            end
        end
    end
    return nil, nil
end

--- Nur **Standard**/ESX: **`giveweapon`**, **`give_weapon`** usw.
--- @return integer|nil completeParamIndex, table|nil aliasList
function EcChat.ResolveWeaponAutocompleteRule(cmdLower)
    if EcChat.SqlInventoryIsOx() then
        return nil, nil
    end

    local sqlCfg = Config.SQL
    local weapons = sqlCfg and sqlCfg.tables and sqlCfg.tables.weapons
    local ac = weapons and weapons.autocomplete
    if type(ac) ~= "table" or ac.enabled ~= true or type(ac.commands) ~= "table" then
        return nil, nil
    end

    local c = normSlashCmd(cmdLower)
    if c == "" then
        return nil, nil
    end

    for _, row in ipairs(ac.commands) do
        local al = row.aliases
        if type(al) == "table" then
            for _, alias in ipairs(al) do
                if normSlashCmd(alias) == c then
                    local idx = tonumber(row.completeParamIndex)
                    return idx, al
                end
            end
        end
    end
    return nil, nil
end

local function tierForEntry(entry, prefix)
    if prefix == "" then
        return 100, ""
    end
    local vn = entry.valueLower
    local ln = entry.labelLower
    if vn == prefix then
        return 0, vn
    end
    if vn:find(prefix, 1, true) == 1 then
        return 1, vn
    end
    if ln:find(prefix, 1, true) == 1 then
        return 2, ln
    end
    if vn:find(prefix, 1, true) ~= nil then
        return 3, vn
    end
    if ln:find(prefix, 1, true) ~= nil then
        return 4, ln
    end
    return nil, ""
end

function EcChat.BuildCatalogSuggestPayload(pool, prefixNormalized, limit, minChars)
    local pref = prefixNormalized or ""

    if type(pool) ~= "table" then
        return {}
    end

    if pref == "" then
        local tmp = {}
        for _, entry in ipairs(pool) do
            tmp[#tmp + 1] = entry
        end
        table.sort(tmp, function(a, b)
            return (a.label or a.value):lower() < (b.label or b.value):lower()
        end)
        local out = {}
        local cap = math.min(limit or 30, #tmp)
        for i = 1, cap do
            local e = tmp[i]
            out[#out + 1] = { value = e.value, label = e.label }
        end
        return out
    end

    local minC = tonumber(minChars) or 1
    if minC > 0 and #pref < minC then
        return {}
    end

    local scored = {}
    for _, entry in ipairs(pool) do
        local tier, _ = tierForEntry(entry, pref)
        if tier ~= nil then
            scored[#scored + 1] = {
                tier = tier,
                value = entry.value,
                label = entry.label,
                sortKey = (entry.value or ""):lower()
            }
        end
    end

    table.sort(scored, function(a, b)
        if a.tier ~= b.tier then
            return a.tier < b.tier
        end
        return a.sortKey < b.sortKey
    end)

    local out = {}
    local maxN = tonumber(limit) or 30
    for i = 1, math.min(maxN, #scored) do
        local r = scored[i]
        out[#out + 1] = { value = r.value, label = r.label }
    end
    return out
end

function EcChat.BuildItemSuggestPayload(prefixNormalized, limit, minChars)
    return EcChat.BuildCatalogSuggestPayload(EcChat.ItemCatalogEntries, prefixNormalized, limit, minChars)
end

RegisterNetEvent("ec_chat_theme:itemSuggestRequest", function(payload)
    local src = source
    if type(src) ~= "number" or src <= 0 then
        return
    end

    if type(payload) ~= "table" then
        return
    end

    local rid = payload.requestId
    if type(rid) == "number" then
        rid = tostring(math.floor(rid + 0.5))
    elseif type(rid) ~= "string" then
        rid = tostring(rid or "")
    end
    if type(rid) ~= "string" or rid == "" or #rid > 96 then
        return
    end

    local sqlCfg = Config.SQL
    if type(sqlCfg) ~= "table" or sqlCfg.enabled ~= true then
        TriggerClientEvent("ec_chat_theme:itemSuggestResponse", src, rid, {})
        return
    end

    local itemsTbl = sqlCfg.tables and sqlCfg.tables.items
    local itemsAc = itemsTbl and itemsTbl.autocomplete
    local itemsAutocompleteOn =
        type(itemsAc) == "table"
        and itemsAc.enabled == true
        and type(itemsAc.commands) == "table"

    if not itemsAutocompleteOn and not EcChat.SqlWeaponsAutocompleteActive() then
        TriggerClientEvent("ec_chat_theme:itemSuggestResponse", src, rid, {})
        return
    end

    local cmdRaw = payload.cmd or payload.command
    local argIx = tonumber(payload.argIndex or payload.arg_index or payload.argindex)

    local wParam, weaponAliases = EcChat.ResolveWeaponAutocompleteRule(cmdRaw)
    local iParam, itemAliases = EcChat.ResolveItemAutocompleteRule(cmdRaw)

    local paramIdx = nil
    local aliasList = nil
    local pool = EcChat.ItemCatalogEntries

    if wParam and argIx and type(weaponAliases) == "table" then
        if math.floor(wParam + 0.5) == math.floor(argIx + 0.5) then
            paramIdx = wParam
            aliasList = weaponAliases
            pool = EcChat.WeaponCatalogEntries
        end
    end

    if paramIdx == nil and iParam and argIx and type(itemAliases) == "table" then
        if math.floor(iParam + 0.5) == math.floor(argIx + 0.5) then
            paramIdx = iParam
            aliasList = itemAliases
            pool = EcChat.ItemCatalogEntries
        end
    end

    if not paramIdx or not aliasList then
        if Config.Debug == true then
            print(
                ("[ec_chat_theme][itemSuggest] kein Treffer (cmd=%s argIx=%s iParam=%s wParam=%s)"):format(
                    tostring(cmdRaw),
                    tostring(argIx),
                    tostring(iParam),
                    tostring(wParam)
                )
            )
        end
        TriggerClientEvent("ec_chat_theme:itemSuggestResponse", src, rid, {})
        return
    end

    if not EcChat.ItemSuggestAceAllowed(src, aliasList) then
        if Config.Debug == true then
            print(
                ("[ec_chat_theme][itemSuggest] ACE verweigert (src=%s cmd=%s)"):format(tostring(src), tostring(cmdRaw))
            )
        end
        TriggerClientEvent("ec_chat_theme:itemSuggestResponse", src, rid, {})
        return
    end

    local prefixRaw = payload.prefix
    local prefSan = prefixSanitize(prefixRaw)
    local lim = tonumber(sqlCfg.maxSuggestionResults) or 30
    local minC = tonumber(sqlCfg.minSuggestionChars) or 1

    --- Sonderweg Standard: `/giveitem` — Präfix passt ⇒ Vorschläge aus **`tables.weapons`** (**`giveitemSuggestPrefix`** / Legacy **`giveitemSuggestWeaponsPrefix`**).
    local bridgePref = EcChat.GiveitemSuggestWeaponsPrefixNormalized()
    if bridgePref
        and pool == EcChat.ItemCatalogEntries
        and prefSan ~= ""
        and prefSan:find(bridgePref, 1, true) == 1
        and EcChat.SqlWeaponsTableConfigured()
    then
        local wpool = EcChat.WeaponCatalogEntries
        if type(wpool) == "table" and #wpool > 0 then
            pool = wpool
        end
    end

    if type(pool) ~= "table" then
        pool = {}
    end

    local matches = EcChat.BuildCatalogSuggestPayload(pool, prefSan, lim, minC)
    if Config.Debug == true then
        local poolName = pool == EcChat.WeaponCatalogEntries and "weapons" or "items"
        print(
            ("[ec_chat_theme][itemSuggest] ok pool=%s n=%s prefix=%s"):format(
                poolName,
                tostring(#matches),
                tostring(prefSan)
            )
        )
    end
    TriggerClientEvent("ec_chat_theme:itemSuggestResponse", src, rid, matches)
end)
