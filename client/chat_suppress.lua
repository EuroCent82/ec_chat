--[[ Standard-FiveM-/System-Chat dämpfen; Konflikte mit ec_chat vermeiden. ]]

EcChat = EcChat or {}

local function suppressCfg()
    if EcChat.ConfigSuppressDefaultChat then
        return EcChat.ConfigSuppressDefaultChat()
    end
    return {
        enabled = true,
        cancelChatMessageEvent = true,
        warnIfChatResourceRunning = true,
    }
end

local function runStartupDiagnostics()
    local cfg = suppressCfg()
    if cfg.enabled ~= true and cfg.enabled ~= nil then
        return
    end

    if cfg.warnIfChatResourceRunning ~= false then
        local state = GetResourceState("chat")
        if state == "started" or state == "starting" then
            print(
                "[ec_chat_theme] Hinweis: Resource „chat“ läuft parallel — in server.cfg „ensure chat“ entfernen und „stop chat“ setzen.")
        end
    end

    local sysChat = GetConvar("resources_useSystemChat", "false")
    if sysChat == "true" or sysChat == "1" then
        print(
            "[ec_chat_theme] Hinweis: resources_useSystemChat ist true — setze in server.cfg: set resources_useSystemChat false")
    end
end

local function applyTextChatEnabled()
    local cfg = suppressCfg()
    if cfg.enabled == false then
        return
    end
    SetTextChatEnabled(false)
end

CreateThread(function()
    Wait(500)
    applyTextChatEnabled()
    runStartupDiagnostics()
end)

AddEventHandler("onClientResourceStart", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        applyTextChatEnabled()
    elseif resourceName == "chat" then
        local cfg = suppressCfg()
        if cfg.warnIfChatResourceRunning ~= false then
            print("[ec_chat_theme] Resource „chat“ wurde gestartet — kann den Standard-Chat-Kasten ([JEDER]) anzeigen.")
        end
    end
end)

if suppressCfg().cancelChatMessageEvent ~= false then
    AddEventHandler("chatMessage", function(_, _, _)
        CancelEvent()
    end)
end
