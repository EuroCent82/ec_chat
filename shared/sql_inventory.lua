--[[ SQL-Autocomplete unterscheidet Standard-ESX (giveweapon + giveitem) von ox_inventory (nur giveitem für Waffen). ]]

EcChat = EcChat or {}

--- **`nil`** / **`""`** / **`"standard"`** / **`"esx"`** ⇒ klassisches Verhalten (**`giveweapon`** → **`tables.weapons`**).
--- **`"ox_inventory"`** (auch **`ox`**, **`ox-inventory`**) ⇒ Waffen laufen wie Items über **`giveitem`** (**`tables.weapons`** wird für Vorschläge nicht genutzt).
function EcChat.SqlInventoryFlavor()
    local raw = rawget(Config, "Inventory")
    if raw == nil or raw == false then
        return "standard"
    end
    if type(raw) ~= "string" then
        return "standard"
    end
    local s = raw:lower():gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", ""):gsub("-", "_")
    if s == "" or s == "standard" or s == "esx" then
        return "standard"
    end
    if s == "ox_inventory" or s == "oxinv" or s == "ox" then
        return "ox_inventory"
    end
    return "standard"
end

function EcChat.SqlInventoryIsOx()
    return EcChat.SqlInventoryFlavor() == "ox_inventory"
end

--- Gibt es aktiv **`giveweapon`**-Autocomplete-Reihen? (nur **Standard**-Betrieb).
function EcChat.SqlWeaponsAutocompleteActive()
    if EcChat.SqlInventoryIsOx() then
        return false
    end
    local sqlCfg = rawget(Config, "SQL")
    local weapons = sqlCfg and sqlCfg.tables and sqlCfg.tables.weapons
    local ac = weapons and weapons.autocomplete
    if type(ac) ~= "table" or ac.enabled ~= true or type(ac.commands) ~= "table" then
        return false
    end
    for _, row in ipairs(ac.commands) do
        if type(row) == "table" and type(row.aliases) == "table" and tonumber(row.completeParamIndex) then
            return true
        end
    end
    return false
end

local function sanitizeSuggestPrefix(raw)
    if type(raw) ~= "string" then
        return nil
    end
    local s = raw:lower():sub(1, 48):gsub("[^%w_%-]", "")
    if s == "" then
        return nil
    end
    return s
end

--- Optional **Standard**/ESX (**nicht** Ox): Slash **`giveitem`** — wenn der Suchstring nach Bereinigung **mit diesem Präfix beginnt**, kommen Dropdown‑Einträge aus **`tables.weapons`** (**`tables.weapons.table`** …), nicht aus **`tables.items`**.
--- **Konfigreihenfolge:** zuerst **`tables.weapons.giveitemSuggestPrefix`** (empfohlen, steht dort neben dem DB‑Tabellenname). Sonst Fallback **`tables.items.autocomplete.giveitemSuggestWeaponsPrefix`** (**Alt‑Key** — bitte migrieren).
--- **`giveitemSuggestPrefix`:** Schlüssel weg / **`nil`** ⇒ aus (außer Alt‑Fallback). **`false`** ⇒ **Aus**, kein Fallback. **`true`** ⇒ **`"weapon_"`**. **`"weapon_"`** o. ä.
function EcChat.GiveitemSuggestWeaponsPrefixNormalized()
    if EcChat.SqlInventoryIsOx() then
        return nil
    end

    local sqlCfg = rawget(Config, "SQL")
    local weapons = sqlCfg and sqlCfg.tables and sqlCfg.tables.weapons
    if type(weapons) == "table" and weapons.giveitemSuggestPrefix ~= nil then
        local wRaw = weapons.giveitemSuggestPrefix
        if wRaw == false then
            return nil
        end
        if wRaw == true then
            return "weapon_"
        end
        return sanitizeSuggestPrefix(wRaw)
    end

    local items = sqlCfg and sqlCfg.tables and sqlCfg.tables.items
    local ac = items and items.autocomplete
    if type(ac) ~= "table" then
        return nil
    end
    local raw = ac.giveitemSuggestWeaponsPrefix
    if raw == true then
        return "weapon_"
    end
    return sanitizeSuggestPrefix(raw)
end
