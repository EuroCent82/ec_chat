--[[ `/checkgroup` — FiveM-ACE `group.*` aus `Config.StaffChat.groups` (nicht txAdmin-Panel-`setgroup`). ]]

EcChat = EcChat or {}

local function checkGroupCfg()
    local c = rawget(Config, "CheckGroup")
    return type(c) == "table" and c or {}
end

--- **`Config.CheckGroup.enabled`** — Standard **`true`**; **`false`** = kein `/checkgroup` (Server lehnt Event ab).
function EcChat.IsCheckGroupEnabled()
    return checkGroupCfg().enabled ~= false
end

function EcChat.CheckGroupServerLogEnabled()
    local c = checkGroupCfg()
    if c.serverLog == false then
        return false
    end
    if c.serverLog == true then
        return true
    end
    return rawget(Config, "Debug") == true
end

local function checkGroupAlsoChat()
    return checkGroupCfg().alsoChat == true
end

local function showLicenseHint()
    local c = checkGroupCfg()
    if c.showLicenseHint == false then
        return false
    end
    return true
end

local function primaryLicense(playerSrc)
    local ids = GetPlayerIdentifiers(playerSrc)
    if type(ids) ~= "table" then
        return nil
    end
    for _, id in ipairs(ids) do
        if type(id) == "string" and id:find("^license:") then
            return id
        end
    end
    for _, id in ipairs(ids) do
        if type(id) == "string" and id:find("^license2:") then
            return id
        end
    end
    return ids[1]
end

--- `license:hex` aus GetPlayerIdentifiers → `identifier.license:hex` für **server.cfg** / ACE.
function EcChat.AcePrincipalFromIdentifier(id)
    if type(id) ~= "string" or id == "" then
        return nil
    end
    if id:find("^identifier%.") then
        return id
    end
    local typ, val = id:match("^([^:]+):(.+)$")
    if typ and val and typ ~= "" and val ~= "" then
        return ("identifier.%s:%s"):format(typ, val)
    end
    return id
end

