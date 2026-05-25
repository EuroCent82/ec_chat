--[[ txAdmin: authentifizierte Panel-Admins (F4 / txAdmin-Menü) — nicht dasselbe wie ESX /setgroup. ]]

EcChat = EcChat or {}
EcChat.TxAdminStaff = EcChat.TxAdminStaff or {}

AddEventHandler("txAdmin:events:adminAuth", function(data)
    if type(data) ~= "table" then
        return
    end

    if data.netid == -1 then
        EcChat.TxAdminStaff = {}
        return
    end

    local id = tonumber(data.netid)
    if not id or id <= 0 then
        return
    end

    local key = tostring(id)
    if data.isAdmin == true then
        EcChat.TxAdminStaff[key] = true
    else
        EcChat.TxAdminStaff[key] = nil
    end
end)

AddEventHandler("playerDropped", function()
    EcChat.TxAdminStaff[tostring(source)] = nil
end)

function EcChat.IsTxAdminAuthenticated(playerSrc)
    if type(playerSrc) ~= "number" or playerSrc <= 0 then
        return false
    end
    return EcChat.TxAdminStaff[tostring(playerSrc)] == true
end
