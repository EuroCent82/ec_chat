--[[
  Slash-Befehle aus dem EC-Chat nach /me /do / Staff:
  Für **doorlock** (ox_doorlock) gilt wie bei **F8/ox_lib**: Erlaubnis über **`command.doorlock`** und/oder **CommandPrincipal**.
  Bei Zulassung **TriggerClientEvent('ox_doorlock:triggeredCommand', …)** – kein Client-ExecuteCommand
  mehr (läuft nach NUI-Schließen oft nicht zuverlässig).
]]

EcChat = EcChat or {}

local function slashRelayDebugEnabled()
    return EcChat.SlashRelayDebugEnabled()
end

local function slashRelayDbg(msg)
    if slashRelayDebugEnabled() then
        print(("[ec_chat_theme][slash][server] %s"):format(msg))
    end
end

local function isOxDoorlockCommand(trimmed)
    local name = trimmed:match("^(%S+)")
    return name and name:lower() == "doorlock"
end

--- ox_lib `lib.addCommand` mit `RegisterCommand(..., true)` prüft Spieler über **`command.<name>`**,
--- also **`command.doorlock`** — nicht zwingend direkt `Config.CommandPrincipal` (z. B. `group.admin`).
local function oxDoorlockCommandAllowed(pid, optionalCommandPrincipal)
    if IsPlayerAceAllowed(pid, "command.doorlock") then
        return true
    end
    if type(optionalCommandPrincipal) == "string" and optionalCommandPrincipal ~= ""
        and IsPlayerAceAllowed(pid, optionalCommandPrincipal) then
        return true
    end
    return false
end

local function oxDoorlockCommandAcePrincipal()
    local cs = EcChat.ConfigChatSlash and EcChat.ConfigChatSlash() or Config.ChatSlash
    if type(cs) == "table" and type(cs.doorlockCommandPrincipal) == "string" and cs.doorlockCommandPrincipal ~= "" then
        return cs.doorlockCommandPrincipal, true
    end

    local txt = LoadResourceFile("ox_doorlock", "config.lua")
    if type(txt) ~= "string" or txt == "" then
        return nil, false
    end

    for line in txt:gmatch("[^\r\n]+") do
        local work = line:gsub("%s%-%-.*$", "")
        if work:find("CommandPrincipal", 1, true) and work:find("=", 1, true) then
            local rhs = work:match("CommandPrincipal%s*=%s*(.*)$")
            if rhs then
                rhs = rhs:gsub("^%s+", ""):gsub("%s+$", "")
                local quoted = rhs:match("^[\"']([^\"']+)[\"']%s*$")
                if quoted and quoted ~= "" then
                    return quoted, true
                end
                local bare = rhs:match("^([%w._:]+)")
                if bare and bare ~= "" then
                    local bl = bare:lower()
                    if bl ~= "false" and bl ~= "nil" then
                        return bare, true
                    end
                end
            end
        end
    end

    return nil, false
end

--- Zweites Argument wie ox `args.closest`: optional das Wort `closest`.
local function oxDoorlockTriggerArg(trimmed)
    local tail = trimmed:match("^%S+%s+(.+)$")
    if type(tail) ~= "string" then
        return nil
    end
    tail = tail:gsub("^%s+", ""):gsub("%s+$", "")
    if tail == "" then
        return nil
    end
    local tok = tail:match("^(%S+)")
    if tok and tok:lower() == "closest" then
        return tok
    end
    return nil
end

RegisterNetEvent("ec_chat_theme:relayChatSlashCommand", function(cmdLine)
    local src = source

    if EcChat.SlashRelayDebugEnabled() then
        print(("[ec_chat_theme][slash][server] Relay empfangen: source=%s typ(cmdLine)=%s"):format(tostring(src),
            type(cmdLine)))
    end

    if type(src) ~= "number" or src <= 0 then
        slashRelayDbg(("relayChatSlashCommand: skip invalid source (%s)"):format(tostring(src)))
        return
    end

    if type(cmdLine) ~= "string" then
        slashRelayDbg(("relayChatSlashCommand[%s]: skip non-string cmdLine"):format(src))
        return
    end

    local trimmed = cmdLine:gsub("^%s+", ""):gsub("%s+$", "")
    if trimmed == "" then
        slashRelayDbg(("relayChatSlashCommand[%s]: skip empty after trim"):format(src))
        return
    end

    if #trimmed > 400 then
        slashRelayDbg(("relayChatSlashCommand[%s]: skip too long (%s chars)"):format(src, #trimmed))
        return
    end

    local oxState = GetResourceState("ox_doorlock")
    local isDoor = isOxDoorlockCommand(trimmed)
    slashRelayDbg(("relayChatSlashCommand[%s]: trim=%q ox_doorlock=%s doorlockPrefix=%s"):format(src, trimmed, oxState,
        isDoor))

    if isOxDoorlockCommand(trimmed) and oxState == "started" then
        local principal, sniffOk = oxDoorlockCommandAcePrincipal()
        local pForCheck = (type(principal) == "string" and principal ~= "") and principal or nil

        if oxDoorlockCommandAllowed(src, pForCheck) then
            local argClosest = oxDoorlockTriggerArg(trimmed)
            slashRelayDbg(
                ("relayChatSlashCommand[%s]: TriggerClientEvent ox_doorlock:triggeredCommand (closest=%s)"):format(src,
                    tostring(argClosest)))
            TriggerClientEvent("ox_doorlock:triggeredCommand", src, argClosest)
            return
        end

        if sniffOk then
            local aclHint = "command.doorlock"
            if type(pForCheck) == "string" and pForCheck ~= "" then
                aclHint = ("%s oder %q"):format(aclHint, pForCheck)
            end
            slashRelayDbg(
                ("relayChatSlashCommand[%s]: doorlock denied (%s)"):format(src, aclHint))
            print(("[ec_chat_theme][doorlock] %s [%s]: Chat-/doorlock abgelehnt — fehlt %s (ox)"):format(
                GetPlayerName(src), src, aclHint))
            return
        end

        slashRelayDbg(
            ("relayChatSlashCommand[%s]: doorlock — ACE/Principal nicht ermittelt → Fallback executeDeferredCommand (ExecuteCommand)")
                :format(src))
        TriggerClientEvent("ec_chat_theme:executeDeferredCommand", src, trimmed)
        return
    end

    if isOxDoorlockCommand(trimmed) and oxState ~= "started" then
        slashRelayDbg(
            ("relayChatSlashCommand[%s]: doorlock but ox_doorlock nicht started → deferred ExecuteCommand"):format(src))
    end

    slashRelayDbg(("relayChatSlashCommand[%s]: -> TriggerClientEvent executeDeferredCommand"):format(src))
    TriggerClientEvent("ec_chat_theme:executeDeferredCommand", src, trimmed)
end)
