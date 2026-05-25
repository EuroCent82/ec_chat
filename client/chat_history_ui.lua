--[[ Lokale Chat-Historie: /chat on|off (ESX-ähnliches Fade), KVP, Vorschläge — Config.Ui.history ]]



EcChat = EcChat or {}



local KVP_HISTORY_HIDDEN = "ec_chat_theme_history_hidden"



local function historyCfg()
    if EcChat.ConfigChatHistoryUi then
        return EcChat.ConfigChatHistoryUi()
    end
    return Config.ChatHistoryUi
end



function EcChat.IsChatHistoryUiEnabled()

    local ch = historyCfg()

    return type(ch) == "table" and ch.enabled == true

end



function EcChat.HistoryToggleCommandName()

    local ch = historyCfg()

    local name = type(ch) == "table" and type(ch.toggleCommand) == "string" and ch.toggleCommand or "chat"

    name = name:gsub("^%s+", ""):gsub("%s+$", ""):gsub("^/", "")

    if name == "" then

        name = "chat"

    end

    return name

end



function EcChat.BuildChatHistoryUiPayload()

    local ch = historyCfg()

    if not EcChat.IsChatHistoryUiEnabled() then

        return nil

    end

    local autoMs = tonumber(ch.autoHideHistoryMs)

    if not autoMs or autoMs < 0 then

        autoMs = 0

    end

    return {

        maxHistoryMessages = tonumber(ch.maxHistoryMessages) or 15,

        visibleHistoryLines = tonumber(ch.visibleHistoryLines) or 5,

        autoHideHistoryMs = math.floor(autoMs),

        toggleCommand = EcChat.HistoryToggleCommandName(),

    }

end



function EcChat.LoadHistoryPrivacyFromKvp()

    EcChat.client = EcChat.client or {}

    local ch = historyCfg()

    if type(ch) ~= "table" or ch.persistStreamerPrivacyInKvp ~= true then

        EcChat.client.historyPrivacyHidden = false

        return

    end

    local raw = GetResourceKvpString(KVP_HISTORY_HIDDEN)

    EcChat.client.historyPrivacyHidden = raw == "1" or raw == "true"

end



function EcChat.SaveHistoryPrivacyToKvp(hidden)

    local ch = historyCfg()

    if type(ch) ~= "table" or ch.persistStreamerPrivacyInKvp ~= true then

        return

    end

    SetResourceKvp(KVP_HISTORY_HIDDEN, hidden and "1" or "0")

end



function EcChat.PushHistoryPrivacyToNui()

    EcChat.SendUi("setHistoryPrivacy", {

        hidden = EcChat.client.historyPrivacyHidden == true,

    })

end



function EcChat.SetHistoryPrivacyHidden(hidden, persist)

    EcChat.client.historyPrivacyHidden = hidden == true

    if persist ~= false then

        EcChat.SaveHistoryPrivacyToKvp(EcChat.client.historyPrivacyHidden)

    end

    EcChat.PushHistoryPrivacyToNui()

end



local function notifyHistoryToggle(hidden)

    if not EcChat.ShowPlayerNotify then

        return

    end

    local cmd = EcChat.HistoryToggleCommandName()

    if hidden then

        EcChat.ShowPlayerNotify(

            "Chat-Historie",

            ("Streamer-Modus: HUD-Liste aus — /%s on für Standard (mit Auto-Fade)."):format(cmd),

            "inform"

        )

    else

        EcChat.ShowPlayerNotify(

            "Chat-Historie",

            "Standard: Nachrichten erscheinen und blenden nach ein paar Sekunden aus.",

            "success"

        )

    end

end



function EcChat.PushHistoryCommandSuggestions()

    if not EcChat.IsChatHistoryUiEnabled() then

        return

    end

    local name = EcChat.HistoryToggleCommandName()

    EcChat.UpsertSuggestion(name, "HUD-Nachrichtenliste: Standard mit Auto-Fade oder Streamer ohne Anzeige.", {

        { name = "on", help = "Standard — Historie sichtbar, blendet nach Config aus (wie ESX-Chat)." },

        { name = "off", help = "Streamer — keine Nachrichten auf dem Bildschirm (Eingabe bleibt)." },

    })

    if EcChat.RebuildSuggestions then

        EcChat.RebuildSuggestions()

    end

end



function EcChat.ApplyHistoryPrivacyCommand(argWord)

    if not EcChat.IsChatHistoryUiEnabled() then

        if EcChat.ShowPlayerNotify then

            EcChat.ShowPlayerNotify("Chat-Historie", "Lokale Historie ist deaktiviert (Config.Ui.history.enabled).", "inform")

        end

        return

    end



    local word = type(argWord) == "string" and argWord:lower():gsub("^%s+", ""):gsub("%s+$", "") or ""

    local cmd = EcChat.HistoryToggleCommandName()



    if word == "on" or word == "true" or word == "ein" or word == "an" then

        EcChat.SetHistoryPrivacyHidden(false)

        notifyHistoryToggle(false)

        return

    end

    if word == "off" or word == "false" or word == "aus" then

        EcChat.SetHistoryPrivacyHidden(true)

        notifyHistoryToggle(true)

        return

    end



    if EcChat.ShowPlayerNotify then

        EcChat.ShowPlayerNotify(

            "Chat-Historie",

            ("Nutze /%s on oder /%s off"):format(cmd, cmd),

            "inform"

        )

    end

end



local function registerHistoryToggleCommand()

    local ch = historyCfg()

    if type(ch) ~= "table" or ch.enabled ~= true then

        return

    end

    local name = EcChat.HistoryToggleCommandName()



    RegisterCommand(name, function(_, args)

        EcChat.ApplyHistoryPrivacyCommand(args and args[1])

    end, false)



    EcChat.PushHistoryCommandSuggestions()



    local key = ch.toggleKey

    if type(key) == "string" and key ~= "" then

        RegisterKeyMapping(

            "ec_chat_theme_history_privacy",

            "Chat-Historie: Standard an / Streamer aus",

            "keyboard",

            key

        )

        RegisterCommand("ec_chat_theme_history_privacy", function()

            if EcChat.client.historyPrivacyHidden then

                EcChat.ApplyHistoryPrivacyCommand("on")

            else

                EcChat.ApplyHistoryPrivacyCommand("off")

            end

        end, false)

    end

end



CreateThread(function()

    EcChat.LoadHistoryPrivacyFromKvp()

    registerHistoryToggleCommand()

end)

