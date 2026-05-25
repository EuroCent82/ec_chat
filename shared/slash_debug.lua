--[[ Gemeinsames Flag: Slash-Relay-Logs nur wenn aktiv (Config.Debug oder explizites ChatSlash.debugSlashRelay). ]]

EcChat = EcChat or {}

function EcChat.SlashRelayDebugEnabled()
    if Config.Debug == true then
        return true
    end
    local cs = EcChat.ConfigChatSlash and EcChat.ConfigChatSlash() or Config.ChatSlash
    return type(cs) == "table" and cs.debugSlashRelay == true
end
