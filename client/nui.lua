--[[ NUI: Nachrichten an das Frontend ]]

EcChat = EcChat or {}

function EcChat.SendUi(action, data)
    SendNUIMessage({
        action = action,
        data = data or {}
    })
end

--- `addMessage` / Staff — nur an NUI wenn Berechtigung passt (Historie + Live).
function EcChat.ForwardChatMessageToUi(message)
    if EcChat.IsStaffShapedChatMessage and EcChat.IsStaffShapedChatMessage(message) then
        if not EcChat.ClientMayDisplayStaffChat() then
            return
        end
    elseif EcChat.ClientMayDisplayProximityMessage and not EcChat.ClientMayDisplayProximityMessage(message) then
        return
    end
    EcChat.SendUi("addMessage", message)

    if EcChat.IsStaffShapedChatMessage(message) and not EcChat.client.chatOpen then
        if EcChat.NotifyStaffChatMessage then
            EcChat.NotifyStaffChatMessage(message)
        end
    end
end

--- Einstellungen für die NUI (KVP + Defaults), ohne abgeleitete Debug-UI-Flags.
function EcChat.SettingsPayloadForUi()
    local s = {}
    for k, v in pairs(EcChat.client.settings) do
        s[k] = v
    end
    return s
end

local function trimUiStr(s)
    if type(s) ~= "string" then
        return nil
    end
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

--- Kopfzeile (**Config.Ui.brand`**) für **`open`** / **`setUiBrand`**.
function EcChat.UiBrandPayloadForNui()
    local raw = EcChat.ConfigUiBrand and EcChat.ConfigUiBrand() or rawget(Config, "UiBrand")
    local title = "EC CHAT"
    local badge = "LIVE"
    if type(raw) == "table" then
        local t = trimUiStr(raw.title)
        if t ~= nil then
            title = t
        end
        if raw.badge == false then
            badge = ""
        else
            local b = trimUiStr(raw.badge)
            if b ~= nil then
                badge = b
            end
        end
    end
    return { title = title, badge = badge }
end

function EcChat.UiSoundsPayloadForNui()
    return EcChat.ConfigUiSounds and EcChat.ConfigUiSounds() or {
        enabled = true,
        staffEnabled = true,
        volume = 0.35,
        staffVolume = 0.50,
        staffNotifyWhenClosed = true,
    }
end

function EcChat.BuildOpenPayload()
    return {
        settings = EcChat.SettingsPayloadForUi(),
        permissions = EcChat.client.lastPermissions,
        chatHistoryUi = EcChat.BuildChatHistoryUiPayload and EcChat.BuildChatHistoryUiPayload() or nil,
        itemAutocomplete = EcChat.ItemAutocompleteUiRules(),
        uiBrand = EcChat.UiBrandPayloadForNui(),
        rpTextLimits = EcChat.RpTextLimitsPayload and EcChat.RpTextLimitsPayload() or nil,
        chatSounds = EcChat.UiSoundsPayloadForNui(),
    }
end
