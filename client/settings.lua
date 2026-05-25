--[[ Gespeicherte UI-Einstellungen (Resource KVP) — ohne Config-Felder wie Debug ]]

function EcChat.LoadSettingsFromKvp()
    local settings = EcChat.client.settings
    local rawSettings = GetResourceKvpString("ec_chat_theme_settings")
    if not rawSettings or rawSettings == "" then
        return
    end

    local ok, decoded = pcall(json.decode, rawSettings)
    if not ok or type(decoded) ~= "table" then
        return
    end

    if type(decoded.showMeButton) == "boolean" then
        settings.showMeButton = decoded.showMeButton
    end
    if type(decoded.showDoButton) == "boolean" then
        settings.showDoButton = decoded.showDoButton
    end
    if type(decoded.positionPreset) == "string" and decoded.positionPreset ~= "" then
        settings.positionPreset = decoded.positionPreset
    end
    if type(decoded.manualMoveEnabled) == "boolean" then
        settings.manualMoveEnabled = decoded.manualMoveEnabled
    end
    if type(decoded.manualX) == "number" then
        settings.manualX = decoded.manualX
    end
    if type(decoded.manualY) == "number" then
        settings.manualY = decoded.manualY
    end
    if type(decoded.historyHudMoveEnabled) == "boolean" then
        settings.historyHudMoveEnabled = decoded.historyHudMoveEnabled
    end
    if type(decoded.historyHudX) == "number" then
        settings.historyHudX = decoded.historyHudX
    end
    if type(decoded.historyHudY) == "number" then
        settings.historyHudY = decoded.historyHudY
    end
    if type(decoded.historyHudStaffX) == "number" then
        settings.historyHudStaffX = decoded.historyHudStaffX
    end
    if type(decoded.historyHudStaffY) == "number" then
        settings.historyHudStaffY = decoded.historyHudStaffY
    end
    if type(decoded.historyPopupMoveEnabled) == "boolean" then
        settings.historyPopupMoveEnabled = decoded.historyPopupMoveEnabled
    end
    if type(decoded.historyPopupX) == "number" then
        settings.historyPopupX = decoded.historyPopupX
    end
    if type(decoded.historyPopupY) == "number" then
        settings.historyPopupY = decoded.historyPopupY
    end
    if type(decoded.historyPopupStaffX) == "number" then
        settings.historyPopupStaffX = decoded.historyPopupStaffX
    end
    if type(decoded.historyPopupStaffY) == "number" then
        settings.historyPopupStaffY = decoded.historyPopupStaffY
    end
    if type(decoded.soundNormalEnabled) == "boolean" then
        settings.soundNormalEnabled = decoded.soundNormalEnabled
    end
    if type(decoded.soundStaffEnabled) == "boolean" then
        settings.soundStaffEnabled = decoded.soundStaffEnabled
    end
    if type(decoded.soundNormalVolume) == "number" then
        settings.soundNormalVolume = decoded.soundNormalVolume
    end
    if type(decoded.soundStaffVolume) == "number" then
        settings.soundStaffVolume = decoded.soundStaffVolume
    end
    if type(decoded.showQuickButtons) == "boolean" and type(decoded.showMeButton) ~= "boolean" then
        settings.showMeButton = decoded.showQuickButtons
        settings.showDoButton = decoded.showQuickButtons
    end
end
