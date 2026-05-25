--[[ Während EC-Chat-NUI offen: Gameplay-Controls blocken (Hände heben, etc.). ]]

EcChat = EcChat or {}

local function focusCfg()
    if EcChat.ConfigChatFocus then
        return EcChat.ConfigChatFocus()
    end
    return { blockGameplayControls = true }
end

CreateThread(function()
    while true do
        local block = focusCfg().blockGameplayControls ~= false
        if block and EcChat.client and EcChat.client.chatOpen then
            SetNuiFocusKeepInput(false)
            DisableAllControlActions(0)
            DisableAllControlActions(1)
            DisableAllControlActions(2)
            Wait(0)
        else
            Wait(200)
        end
    end
end)
