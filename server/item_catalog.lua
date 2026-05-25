--[[ Item-Katalog aus MySQL über `server/mysql_adapter.lua` (**Config.MySQL**). ]]

EcChat = EcChat or {}
EcChat.ItemCatalogReady = EcChat.ItemCatalogReady or false
EcChat.ItemCatalogEntries = EcChat.ItemCatalogEntries or {}

local function dbg(msg)
    if EcChat.SlashRelayDebugEnabled and EcChat.SlashRelayDebugEnabled() then
        print(("[ec_chat_theme][item_catalog] %s"):format(msg))
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

local function validateIdentifier(id)
    return type(id) == "string" and id ~= "" and id:find("^[%w_]+$") ~= nil
end

--- Optional zweite Tabelle (**nur ox_inventory**): Waffen-Codes stehen oft **nicht** in `items.name` — dann zusätzlich laden (z. B. **`wepaons`**, **`weapons`**).
function EcChat.ItemsWeaponNameMergeCfg()
    if not EcChat.SqlInventoryIsOx() then
        return nil
    end
    local items = Config.SQL and Config.SQL.tables and Config.SQL.tables.items
    local m = items and items.weaponNameMerge
    if m == false then
        return nil
    end
    if type(m) ~= "table" then
        return nil
    end
    if
        validateIdentifier(m.table)
        and validateIdentifier(m.name)
        and validateIdentifier(m.label)
    then
        return m
    end
    return nil
end

function EcChat.ItemCatalogNeedsLoad()
    local sqlCfg = Config.SQL
    local items = sqlCfg and sqlCfg.tables and sqlCfg.tables.items
    local ac = items and items.autocomplete
    if type(sqlCfg) ~= "table" or sqlCfg.enabled ~= true then
        return false
    end
    if type(ac) ~= "table" or ac.enabled ~= true then
        return false
    end
    local tblName = items and items.table
    local colName = items and items.name
    local colLabel = items and items.label
    return validateIdentifier(tblName) and validateIdentifier(colName) and validateIdentifier(colLabel)
end

function EcChat.LoadItemCatalog()
    clearTable(EcChat.ItemCatalogEntries)

    if not EcChat.ItemCatalogNeedsLoad() then
        dbg("überspringe (SQL/items.autocomplete nicht aktiv)")
        EcChat.ItemCatalogReady = true
        return
    end

    if not EcChat.MySqlDriverReady() then
        print(
            "[ec_chat_theme] ItemAutocomplete: konfigurierten MySQL-Treiber prüfen — Resource nicht gestartet oder Exports/MySQL.Async fehlt (Config.MySQL in config.lua).")
        EcChat.ItemCatalogReady = true
        return
    end

    local items = Config.SQL.tables.items
    local tbl = items.table
    local colName = items.name
    local colLabel = items.label
    local sql = ("SELECT `%s` AS vn, `%s` AS lbl FROM `%s`"):format(colName, colLabel, tbl)

    EcChat.MySqlFetchAll(sql, function(rows)
        EcChat.ItemCatalogEntries = EcChat.ItemCatalogEntries or {}
        clearTable(EcChat.ItemCatalogEntries)
        local n = 0
        if type(rows) ~= "table" then
            print("[ec_chat_theme] ItemAutocomplete: leere oder ungültige Antwort — DB/Tabelle prüfen.")
            EcChat.ItemCatalogReady = true
            return
        end
        for _, r in ipairs(rows) do
            local v = r.vn
            local lbl = r.lbl
            if type(v) == "string" and v ~= "" then
                n = n + 1
                EcChat.ItemCatalogEntries[#EcChat.ItemCatalogEntries + 1] = {
                    value = v,
                    valueLower = v:lower(),
                    label = (type(lbl) == "string" and lbl ~= "") and lbl or v,
                    labelLower = ((type(lbl) == "string" and lbl ~= "") and lbl or v):lower()
                }
            end
        end

        local mergeCfg = EcChat.ItemsWeaponNameMergeCfg()
        if not mergeCfg then
            EcChat.ItemCatalogReady = true
            if n == 0 then
                print(("[ec_chat_theme] ItemAutocomplete: 0 Einträge aus `%s` — Tabelle/Leer oder Spalten prüfen."):format(tbl))
            else
                local oxHint = EcChat.SqlInventoryIsOx()
                        and " — ox_inventory: ohne `weaponNameMerge` gilt nur `items`."
                    or ""
                print(("[ec_chat_theme] ItemAutocomplete: %d Einträge aus `%s`.%s"):format(n, tbl, oxHint))
            end
            return
        end

        local sql2 = ("SELECT `%s` AS vn, `%s` AS lbl FROM `%s`"):format(
            mergeCfg.name,
            mergeCfg.label,
            mergeCfg.table
        )
        EcChat.MySqlFetchAll(sql2, function(rows2)
            local seen = {}
            for _, e in ipairs(EcChat.ItemCatalogEntries) do
                seen[e.valueLower] = true
            end
            local m = 0
            if type(rows2) == "table" then
                for _, r in ipairs(rows2) do
                    local v = r.vn
                    local lbl = r.lbl
                    if type(v) == "string" and v ~= "" then
                        local vl = v:lower()
                        if not seen[vl] then
                            seen[vl] = true
                            m = m + 1
                            EcChat.ItemCatalogEntries[#EcChat.ItemCatalogEntries + 1] = {
                                value = v,
                                valueLower = vl,
                                label = (type(lbl) == "string" and lbl ~= "") and lbl or v,
                                labelLower = ((type(lbl) == "string" and lbl ~= "") and lbl or v):lower()
                            }
                        end
                    end
                end
            end
            EcChat.ItemCatalogReady = true
            if n == 0 and m == 0 then
                print(
                    ("[ec_chat_theme] ItemAutocomplete: 0 Einträge aus `%s` / Merge `%s` — prüfen."):format(tbl, mergeCfg.table)
                )
            else
                print(
                    ("[ec_chat_theme] ItemAutocomplete: %d aus `%s` + %d aus `%s` (ox · `weaponNameMerge`)."):format(
                        n,
                        tbl,
                        m,
                        mergeCfg.table
                    )
                )
            end
        end)
    end)
end

CreateThread(function()
    if not EcChat.ItemCatalogNeedsLoad() then
        return
    end
    EcChat.WaitForMysqlDependency()
    Wait(400)
    EcChat.LoadItemCatalog()
end)
