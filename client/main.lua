local function openChatUi()
    if EcChat.client.chatOpen then
        return
    end

    EcChat.client.chatOpen = true
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    EcChat.SendUi("open", EcChat.BuildOpenPayload())
end

local function closeChat()
    if not EcChat.client.chatOpen then
        return
    end

    EcChat.client.chatOpen = false
    SetNuiFocus(false, false)
    EcChat.SendUi("close")
end

local function clearLocalChat()
    EcChat.SendUi("clearMessages")
end

--- Eine Submit-Zeile serverseitig für chat_history (alle Eingaben aus dem Chat-Feld & F8-Staff-Zeilen).
local function ecChatSlashDebugEnabled()
    return EcChat.SlashRelayDebugEnabled()
end

local function ecChatSlashDbg(msg)
    if ecChatSlashDebugEnabled() then
        print(("[ec_chat_theme][slash][client] %s"):format(msg))
    end
end

local function ecChatMaybeLogSubmittedLine(rawLine)
    if type(rawLine) ~= "string" or rawLine == "" then
        return
    end
    local db = Config.ChatHistoryDatabase
    if type(db) ~= "table" or db.enabled ~= true then
        return
    end
    TriggerServerEvent("ec_chat_theme:logSubmittedLine", rawLine)
end

local function syncStaffChatSuggestions(canStaff)
    local aliases = EcChat.GetStaffChatAliases()
    for _, alias in ipairs(aliases) do
        local n = EcChat.NormalizeCommandName(alias)
        if n then
            EcChat.client.suggestions[n] = nil
        end
    end

    if canStaff == true and Config.StaffChat and Config.StaffChat.enabled then
        for _, alias in ipairs(aliases) do
            EcChat.UpsertSuggestion(alias, "Team-/Staff-Chat (nur für Berechtigte).", {
                { name = "Nachricht", help = "Nachricht an das Team." }
            })
        end
    end

    EcChat.RebuildSuggestions()
end

local function applyPermissionsFromTable(perms)
    if type(perms) ~= "table" then
        return
    end
    local lp = EcChat.client.lastPermissions
    if type(perms.canUseMe) == "boolean" then
        lp.canUseMe = perms.canUseMe
    end
    if type(perms.canUseDo) == "boolean" then
        lp.canUseDo = perms.canUseDo
    end
    if type(perms.canUseStaffChat) == "boolean" then
        lp.canUseStaffChat = perms.canUseStaffChat
        syncStaffChatSuggestions(perms.canUseStaffChat)
    end
    if type(perms.staffChatAliases) == "table" then
        lp.staffChatAliases = perms.staffChatAliases
    end
end

RegisterNetEvent("ec_chat_theme:setPermissions", function(perms)
    applyPermissionsFromTable(perms)
    EcChat.SendUi("setPermissions", EcChat.client.lastPermissions)
end)

RegisterNetEvent("ec_chat_theme:openChat", function(perms)
    applyPermissionsFromTable(perms)
    openChatUi()
end)

RegisterNetEvent("ec_chat_theme:rpTextRejected", function(data)
    if type(data) ~= "table" then
        return
    end
    local kind = data.kind == "do" and "do" or "me"
    local max = tonumber(data.max) or (kind == "do" and EcChat.RpDoMaxLength() or EcChat.RpMeMaxLength())
    local label = kind == "do" and "/do" or "/me"
    if EcChat.ShowPlayerNotify then
        EcChat.ShowPlayerNotify(
            "EC Chat",
            ("%s: maximal %d Zeichen (kein Abschneiden)."):format(label, max),
            "error",
            true
        )
    end
end)

CreateThread(function()
    --- Sofort: nach Script-Neustart sonst leer bis ESX erneut sendet (tut es oft nicht).
    EcChat.LoadSuggestionsFromKvp()
    Wait(250)

    EcChat.LoadSettingsFromKvp()

    EcChat.UpsertSuggestion("me", "RP-Einspieler-Aktion (Ich-Form).", {
        { name = "Text", help = "Was du tust oder ausdrückst." }
    })
    EcChat.UpsertSuggestion("do", "Umgebung / situative Beschreibung.", {
        { name = "Text", help = "Was in der Szene passiert (sichtbar/hörbar)." }
    })

    local registeredCommands = GetRegisteredCommands()
    for _, command in ipairs(registeredCommands) do
        if command.name then
            EcChat.UpsertSuggestion(command.name, "Registrierter Befehl.", {})
        end
    end

    EcChat.RebuildSuggestions()

    TriggerServerEvent("ec_chat_theme:requestPermissionsOnly")

    local function registerStaffSlashCommands()
        local staffAliases = EcChat.GetStaffChatAliases()
        for _, alias in ipairs(staffAliases) do
            RegisterCommand(alias, function(_, args)
                local msg = table.concat(args, " ")
                local raw = "/" .. alias .. (msg ~= "" and (" " .. msg) or "")
                ecChatMaybeLogSubmittedLine(raw)
                TriggerServerEvent("ec_chat_theme:sendStaff", raw)
            end, false)
        end
    end

    registerStaffSlashCommands()
    CreateThread(function()
        Wait(1500)
        registerStaffSlashCommands()
    end)
end)

