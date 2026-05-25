--[[ Vorschläge aus registrierten Server-Befehlen (ACE / restricted) ]]

function EcChat.BuildServerSuggestionsForPlayer(playerSrc)
    local entries = {}
    local registered = GetRegisteredCommands()

    for _, command in ipairs(registered) do
        local name = command.name
        if type(name) == "string" and name ~= "" then
            if name:sub(1, 1) ~= "_" and name:sub(1, 1) ~= "+" and name:sub(1, 1) ~= "-" then
                local allowed = true
                if command.restricted then
                    allowed = IsPlayerAceAllowed(playerSrc, ("command.%s"):format(name))
                end

                --- Leerer help: Client behält vorhandene Hilfe (ESX/chat:addSuggestion), füllt sonst Fallback
                if allowed then
                    entries[#entries + 1] = {
                        name = name,
                        help = "",
                        params = {}
                    }
                end
            end
        end
    end

    return entries
end
