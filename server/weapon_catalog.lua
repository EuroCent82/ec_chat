--[[ Bei **Standard**/ESX: Katalog **`Config.SQL.tables.weapons`** wenn **`giveweapon`**-Autocomplete aktiv **oder**
    **`giveitemSuggestPrefix`** (bzw. Alt **`giveitemSuggestWeaponsPrefix`**) **`giveitem`** zur Waffentabelle umleitet.
    Bei **`Config.Inventory`** = **`ox_inventory`**: keine Waffentabelle für Autocomplete (Waffen = Items **`giveitem`). ]]

EcChat = EcChat or {}
EcChat.WeaponCatalogEntries = EcChat.WeaponCatalogEntries or {}

local function dbg(msg)
    if EcChat.SlashRelayDebugEnabled and EcChat.SlashRelayDebugEnabled() then
        print(("[ec_chat_theme][weapon_catalog] %s"):format(msg))
    end
end

local function clearTable(tbl)
    if type(tbl) ~= "table" then
        return
    end
    for k in pairs(tbl) do
        tbl[k] = nil
    end
end

function EcChat.SqlWeaponsTableConfigured()
    local sqlCfg = Config.SQL
    local w = sqlCfg and sqlCfg.tables and sqlCfg.tables.weapons
    if EcChat.SqlInventoryIsOx() or type(sqlCfg) ~= "table" or sqlCfg.enabled ~= true or type(w) ~= "table" then
        return false
    end
    local tblName = w.table
    local colName = w.name
    local colLabel = w.label
    return EcChat.ValidateSqlTableName(tblName)
        and EcChat.ValidateSqlTableName(colName)
        and EcChat.ValidateSqlTableName(colLabel)
end

function EcChat.WeaponCatalogNeedsLoad()
    if EcChat.SqlInventoryIsOx() then
        return false
    end
    if EcChat.SqlWeaponsTableConfigured() ~= true then
        return false
    end
    return EcChat.SqlWeaponsAutocompleteActive() == true or EcChat.GiveitemSuggestWeaponsPrefixNormalized() ~= nil
end

function EcChat.LoadWeaponCatalog()
    clearTable(EcChat.WeaponCatalogEntries)

    if not EcChat.WeaponCatalogNeedsLoad() then
        dbg("überspringe (ox_inventory, nicht konfiguriert oder kein weapons.autocomplete)")
        return
    end

    if not EcChat.MySqlDriverReady() then
        print("[ec_chat_theme] WeaponAutocomplete: konfigurierten MySQL-Treiber prüfen.")
        return
    end

    local wCfg = Config.SQL.tables.weapons
    local tbl = wCfg.table
    local colName = wCfg.name
    local colLabel = wCfg.label
    local sql = ("SELECT `%s` AS vn, `%s` AS lbl FROM `%s`"):format(colName, colLabel, tbl)

    EcChat.MySqlFetchAll(sql, function(rows)
        EcChat.WeaponCatalogEntries = EcChat.WeaponCatalogEntries or {}
        clearTable(EcChat.WeaponCatalogEntries)
        local n = 0
        if type(rows) ~= "table" then
            print("[ec_chat_theme] WeaponAutocomplete: leere oder ungültige Antwort.")
            return
        end
        for _, r in ipairs(rows) do
            local v = r.vn
            local lbl = r.lbl
            if type(v) == "string" and v ~= "" then
                n = n + 1
                EcChat.WeaponCatalogEntries[#EcChat.WeaponCatalogEntries + 1] = {
                    value = v,
                    valueLower = v:lower(),
                    label = (type(lbl) == "string" and lbl ~= "") and lbl or v,
                    labelLower = ((type(lbl) == "string" and lbl ~= "") and lbl or v):lower()
                }
            end
        end
        if n == 0 then
            print(("[ec_chat_theme] WeaponAutocomplete: 0 Einträge aus `%s`." ):format(tbl))
        else
            print(("[ec_chat_theme] WeaponAutocomplete: %d Einträge aus `%s`."):format(n, tbl))
        end
    end)
end

CreateThread(function()
    if not EcChat.WeaponCatalogNeedsLoad() then
        return
    end
    EcChat.WaitForMysqlDependency()
    Wait(600)
    EcChat.LoadWeaponCatalog()
end)