local function serverCfgPrincipalLines(playerSrc)
    local lines = { "add_ace group.admin command allow" }
    local seen = {}
    local ids = GetPlayerIdentifiers(playerSrc)
    if type(ids) ~= "table" then
        return lines
    end
    for _, id in ipairs(ids) do
        if type(id) == "string" then
            local p = EcChat.AcePrincipalFromIdentifier(id)
            if p and (id:find("^license:") or id:find("^license2:") or id:find("^fivem:")) and not seen[p] then
                seen[p] = true
                lines[#lines + 1] = ("add_principal %s group.admin"):format(p)
            end
        end
    end
    if #lines == 1 then
        lines[#lines + 1] = "add_principal identifier.license:DEINE_LICENSE group.admin"
    end
    return lines
end

--- Vollständiger Diagnose-Block in die Server-Konsole (txAdmin / FXServer).
function EcChat.LogCheckGroupToServer(requesterSrc, targetPid, report)
    if not EcChat.CheckGroupServerLogEnabled() or type(report) ~= "table" then
        return
    end

    local function line(msg)
        print(("[ec_chat_theme][checkgroup] %s"):format(msg))
    end

    line("========== Diagnose (Server) ==========")
    line(("Anfrage von source=%s → Ziel source=%s (%s)"):format(
        tostring(requesterSrc),
        tostring(targetPid),
        tostring(report.playerName)
    ))
    line(("Kurz: %s"):format(tostring(report.summary)))

    if type(report.license) == "string" then
        line(("License (Hinweis): %s"):format(report.license))
    end

    local ids = GetPlayerIdentifiers(targetPid)
    if type(ids) == "table" then
        line("— Alle Identifier des Ziels —")
        for i, id in ipairs(ids) do
            line(("  [%d] %s"):format(i, id))
        end
    end

    line("— Staff-Berechtigung (alle Pfade) —")
    if type(report.membershipPaths) == "table" then
        for _, row in ipairs(report.membershipPaths) do
            line(("  [%s] %s"):format(row.ok and "JA" or "NEIN", row.label))
        end
    end

    line(("IsStaffChatMember (gesamt): %s"):format(report.isStaffMember and "JA" or "NEIN"))
    line(("StaffChat.enabled: %s"):format(report.staffChatEnabled and "true" or "false"))

    if type(report.detail) == "string" and report.detail ~= "" then
        line("— Notify-Detail (wie beim Client) —")
        for part in report.detail:gmatch("[^\n]+") do
            line(("  %s"):format(part))
        end
    end

    if type(report.serverCfgHint) == "table" then
        line("— In server.cfg eintragen (danach Server-Neustart + Reconnect) —")
        for _, cfgLine in ipairs(report.serverCfgHint) do
            line(("  %s"):format(cfgLine))
        end
    end

    line("Hinweis: txAdmin-Konsole setgroup ≠ ESX /setgroup — siehe membershipPaths oben.")
    line("========================================")
end

function EcChat.BuildCheckGroupReport(targetPid)
    if type(targetPid) ~= "number" or targetPid <= 0 then
        return nil
    end

    local name = GetPlayerName(targetPid)
    local membership = EcChat.StaffMembershipChecks(targetPid)
    local report = {
        targetId = targetPid,
        playerName = (type(name) == "string" and name ~= "") and name or ("#" .. tostring(targetPid)),
        isStaffMember = membership.matched,
        membershipPaths = membership.paths or {},
        staffChatEnabled = type(Config.StaffChat) == "table" and Config.StaffChat.enabled == true,
    }

    local license = showLicenseHint() and primaryLicense(targetPid) or nil
    if license then
        report.license = license
    end

    local teamLabel = report.isStaffMember and "ja" or "nein"
    local hitLabels = {}
    for _, row in ipairs(report.membershipPaths) do
        if row.ok then
            hitLabels[#hitLabels + 1] = row.label
        end
    end

    local groupsLabel
    if #hitLabels > 0 then
        groupsLabel = table.concat(hitLabels, " · ")
    else
        groupsLabel = "keine"
    end

    report.summary = ("Team-Chat: %s · Treffer: %s"):format(teamLabel, groupsLabel)

    local detail = {}
    for _, row in ipairs(report.membershipPaths) do
        detail[#detail + 1] = ("[%s] %s"):format(row.ok and "ja" or "nein", row.label)
    end

    report.serverCfgHint = serverCfgPrincipalLines(targetPid)

    if not report.isStaffMember then
        detail[#detail + 1] = ""
        detail[#detail + 1] = "Euro-Test server.cfg: du bist oft in group.txadmin (nicht group.admin)."
        detail[#detail + 1] = "permissionAces command sollte JA sein, wenn add_principal … group.txadmin gesetzt ist."
        detail[#detail + 1] = "ESX /setgroup admin → trustEsxGroup muss JA zeigen."
        if #report.serverCfgHint > 0 then
            detail[#detail + 1] = "Falls ACE fehlt — server.cfg:"
            for _, cfgLine in ipairs(report.serverCfgHint) do
                detail[#detail + 1] = ("  %s"):format(cfgLine)
            end
        end
    end

    if not report.staffChatEnabled then
        detail[#detail + 1] = "Hinweis: Config.StaffChat.enabled = false."
    end

    report.detail = table.concat(detail, "\n")

    return report
end

local function pushChatLines(toSrc, report)
    if not checkGroupAlsoChat() or not report then
        return
    end
    TriggerClientEvent("chat:addMessage", toSrc, {
        color = { 180, 205, 245 },
        args = { "[checkgroup]", report.summary },
    })
end

RegisterNetEvent("ec_chat_theme:requestCheckGroup", function(payload)
    local src = source
    if type(src) ~= "number" or src <= 0 then
        return
    end

    if not EcChat.IsCheckGroupEnabled() then
        local err = {
            error = true,
            summary = "Diagnose /checkgroup ist deaktiviert (Config.CheckGroup.enabled = false).",
        }
        TriggerClientEvent("ec_chat_theme:checkGroupResult", src, err)
        return
    end

    if type(payload) ~= "table" then
        payload = { scope = "self" }
    end

    local targetPid = src

    if payload.scope == "id" or payload.scope == "other" then
        local tgt = tonumber(payload.target)
        if not tgt or tgt ~= math.floor(tgt) or tgt < 1 then
            local err = {
                error = true,
                summary = "Ungültige Server-ID. Nutze: /checkgroup oder /checkgroup me",
            }
            EcChat.LogCheckGroupToServer(src, src, err)
            TriggerClientEvent("ec_chat_theme:checkGroupResult", src, err)
            return
        end

        local allowOther = EcChat.IsStaffChatMember(src)
        local dbg = rawget(Config, "Debug") == true
        if tgt ~= src and not allowOther and not dbg then
            local err = {
                error = true,
                summary = "Andere Spieler nur mit Team-Recht oder Config.Debug — sonst nur /checkgroup.",
            }
            EcChat.LogCheckGroupToServer(src, src, err)
            TriggerClientEvent("ec_chat_theme:checkGroupResult", src, err)
            return
        end

        if not GetPlayerName(tgt) then
            local err = {
                error = true,
                summary = ("Kein Spieler mit Server-ID %d online."):format(tgt),
            }
            EcChat.LogCheckGroupToServer(src, tgt, err)
            TriggerClientEvent("ec_chat_theme:checkGroupResult", src, err)
            return
        end
        targetPid = tgt
    end

    local report = EcChat.BuildCheckGroupReport(targetPid)
    if not report then
        local err = { error = true, summary = "Prüfung fehlgeschlagen." }
        EcChat.LogCheckGroupToServer(src, targetPid, err)
        TriggerClientEvent("ec_chat_theme:checkGroupResult", src, err)
        return
    end

    if targetPid ~= src then
        report.summary = ("[%s] %s"):format(report.playerName, report.summary)
    end

    EcChat.LogCheckGroupToServer(src, targetPid, report)
    pushChatLines(src, report)
    TriggerClientEvent("ec_chat_theme:checkGroupResult", src, report)
end)
