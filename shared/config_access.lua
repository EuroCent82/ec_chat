--[[ Zentrale Config-Zugriffe mit Fallback auf ältere Top-Level-Keys (`Config.ChatSlash`, `Config.UiBrand`, …). ]]

EcChat = EcChat or {}

local function chatRoot()
    local c = rawget(Config, "Chat")
    if type(c) == "table" then
        return c
    end
    return nil
end

local function uiRoot()
    local u = rawget(Config, "Ui")
    if type(u) == "table" then
        return u
    end
    return nil
end

function EcChat.ConfigChatSlash()
    local chat = chatRoot()
    if chat and type(chat.slash) == "table" then
        return chat.slash
    end
    local legacy = rawget(Config, "ChatSlash")
    if type(legacy) == "table" then
        return legacy
    end
    return {}
end

function EcChat.ConfigChatFocus()
    local chat = chatRoot()
    if chat and type(chat.focus) == "table" then
        return chat.focus
    end
    local legacy = rawget(Config, "ChatFocus")
    if type(legacy) == "table" then
        return legacy
    end
    return { blockGameplayControls = true }
end

function EcChat.ConfigSuppressDefaultChat()
    local chat = chatRoot()
    if chat and type(chat.suppressDefault) == "table" then
        return chat.suppressDefault
    end
    local legacy = rawget(Config, "SuppressDefaultChat")
    if type(legacy) == "table" then
        return legacy
    end
    return {
        enabled = true,
        cancelChatMessageEvent = true,
        warnIfChatResourceRunning = true,
    }
end

function EcChat.ConfigUiBrand()
    local ui = uiRoot()
    if ui and type(ui.brand) == "table" then
        return ui.brand
    end
    local legacy = rawget(Config, "UiBrand")
    if type(legacy) == "table" then
        return legacy
    end
    return nil
end

function EcChat.ConfigChatHistoryUi()
    local ui = uiRoot()
    if ui and type(ui.history) == "table" then
        return ui.history
    end
    local legacy = rawget(Config, "ChatHistoryUi")
    if type(legacy) == "table" then
        return legacy
    end
    return nil
end

function EcChat.ConfigChatProximity()
    local chat = chatRoot()
    if chat and type(chat.proximity) == "table" then
        return chat.proximity
    end
    return {
        enabled = true,
        sayDistance = 35.0,
    }
end

function EcChat.ConfigUiSounds()
    local ui = uiRoot()
    local raw = ui and type(ui.sounds) == "table" and ui.sounds or nil
    local vol = raw and tonumber(raw.volume)
    if not vol or vol < 0 then
        vol = 0.35
    elseif vol > 1 then
        vol = 1.0
    end
    local staffVol = raw and tonumber(raw.staffVolume)
    if not staffVol or staffVol < 0 then
        staffVol = 0.50
    elseif staffVol > 1 then
        staffVol = 1.0
    end
    return {
        enabled = raw == nil or raw.enabled ~= false,
        staffEnabled = raw == nil or raw.staffEnabled ~= false,
        volume = vol,
        staffVolume = staffVol,
        staffNotifyWhenClosed = raw == nil or raw.staffNotifyWhenClosed ~= false,
    }
end
