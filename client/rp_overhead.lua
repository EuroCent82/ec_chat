--[[ RP: 3D-Text über Spielern (/me, /do) via Server-Event ]]

local function drawRpOverhead(worldX, worldY, worldZ, text, kind)
    SetDrawOrigin(worldX, worldY, worldZ, 0)
    SetTextScale(0.33, 0.33)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextCentre(true)
    SetTextOutline()

    if kind == "do" then
        SetTextColour(190, 215, 200, 235)
    else
        SetTextColour(220, 235, 255, 240)
    end

    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

CreateThread(function()
    while true do
        local sleep = 400
        local now = GetGameTimer()
        local myCoords = GetEntityCoords(PlayerPedId())
        local maxDist = EcChat.RpOverheadDrawDistance and EcChat.RpOverheadDrawDistance() or 25.0
        local overhead = EcChat.client.overheadTexts

        for serverId, entry in pairs(overhead) do
            if now > entry.expiresAt then
                overhead[serverId] = nil
            else
                sleep = 0
                local idx = GetPlayerFromServerId(serverId)
                if idx ~= -1 then
                    local ped = GetPlayerPed(idx)
                    if ped and ped ~= 0 then
                        local c = GetEntityCoords(ped)
                        if #(myCoords - c) <= maxDist then
                            drawRpOverhead(c.x, c.y, c.z + 1.08, entry.text, entry.kind)
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

RegisterNetEvent("ec_chat_theme:overheadDraw", function(serverId, kind, text, duration)
    if type(serverId) ~= "number" or type(text) ~= "string" or text == "" then
        return
    end

    EcChat.client.overheadTexts[serverId] = {
        kind = kind == "do" and "do" or "me",
        text = text,
        expiresAt = GetGameTimer() + (tonumber(duration) or 12000)
    }
end)
