RegisterNetEvent("ec_chat_theme:requestPermissionsOnly", function()
    local src = source
    if not src or src <= 0 then
        return
    end

    TriggerClientEvent("ec_chat_theme:setPermissions", src, EcChat.GetPermissionsForPlayer(src))
    EcChat.PushStaffChatSuggestions(src)
end)

RegisterNetEvent("ec_chat_theme:requestOpen", function()
    local src = source
    if not src or src <= 0 then
        return
    end

    local perms = EcChat.GetPermissionsForPlayer(src)
    TriggerClientEvent("ec_chat_theme:openChat", src, perms)
    EcChat.PushStaffChatSuggestions(src)
end)

RegisterNetEvent("ec_chat_theme:logSubmittedLine", function(rawLine)
    local src = source
    if not src or src <= 0 then
        return
    end

    if type(rawLine) ~= "string" then
        return
    end

    local trimmed = rawLine:gsub("^%s+", ""):gsub("%s+$", "")
    if trimmed == "" then
        return
    end

    if EcChat.LogChatHistory then
        EcChat.LogChatHistory(src, trimmed, "input")
    end
end)

RegisterNetEvent("ec_chat_theme:sendMessage", function(text)
    if type(text) ~= "string" then
        return
    end

    local trimmed = text:gsub("^%s+", ""):gsub("%s+$", "")
    if trimmed == "" then
        return
    end

    local sourcePlayer = source
    local playerName = GetPlayerName(sourcePlayer) or ("Player %d"):format(sourcePlayer)

    TriggerClientEvent("chat:addMessage", -1, {
        color = { 255, 255, 255 },
        args = { playerName, trimmed },
        sender = sourcePlayer,
    })
end)

RegisterNetEvent("ec_chat_theme:sendRp", function(kind, rawText)
    local src = source
    if not src or src <= 0 then
        return
    end

    if kind ~= "me" and kind ~= "do" then
        return
    end

    if not EcChat.IsRpCommandAllowed(src, EcChat.RpPermissionRules(kind)) then
        return
    end

    if type(rawText) ~= "string" then
        return
    end

    local rest = rawText:gsub("^%s+", ""):gsub("%s+$", "")
    local lowerLine = rest:lower()
    if not EcChat.SlashRpVerbBoundary(lowerLine, kind) then
        return
    end

    local msg = ""
    if kind == "me" then
        msg = rest:match("^/?me%s+(.+)$") or rest:match("^/?ME%s+(.+)$") or ""
    else
        msg = rest:match("^/?do%s+(.+)$") or rest:match("^/?DO%s+(.+)$") or ""
    end

    msg = (msg or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if msg == "" then
        return
    end

    local okText = EcChat.ValidateRpMessageText(kind, msg)
    if not okText then
        TriggerClientEvent("ec_chat_theme:rpTextRejected", src, {
            kind = kind,
            max = kind == "do" and EcChat.RpDoMaxLength() or EcChat.RpMeMaxLength(),
        })
        return
    end

    local playerName = GetPlayerName(src) or ("Player %d"):format(src)
    local duration = EcChat.RpOverheadDuration(kind)

    local prefix = kind == "me" and "* " or "(( "
    local suffix = kind == "me" and " *" or " ))"
    local overheadText = prefix .. msg .. suffix

    TriggerClientEvent("ec_chat_theme:overheadDraw", -1, src, kind, overheadText, duration)

    local lineTag = kind == "me" and "[ME]" or "[DO]"
    TriggerClientEvent("chat:addMessage", -1, {
        color = kind == "me" and { 200, 220, 255 } or { 190, 215, 200 },
        args = { lineTag, playerName .. ": " .. msg },
        sender = src,
    })
end)

RegisterNetEvent("ec_chat_theme:requestServerSuggestions", function()
    local playerSrc = source
    if not playerSrc or playerSrc <= 0 then
        return
    end

    local entries = EcChat.BuildServerSuggestionsForPlayer(playerSrc)
    TriggerClientEvent("chat:addSuggestions", playerSrc, entries)
    EcChat.PushStaffChatSuggestions(playerSrc)
end)
