--[[ Sichtbare Hinweise (ox_lib / QBCore / ESX / GTA-Feed) — unabhängig vom geschlossenen EC-Chat-NUI. ]]

EcChat = EcChat or {}

local function checkGroupNotifyCfg()
    local c = rawget(Config, "CheckGroup")
    if type(c) ~= "table" then
        return true
    end
    if c.notify == false then
        return false
    end
    return true
end

--- @param title string
--- @param description string
--- @param notifyType? 'inform'|'success'|'error'|'warning'
--- @param force? boolean — auch wenn CheckGroup.notify = false (z. B. RP-Zeichenlimit)
function EcChat.ShowPlayerNotify(title, description, notifyType, force)
    if not force and not checkGroupNotifyCfg() then
        return
    end

    title = type(title) == "string" and title or "EC Chat"
    description = type(description) == "string" and description or ""
    notifyType = notifyType or "inform"

    if GetResourceState("ox_lib") == "started" then
        local ok = pcall(function()
            local dur = 9000
            if #description > 120 then
                dur = 14000
            end
            exports.ox_lib:notify({
                title = title,
                description = description,
                type = notifyType,
                duration = dur,
            })
        end)
        if ok then
            return
        end
    end

    if GetResourceState("qb-core") == "started" then
        local ok, QBCore = pcall(function()
            return exports["qb-core"]:GetCoreObject()
        end)
        if ok and QBCore and QBCore.Functions and QBCore.Functions.Notify then
            local map = { success = "success", error = "error", warning = "primary", inform = "primary" }
            QBCore.Functions.Notify(description, map[notifyType] or "primary", 9000)
            return
        end
    end

    if GetResourceState("es_extended") == "started" then
        local ok, ESX = pcall(function()
            return exports["es_extended"]:getSharedObject()
        end)
        if ok and ESX and ESX.ShowNotification then
            ESX.ShowNotification(("%s\n%s"):format(title, description))
            return
        end
    end

    local feed = description
    if title ~= "" and title ~= description then
        feed = ("%s~n~%s"):format(title, description)
    end
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(feed)
    EndTextCommandThefeedPostTicker(false, true)
end

--- Staff-Chat-Hinweis wenn der EC-Chat geschlossen ist (unabhängig von CheckGroup.notify).
--- @param message table — `addMessage`-Payload mit `args`
function EcChat.NotifyStaffChatMessage(message)
    if type(message) ~= "table" then
        return
    end
    local sounds = EcChat.ConfigUiSounds and EcChat.ConfigUiSounds() or {}
    if sounds.staffNotifyWhenClosed == false then
        return
    end
    local args = message.args
    if type(args) ~= "table" or #args < 1 then
        return
    end
    local header = type(args[1]) == "string" and args[1] or "Staff-Chat"
    local body = ""
    if #args >= 2 and type(args[2]) == "string" then
        body = args[2]
    end
    EcChat.ShowPlayerNotify(header, body, "inform", true)
end
