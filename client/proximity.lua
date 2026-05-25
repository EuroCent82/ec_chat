--[[ Nähe-Filter für Say /me /do — Staff-Chat ausgenommen. ]]

EcChat = EcChat or {}

local function proximityCfg()
    if EcChat.ConfigChatProximity then
        return EcChat.ConfigChatProximity()
    end
    return { enabled = true, sayDistance = 35.0 }
end

function EcChat.ProximitySayDistance()
    local cfg = proximityCfg()
    if cfg.enabled == false then
        return nil
    end
    local dist = tonumber(cfg.sayDistance)
    if not dist or dist < 0 then
        dist = 35.0
    end
    return dist + 0.0
end

local function messageSenderId(message)
    if type(message) ~= "table" then
        return nil
    end
    local sender = message.sender or message.source or message.sourceId
    return tonumber(sender)
end

function EcChat.ClientMayDisplayProximityMessage(message)
    if EcChat.IsStaffShapedChatMessage and EcChat.IsStaffShapedChatMessage(message) then
        return true
    end

    local maxDist = EcChat.ProximitySayDistance()
    if not maxDist then
        return true
    end

    local sender = messageSenderId(message)
    if not sender then
        return true
    end

    local myServerId = GetPlayerServerId(PlayerId())
    if sender == myServerId then
        return true
    end

    local senderPlayer = GetPlayerFromServerId(sender)
    if senderPlayer == -1 then
        return false
    end

    local myPed = PlayerPedId()
    local theirPed = GetPlayerPed(senderPlayer)
    if not theirPed or theirPed <= 0 or not DoesEntityExist(theirPed) then
        return false
    end

    local dist = #(GetEntityCoords(myPed) - GetEntityCoords(theirPed))
    return dist <= maxDist
end
