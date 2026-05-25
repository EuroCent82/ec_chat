--- Normalisiert Export-Ziel für TriggerClientEvent (-1 = alle)
EcChat = EcChat or {}

function EcChat.NormalizeTarget(target)
    if target == nil then
        return -1
    end

    local numericTarget = tonumber(target)
    if not numericTarget then
        return -1
    end

    return numericTarget
end
