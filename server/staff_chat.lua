--[[ Staff-Chat broadcast — Mitgliedschaft: EcChat.IsStaffChatMember (shared/staff_chat.lua) ]]

EcChat = EcChat or {}

local function staffChatColorRgb()
    local cfg = Config.StaffChat
    local c = type(cfg) == "table" and cfg.color or nil
    if type(c) == "table" and #c >= 3 then
        local r = tonumber(c[1]) or 255
        local g = tonumber(c[2]) or 200
        local b = tonumber(c[3]) or 120
        return { math.floor(r), math.floor(g), math.floor(b) }
    end
    if type(c) == "string" and c ~= "" then
        --- Optional später: Hex parsen — aktuell Fallback.
    end
    return { 235, 85, 85 }
end

local function stripStaffBody(fullText, alias)
    if type(fullText) ~= "string" or type(alias) ~= "string" then
        return ""
    end
    local t = fullText:gsub("^%s+", ""):gsub("%s+$", "")
    local pref = "/" .. alias
    local lower = t:lower()
    local lpref = pref:lower()
    if lower == lpref then
        return ""
    end
    if lower:sub(1, #lpref + 1) == lpref .. " " then
        return t:sub(#pref + 2):gsub("^%s+", ""):gsub("%s+$", "")
    end
    return ""
end

function EcChat.PushStaffChatSuggestions(playerSrc)
    if type(playerSrc) ~= "number" or playerSrc <= 0 then
        return
    end

    if not EcChat.IsStaffChatMember(playerSrc) then
        return
    end

    local help = "Team-/Staff-Chat (nur für Berechtigte)."
    local params = {
        { name = "Nachricht", help = "Nachricht an das Team." }
    }

    for _, alias in ipairs(EcChat.GetStaffChatAliases()) do
        if type(alias) == "string" and alias ~= "" then
            TriggerClientEvent("chat:addSuggestion", playerSrc, alias, help, params)
        end
    end
end

local function staffDenyNotice(src, message)
    if not src or src <= 0 then
        return
    end
    TriggerClientEvent("chat:addMessage", src, {
        color = { 220, 120, 120 },
        args = { "[Staff-Chat]", message }
    })
end

RegisterNetEvent("ec_chat_theme:sendStaff", function(rawText)
    local src = source
    if not src or src <= 0 then
        return
    end

    local cfg = Config.StaffChat
    if type(cfg) ~= "table" or cfg.enabled ~= true then
        staffDenyNotice(src, "Staff-Chat ist deaktiviert (Config.StaffChat.enabled).")
        return
    end

    if not EcChat.IsStaffChatMember(src) then
        if EcChat.CheckGroupServerLogEnabled and EcChat.CheckGroupServerLogEnabled() and EcChat.BuildCheckGroupReport then
            print(("[ec_chat_theme][staff] /a|/t abgelehnt — source=%s IsStaffChatMember=NEIN (siehe [checkgroup]-Block unten)"):format(src))
            local report = EcChat.BuildCheckGroupReport(src)
            if report and EcChat.LogCheckGroupToServer then
                EcChat.LogCheckGroupToServer(src, src, report)
            end
        end
        staffDenyNotice(
            src,
            "Team-Chat: keine Berechtigung. In config.lua StaffChat.groups (group.*) oder StaffChat.aceAllow (z.B. qbcore.admin) eintragen."
        )
        return
    end

    if type(rawText) ~= "string" then
        return
    end

    local alias = select(1, EcChat.MessageStartsWithStaffAlias(rawText))
    if not alias then
        return
    end

    local body = stripStaffBody(rawText, alias)
    if body == "" then
        staffDenyNotice(src, ("Nutze /%s <Nachricht> (Nachricht nicht leer)."):format(alias))
        return
    end

    local playerName = GetPlayerName(src) or ("Player %d"):format(src)

    local color = staffChatColorRgb()
    local tag = "[Staff]"

    local payload = {
        template = "staff",
        color = color,
        args = { tag .. " " .. playerName, body }
    }

    for _, pidStr in ipairs(GetPlayers()) do
        local pid = tonumber(pidStr)
        if pid and EcChat.IsStaffChatMember(pid) then
            TriggerClientEvent("ec_chat_theme:addStaffMessage", pid, payload)
        end
    end
end)
