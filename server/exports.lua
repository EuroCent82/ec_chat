exports("addMessage", function(target, message)
    TriggerClientEvent("chat:addMessage", EcChat.NormalizeTarget(target), message)
end)

exports("addSuggestion", function(target, commandName, helpText, params)
    TriggerClientEvent("chat:addSuggestion", EcChat.NormalizeTarget(target), commandName, helpText, params or {})
end)

exports("addSuggestions", function(target, entries)
    TriggerClientEvent("chat:addSuggestions", EcChat.NormalizeTarget(target), entries or {})
end)

exports("removeSuggestion", function(target, commandName)
    TriggerClientEvent("chat:removeSuggestion", EcChat.NormalizeTarget(target), commandName)
end)

exports("clear", function(target)
    TriggerClientEvent("chat:clear", EcChat.NormalizeTarget(target))
end)
