--[[ Staff-Chat: Aliase + Berechtigung (ACE, ESX-Gruppe, txAdmin-Panel). ]]

EcChat = EcChat or {}

local function staffCfg()
    return Config.StaffChat
end

local function cfgGroups(cfg)
    local groups = cfg and cfg.groups
    if type(groups) ~= "table" then
        return {}
    end
    return groups
end

local function cfgPermissionAces(cfg)
    local raw = cfg and cfg.permissionAces
    if type(raw) == "table" and #raw > 0 then
        return raw
    end
    if raw == false then
        return {}
    end
    return { "command" }
end

local function trustEsxGroup(cfg)
    if cfg and cfg.trustEsxGroup == false then
        return false
    end
    return true
end

local function trustTxAdmin(cfg)
    if cfg and cfg.trustTxAdmin == false then
        return false
    end
    return true
end

--- Normalisiert Config.StaffChat.command | .commands (String oder Liste), ohne Slash, lowercase.
function EcChat.GetStaffChatAliases()
    local cfg = staffCfg()
    if type(cfg) ~= "table" or cfg.enabled ~= true then
        return {}
    end

    local raw = cfg.command
    if raw == nil then
        raw = cfg.commands
    end

    local out = {}

    local function pushOne(s)
        if type(s) ~= "string" then
            return
        end
        local n = s:lower():gsub("^/", ""):match("^(%S+)") or ""
        if n ~= "" then
            out[#out + 1] = n
        end
    end

    if type(raw) == "string" then
        pushOne(raw)
    elseif type(raw) == "table" then
        for _, entry in ipairs(raw) do
            pushOne(entry)
        end
    end

    return out
end

--- Detaillierte Prüfung (Server: /checkgroup-Log). `paths` = { { ok, label }, … }.
function EcChat.StaffMembershipChecks(playerSrc)
    local paths = {}
    local matched = false

    if type(playerSrc) ~= "number" or playerSrc <= 0 then
        return { matched = false, paths = paths }
    end

    local cfg = staffCfg()
    if type(cfg) ~= "table" or cfg.enabled ~= true then
        paths[#paths + 1] = { ok = false, label = "StaffChat.enabled = false" }
        return { matched = false, paths = paths }
    end

    local function hit(label)
        matched = true
        paths[#paths + 1] = { ok = true, label = label }
    end

    local function miss(label)
        paths[#paths + 1] = { ok = false, label = label }
    end

    if IsDuplicityVersion() and trustTxAdmin(cfg) and EcChat.IsTxAdminAuthenticated then
        if EcChat.IsTxAdminAuthenticated(playerSrc) then
            hit("txAdmin-Panel (adminAuth / F4-Menü)")
        else
            miss("txAdmin-Panel: nicht authentifiziert (F4-Menü öffnen oder admins.json)")
        end
    end

    if IsDuplicityVersion() and trustEsxGroup(cfg) then
        if GetResourceState("es_extended") == "started" then
            local ok, ESX = pcall(function()
                return exports["es_extended"]:getSharedObject()
            end)
            if ok and ESX then
                local xPlayer = ESX.GetPlayerFromId(playerSrc)
                if xPlayer and xPlayer.getGroup then
                    local grp = xPlayer.getGroup()
                    if type(grp) == "string" and grp ~= "" then
                        local gl = grp:lower()
                        local inList = false
                        for _, g in ipairs(cfgGroups(cfg)) do
                            if type(g) == "string" and g:lower() == gl then
                                inList = true
                                break
                            end
                        end
                        if inList then
                            hit(('ESX getGroup() = "%s" (z.B. /setgroup admin)'):format(grp))
                        else
                            miss(('ESX getGroup() = "%s" (nicht in StaffChat.groups)'):format(grp))
                        end
                    else
                        miss("ESX getGroup() leer")
                    end
                else
                    miss("ESX xPlayer nicht geladen")
                end
            else
                miss("ESX getSharedObject fehlgeschlagen")
            end
        else
            miss("ESX nicht gestartet (trustEsxGroup)")
        end
    end

    local aceAllow = cfg.aceAllow
    if type(aceAllow) == "table" then
        for _, p in ipairs(aceAllow) do
            if type(p) == "string" and p ~= "" then
                if IsPlayerAceAllowed(playerSrc, p) then
                    hit(("aceAllow: %s"):format(p))
                else
                    miss(("aceAllow: %s"):format(p))
                end
            end
        end
    end

    for _, ace in ipairs(cfgPermissionAces(cfg)) do
        if type(ace) == "string" and ace ~= "" then
            if IsPlayerAceAllowed(playerSrc, ace) then
                hit(("permissionAces: %s (typisch group.admin / group.txadmin in server.cfg)"):format(ace))
            else
                miss(("permissionAces: %s"):format(ace))
            end
        end
    end

    for _, g in ipairs(cfgGroups(cfg)) do
        if type(g) == "string" and g ~= "" then
            local ace = ("group.%s"):format(g)
            if IsPlayerAceAllowed(playerSrc, ace) then
                hit(("ACE-Objekt %s (selten; oft unzuverlässig für Mitgliedschaft)"):format(ace))
            else
                miss(("ACE-Objekt %s (≠ Mitgliedschaft in group.%s)"):format(ace, g))
            end
        end
    end

    return { matched = matched, paths = paths }
end

function EcChat.IsStaffChatMember(playerSrc)
    return EcChat.StaffMembershipChecks(playerSrc).matched
end

--- Prüft ob die Zeile mit einem Staff-Alias beginnt (roher Spielertext inkl. /).
function EcChat.MessageStartsWithStaffAlias(text)
    if type(text) ~= "string" then
        return nil
    end
    local t = text:match("^%s*(.*)$") or ""
    local lower = t:lower()
    if lower:sub(1, 1) ~= "/" then
        return nil
    end
    for _, alias in ipairs(EcChat.GetStaffChatAliases()) do
        local pref = "/" .. alias
        if lower == pref or lower:sub(1, #pref + 1) == pref .. " " then
            return alias, t
        end
    end
    return nil
end

--- Team-Broadcast-Zeile (nicht `[Staff-Chat]`-Hinweise an den Absender).
function EcChat.IsStaffShapedChatMessage(message)
    if type(message) ~= "table" then
        return false
    end
    if message.template == "staff" or message.channel == "staff" then
        return true
    end
    local args = message.args
    if type(args) == "table" and type(args[1]) == "string" then
        return args[1]:sub(1, 7) == "[Staff]"
    end
    return false
end

--- Nur Client: darf Staff-Zeilen in der NUI-Historie anzeigen?
function EcChat.ClientMayDisplayStaffChat()
    if IsDuplicityVersion() then
        return false
    end
    EcChat.client = EcChat.client or {}
    local lp = EcChat.client.lastPermissions
    return type(lp) == "table" and lp.canUseStaffChat == true
end