RegisterCommand("+openEcChat", function()
    TriggerServerEvent("ec_chat_theme:requestOpen")
end, false)

RegisterCommand("-openEcChat", function()
end, false)

RegisterKeyMapping("+openEcChat", "EC Chat öffnen", "keyboard", "t")

RegisterNetEvent("ec_chat_theme:executeDeferredCommand", function(cmdLine)
    ecChatSlashDbg(("executeDeferredCommand received type=%s len=%s"):format(type(cmdLine),
        type(cmdLine) == "string" and #cmdLine or "n/a"))
    if type(cmdLine) ~= "string" or cmdLine == "" then
        ecChatSlashDbg("executeDeferredCommand: abort (invalid or empty cmdLine)")
        return
    end

    local cfg = EcChat.ConfigChatSlash and EcChat.ConfigChatSlash() or {}
    local delayMs = tonumber(cfg.deferredExecuteDelayMs)
    if not delayMs or delayMs < 0 then
        delayMs = 75
    end

    --- Nur Fallback (kein ox-Event-Weg): längeres Warten nach Chat-NUI, sonst oft kein Effekt bei doorlock.
    local firstTok = cmdLine:match("^(%S+)") or ""
    if firstTok:lower() == "doorlock" then
        local d = tonumber(cfg.doorlockExecuteFallbackDelayMs)
        if d and d >= 0 then
            delayMs = d
        end
    end

    ecChatSlashDbg(("executeDeferredCommand: wait %sms then ExecuteCommand %q"):format(delayMs, cmdLine))
    CreateThread(function()
        if delayMs > 0 then
            Wait(delayMs)
        else
            Wait(0)
        end
        ecChatSlashDbg(("executeDeferredCommand: invoking ExecuteCommand %q"):format(cmdLine))
        ExecuteCommand(cmdLine)
    end)
end)

RegisterNUICallback("close", function(_, cb)
    closeChat()
    cb({})
end)

RegisterNUICallback("submit", function(data, cb)
    local text = ""
    if data and type(data.text) == "string" then
        text = data.text
    end

    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    if ecChatSlashDebugEnabled() then
        ecChatSlashDbg(("NUICallback submit: trimmed text=%q (len=%s)"):format(text, text == "" and 0 or #text))
    end

    --- Wichtig: Slash zuerst an den Server schicken, *dann* NUI zu (Focus weg).
    --- Sonst können TriggerServerEvent / doorlock-Reaktion hinterher nicht zuverlässig landen.

    if text == "" then
        if ecChatSlashDebugEnabled() then
            ecChatSlashDbg("NUICallback submit: empty line, stop")
        end
        closeChat()
        cb({})
        return
    end

    ecChatMaybeLogSubmittedLine(text)

    if EcChat.MessageStartsWithStaffAlias(text) then
        ecChatSlashDbg("NUICallback submit: staff alias route (no slash relay)")
        TriggerServerEvent("ec_chat_theme:sendStaff", text)
        closeChat()
        cb({})
        return
    end

    local lower = text:lower()
    if lower:sub(1, 1) == "/" then
        if EcChat.SlashRpVerbBoundary(lower, "me") then
            ecChatSlashDbg("NUICallback submit: /me route")
            TriggerServerEvent("ec_chat_theme:sendRp", "me", text)
            closeChat()
            cb({})
            return
        end
        if EcChat.SlashRpVerbBoundary(lower, "do") then
            ecChatSlashDbg("NUICallback submit: /do route")
            TriggerServerEvent("ec_chat_theme:sendRp", "do", text)
            closeChat()
            cb({})
            return
        end

        if EcChat.TryDispatchCheckgroupSlashLine(text) then
            ecChatSlashDbg("NUICallback submit: /checkgroup route (direct server, no ExecuteCommand)")
            closeChat()
            cb({})
            return
        end

        local cmd = text:sub(2)
        ecChatSlashDbg(("NUICallback submit slash: raw=%q cmd(stripLeading/)=%q"):format(text, cmd))
        if cmd ~= "" then
            TriggerServerEvent("ec_chat_theme:relayChatSlashCommand", cmd)
            ecChatSlashDbg("NUICallback submit: TriggerServerEvent relayChatSlashCommand sent")
        else
            ecChatSlashDbg("NUICallback submit: cmd empty after / – no relay")
        end
        closeChat()
        cb({})
        return
    end

    ecChatSlashDbg("NUICallback submit: say route (no leading /)")
    TriggerServerEvent("ec_chat_theme:sendMessage", text)
    closeChat()
    cb({})
end)

RegisterNUICallback("clearMessages", function(_, cb)
    clearLocalChat()
    cb({})
end)

RegisterNUICallback("requestSuggestions", function(_, cb)
    EcChat.RebuildSuggestions()
    TriggerServerEvent("ec_chat_theme:requestServerSuggestions")
    cb({})
end)

RegisterNUICallback("runSlashCommand", function(data, cb)
    if data and type(data.command) == "string" and data.command ~= "" then
        ecChatSlashDbg(("NUICallback runSlashCommand: %q -> relay"):format(data.command))
        TriggerServerEvent("ec_chat_theme:relayChatSlashCommand", data.command)
    elseif ecChatSlashDebugEnabled() then
        ecChatSlashDbg("NUICallback runSlashCommand: no valid data.command")
    end
    cb({})
end)

RegisterNUICallback("saveSettings", function(data, cb)
    if data and type(data) == "table" then
        local settings = EcChat.client.settings
        if type(data.showMeButton) == "boolean" then
            settings.showMeButton = data.showMeButton
        end
        if type(data.showDoButton) == "boolean" then
            settings.showDoButton = data.showDoButton
        end
        if type(data.positionPreset) == "string" and data.positionPreset ~= "" then
            settings.positionPreset = data.positionPreset
        end
        if type(data.manualMoveEnabled) == "boolean" then
            settings.manualMoveEnabled = data.manualMoveEnabled
        end
        if type(data.manualX) == "number" then
            settings.manualX = data.manualX
        elseif data.manualX == nil then
            settings.manualX = nil
        end
        if type(data.manualY) == "number" then
            settings.manualY = data.manualY
        elseif data.manualY == nil then
            settings.manualY = nil
        end
        if type(data.historyHudMoveEnabled) == "boolean" then
            settings.historyHudMoveEnabled = data.historyHudMoveEnabled
        end
        if type(data.historyHudX) == "number" then
            settings.historyHudX = data.historyHudX
        elseif data.historyHudX == nil then
            settings.historyHudX = nil
        end
        if type(data.historyHudY) == "number" then
            settings.historyHudY = data.historyHudY
        elseif data.historyHudY == nil then
            settings.historyHudY = nil
        end
        if type(data.historyHudStaffX) == "number" then
            settings.historyHudStaffX = data.historyHudStaffX
        elseif data.historyHudStaffX == nil then
            settings.historyHudStaffX = nil
        end
        if type(data.historyHudStaffY) == "number" then
            settings.historyHudStaffY = data.historyHudStaffY
        elseif data.historyHudStaffY == nil then
            settings.historyHudStaffY = nil
        end
        if type(data.historyPopupMoveEnabled) == "boolean" then
            settings.historyPopupMoveEnabled = data.historyPopupMoveEnabled
        end
        if type(data.historyPopupX) == "number" then
            settings.historyPopupX = data.historyPopupX
        elseif data.historyPopupX == nil then
            settings.historyPopupX = nil
        end
        if type(data.historyPopupY) == "number" then
            settings.historyPopupY = data.historyPopupY
        elseif data.historyPopupY == nil then
            settings.historyPopupY = nil
        end
        if type(data.historyPopupStaffX) == "number" then
            settings.historyPopupStaffX = data.historyPopupStaffX
        elseif data.historyPopupStaffX == nil then
            settings.historyPopupStaffX = nil
        end
        if type(data.historyPopupStaffY) == "number" then
            settings.historyPopupStaffY = data.historyPopupStaffY
        elseif data.historyPopupStaffY == nil then
            settings.historyPopupStaffY = nil
        end
        if type(data.soundNormalEnabled) == "boolean" then
            settings.soundNormalEnabled = data.soundNormalEnabled
        end
        if type(data.soundStaffEnabled) == "boolean" then
            settings.soundStaffEnabled = data.soundStaffEnabled
        end
        if type(data.soundNormalVolume) == "number" then
            settings.soundNormalVolume = data.soundNormalVolume
        elseif data.soundNormalVolume == nil then
            settings.soundNormalVolume = nil
        end
        if type(data.soundStaffVolume) == "number" then
            settings.soundStaffVolume = data.soundStaffVolume
        elseif data.soundStaffVolume == nil then
            settings.soundStaffVolume = nil
        end

        SetResourceKvp("ec_chat_theme_settings", json.encode(settings))
    end
    cb({})
end)

RegisterNUICallback("saveHistoryPrivacy", function(data, cb)
    if type(data) == "table" and EcChat.SetHistoryPrivacyHidden then
        EcChat.SetHistoryPrivacyHidden(data.hidden == true)
    end
    cb({})
end)

RegisterNUICallback("chatLoaded", function(_, cb)
    if EcChat.PushHistoryCommandSuggestions then
        EcChat.PushHistoryCommandSuggestions()
    end
    EcChat.RebuildSuggestions()
    TriggerServerEvent("ec_chat_theme:requestServerSuggestions")
    TriggerServerEvent("ec_chat_theme:requestPermissionsOnly")
    EcChat.SendUi("setSettings", EcChat.SettingsPayloadForUi())
    EcChat.SendUi("setPermissions", EcChat.client.lastPermissions)

    EcChat.SendUi("setChatHistoryUi", EcChat.BuildChatHistoryUiPayload and EcChat.BuildChatHistoryUiPayload() or nil)
    if EcChat.PushHistoryPrivacyToNui then
        EcChat.PushHistoryPrivacyToNui()
    end
    EcChat.SendUi("setItemAutocomplete", EcChat.ItemAutocompleteUiRules())
    EcChat.SendUi("setUiBrand", EcChat.UiBrandPayloadForNui())
    if EcChat.RpTextLimitsPayload then
        EcChat.SendUi("setRpTextLimits", EcChat.RpTextLimitsPayload())
    end
    if EcChat.UiSoundsPayloadForNui then
        EcChat.SendUi("setChatSounds", EcChat.UiSoundsPayloadForNui())
    end

    cb({})
end)

RegisterNetEvent("chat:addSuggestion", function(commandName, helpText, params)
    EcChat.UpsertSuggestion(commandName, helpText, params or {})
    EcChat.RebuildSuggestions()
end)

RegisterNetEvent("chat:addSuggestions", function(entries)
    if type(entries) ~= "table" then
        return
    end

    for _, entry in ipairs(entries) do
        if entry.name then
            EcChat.UpsertSuggestion(entry.name, entry.help, entry.params or {})
        end
    end

    EcChat.RebuildSuggestions()
end)

RegisterNetEvent("chat:removeSuggestion", function(commandName)
    local normalized = EcChat.NormalizeCommandName(commandName)
    if not normalized then
        return
    end

    EcChat.client.suggestions[normalized] = nil
    EcChat.RebuildSuggestions()
end)

RegisterNetEvent("ec_chat_theme:addStaffMessage", function(message)
    if not EcChat.ClientMayDisplayStaffChat() then
        return
    end
    if type(message) ~= "table" then
        return
    end
    message.template = message.template or "staff"
    EcChat.ForwardChatMessageToUi(message)
end)

RegisterNetEvent("chat:addMessage", function(message)
    EcChat.ForwardChatMessageToUi(message)
end)

RegisterNetEvent("chat:clear", function()
    clearLocalChat()
end)

RegisterCommand("clear", function()
    clearLocalChat()
end, false)

RegisterCommand("cls", function()
    clearLocalChat()
end, false)

exports("addMessage", function(message)
    EcChat.ForwardChatMessageToUi(message)
end)

exports("addSuggestion", function(commandName, helpText, params)
    EcChat.UpsertSuggestion(commandName, helpText, params or {})
    EcChat.RebuildSuggestions()
end)

exports("addSuggestions", function(entries)
    if type(entries) ~= "table" then
        return
    end

    for _, entry in ipairs(entries) do
        if entry.name then
            EcChat.UpsertSuggestion(entry.name, entry.help, entry.params or {})
        end
    end

    EcChat.RebuildSuggestions()
end)

exports("removeSuggestion", function(commandName)
    local normalized = EcChat.NormalizeCommandName(commandName)
    if not normalized then
        return
    end

    EcChat.client.suggestions[normalized] = nil
    EcChat.RebuildSuggestions()
end)

exports("clear", function()
    clearLocalChat()
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        SetNuiFocus(false, false)
    end
end)
