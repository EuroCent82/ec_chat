--[[ Client: `/checkgroup` / `/checkgroup me` / `/checkgroup <id>` — Ergebnis als Notify (sichtbar auch wenn Chat zu ist). ]]

EcChat = EcChat or {}

local function isCheckGroupEnabled()
    local c = rawget(Config, "CheckGroup")
    if type(c) ~= "table" then
        return true
    end
    return c.enabled ~= false
end

local function checkGroupDisabledNotice()
    local msg = "Diagnose /checkgroup ist deaktiviert (Config.CheckGroup.enabled = false)."
    local c = rawget(Config, "CheckGroup")
    local useNotify = type(c) ~= "table" or c.notify ~= false
    if useNotify and EcChat.ShowPlayerNotify then
        EcChat.ShowPlayerNotify("checkgroup", msg, "inform")
        return
    end
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandThefeedPostTicker(false, true)
end

--- Restzeichenkette nach `checkgroup` aus F8/ExecuteCommand liefern (ohne führendes `/`).
local function tailFromRegisterCommandArgs(args, rawCommand)
    if type(rawCommand) == "string" then
        local r = rawCommand:gsub("^%s+", ""):gsub("%s+$", ""):lower()
        r = r:gsub("^/", "")
        local tail = r:match("^checkgroup%s+(.*)$")
        if tail then
            return tail:gsub("^%s+", ""):gsub("%s+$", "")
        end
        if r == "checkgroup" then
            return ""
        end
    end
    if type(args) == "table" and #args > 0 then
        local s = table.concat(args, " "):gsub("^%s+", ""):gsub("%s+$", ""):lower()
        if s == "checkgroup" or s == "" then
            return ""
        end
        if s:match("^checkgroup%s+") then
            return (s:match("^checkgroup%s+(.+)$") or ""):gsub("^%s+", ""):gsub("%s+$", "")
        end
        return s
    end
    return ""
end

local function dispatchCheckgroupTail(tailRaw)
    if not isCheckGroupEnabled() then
        checkGroupDisabledNotice()
        return
    end

    local tail = type(tailRaw) == "string" and tailRaw:gsub("^%s+", ""):gsub("%s+$", ""):lower() or ""
    local first = tail:match("^(%S+)") or ""

    if tail == "" or first == "" or first == "me" then
        TriggerServerEvent("ec_chat_theme:requestCheckGroup", { scope = "self" })
        return
    end

    local nid = tonumber(first)
    if nid and nid >= 1 then
        TriggerServerEvent("ec_chat_theme:requestCheckGroup", {
            scope = "id",
            target = math.floor(nid),
        })
        return
    end

    if EcChat.ShowPlayerNotify then
        EcChat.ShowPlayerNotify("checkgroup", "Nutze /checkgroup, /checkgroup me oder /checkgroup <server-id>", "inform")
    end
end

--- Volle Chat-Zeile wie `/checkgroup me` (NUI-Submit) — **true** wenn verarbeitet (kein Slash-Relay).
function EcChat.TryDispatchCheckgroupSlashLine(text)
    if type(text) ~= "string" then
        return false
    end
    local trimmed = text:gsub("^%s+", ""):gsub("%s+$", "")
    if trimmed:sub(1, 1) ~= "/" then
        return false
    end
    local body = trimmed:sub(2):gsub("^%s+", "")
    local cmd, tail = body:match("^(%S+)%s*(.*)$")
    if not cmd then
        return false
    end
    if cmd:lower() ~= "checkgroup" then
        return false
    end
    if not isCheckGroupEnabled() then
        checkGroupDisabledNotice()
        return true
    end
    dispatchCheckgroupTail(tail)
    return true
end

RegisterCommand("checkgroup", function(_, args, rawCommand)
    if not isCheckGroupEnabled() then
        checkGroupDisabledNotice()
        return
    end
    local tail = tailFromRegisterCommandArgs(args, rawCommand)
    dispatchCheckgroupTail(tail)
end, false)

RegisterNetEvent("ec_chat_theme:checkGroupResult", function(data)
    if type(data) ~= "table" then
        return
    end

    local summary = type(data.summary) == "string" and data.summary or "Keine Daten."
    local detail = type(data.detail) == "string" and data.detail or ""
    local isErr = data.error == true
    local isStaff = data.isStaffMember == true and not isErr

    local notifyType = "inform"
    if isErr then
        notifyType = "error"
    elseif isStaff then
        notifyType = "success"
    elseif data.isStaffMember == false then
        notifyType = "warning"
    end

    local body = summary
    if detail ~= "" then
        body = summary .. "\n\n" .. detail
    end

    if EcChat.ShowPlayerNotify then
        EcChat.ShowPlayerNotify("Team / Gruppe", body, notifyType)
    end
end)
