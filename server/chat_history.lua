--[[ Persistente Chat-Zeilen (**chat_history**) gemäß **Config.MySQL** / `server/mysql_adapter.lua` ]]

EcChat = EcChat or {}

local function primaryIdentifier(playerSrc)
    local ids = GetPlayerIdentifiers(playerSrc)
    if type(ids) ~= "table" then
        return "unknown"
    end
    for _, id in ipairs(ids) do
        if type(id) == "string" and id:sub(1, 8) == "license:" then
            return id
        end
    end
    if ids[1] then
        return tostring(ids[1])
    end
    return "unknown"
end

local function clampMessage(msg)
    if type(msg) ~= "string" then
        return ""
    end
    if #msg > 2000 then
        return msg:sub(1, 2000)
    end
    return msg
end

--- messageKind: z. B. "global", "me", "do", "staff", "slash" (nur zur Dokumentation im caller).
function EcChat.LogChatHistory(playerSrc, message, messageKind)
    local cfg = Config.ChatHistoryDatabase
    if type(cfg) ~= "table" or cfg.enabled ~= true then
        return
    end

    if type(playerSrc) ~= "number" or playerSrc <= 0 then
        return
    end

    local tbl = cfg.table
    if type(tbl) ~= "string" or tbl == "" then
        tbl = "chat_history"
    end
    if not EcChat.ValidateSqlTableName(tbl) then
        print("[ec_chat_theme] ChatHistoryDatabase: unzulässiger Tabellenname — INSERT übersprungen.")
        return
    end

    if not EcChat.MySqlDriverReady() then
        print(
            "[ec_chat_theme] ChatHistoryDatabase.enabled ist true, aber der MySQL-Treiber nicht bereit — überspringe Insert (siehe Config.MySQL / ensure in server.cfg).")
        return
    end

    local pname = GetPlayerName(playerSrc) or ("Player %d"):format(playerSrc)
    local ident = primaryIdentifier(playerSrc)
    local msg = clampMessage(message)

    EcChat.MySqlInsertChatHistoryRow(tbl, pname, playerSrc, ident, msg)
end
