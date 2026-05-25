--[[ Gemeinsamer Client-State (wird von nui / debug / suggestions / rp_overhead / main genutzt) ]]

EcChat = EcChat or {}

EcChat.client = {
    chatOpen = false,
    suggestions = {},
    settings = {
        showMeButton = true,
        showDoButton = true,
        positionPreset = "bottom-left",
        manualMoveEnabled = false,
        manualX = nil,
        manualY = nil,
        --- HUD-Nachrichten (#messages-wrap) losgelöst von der Konsole — frei verschiebbar
        historyHudMoveEnabled = true,
        historyHudX = nil,
        historyHudY = nil,
        historyHudStaffX = nil,
        historyHudStaffY = nil,
        --- Chat-Historie-Popup (Protokoll-Fenster)
        historyPopupMoveEnabled = true,
        historyPopupX = nil,
        historyPopupY = nil,
        historyPopupStaffX = nil,
        historyPopupStaffY = nil,
        --- Sound (KVP; nil = Config.Ui.sounds beim ersten NUI-Laden)
        soundNormalEnabled = nil,
        soundStaffEnabled = nil,
        soundNormalVolume = nil,
        soundStaffVolume = nil,
    },
    lastPermissions = {
        canUseMe = true,
        canUseDo = true,
        canUseStaffChat = false,
        staffChatAliases = {}
    },
    --- true = HUD-Nachrichtenliste aus (Streamer); siehe **Config.ChatHistoryUi** / KVP
    historyPrivacyHidden = false,
    overheadTexts = {}
}
