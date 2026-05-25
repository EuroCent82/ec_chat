--[[
  DB-Zugriffe gemäß **Config.MySQL** (Zeichenkette in **config.lua**):

  • **`"oxmysql"`** oder **`""`** (Empfehlung: als **"oxmysql"** dokumentieren/setzen): **exports oxmysql**, Platzhalter **?**.
  • **`mysql-async`**: **MySQL.Async** — **`@mysql-async/lib/MySQL.lua`** vor anderen **server_scripts** (fxmanifest.lua).
]]

EcChat = EcChat or {}

--- Interne Unterscheidung für die beiden unterstützten Modi.
local function normalizedMysqlChoice()
    local raw = rawget(Config, "MySQL")
    if raw == nil then
        raw = ""
    end
    if type(raw) ~= "string" then
        raw = ""
    end
    local s = raw:lower():gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", "")
    if s == "mysql-async" or s == "mysql_async" then
        return "mysql-async"
    end
    return "oxmysql"
end

--- Resource mit oxmysql‑Exports (**fest** **`oxmysql`**).
function EcChat.MySqlResourceName()
    return "oxmysql"
end

--- @return '"oxmysql"' | '"mysql-async"'
function EcChat.MySqlFlavour()
    return normalizedMysqlChoice()
end

--- Bei mysql-async: Resource-State **fest** **`mysql-async`**.
function EcChat.MySqlAsyncResourceName()
    return "mysql-async"
end

function EcChat.ValidateSqlTableName(id)
    return type(id) == "string" and id ~= "" and id:find("^[%w_]+$") ~= nil
end

function EcChat.MySqlExports()
    local res = EcChat.MySqlResourceName()
    local ok, ex = pcall(function()
        return exports[res]
    end)
    if ok and type(ex) == "table" then
        return ex
    end
    return nil
end

--- Wartet bis die für den gewählten Flavour nötige Resource läuft.
function EcChat.WaitForMysqlDependency()
    if EcChat.MySqlFlavour() == "mysql-async" then
        local ar = EcChat.MySqlAsyncResourceName()
        while GetResourceState(ar) ~= "started" do
            Wait(200)
        end
        return
    end
    local r = EcChat.MySqlResourceName()
    while GetResourceState(r) ~= "started" do
        Wait(200)
    end
end

--- Optional: Schnell-check vor einzelnem Insert (Historie).
function EcChat.MySqlDriverReady()
    if EcChat.MySqlFlavour() == "mysql-async" then
        if GetResourceState(EcChat.MySqlAsyncResourceName()) ~= "started" then
            return false
        end
        if not (MySQL and MySQL.Async) then
            return false
        end
        return true
    end
    local ex = EcChat.MySqlExports()
    return ex ~= nil and (type(ex.execute) == "function" or type(ex.query) == "function")
end

local function oxFetchAllCb(sql, cb)
    cb = cb or function() end
    local res = EcChat.MySqlResourceName()
    local ex = EcChat.MySqlExports()
    if not ex then
        print(('[ec_chat_theme] MySql: keine Exports unter Resource „%s“'):format(res))
        cb({})
        return
    end
    if type(ex.query) == "function" then
        ex:query(sql, {}, cb)
        return
    end
    if type(ex.execute) == "function" then
        ex:execute(sql, {}, cb)
        return
    end
    print(('[ec_chat_theme] Resource „%s“: weder „query“ noch „execute“. Config.MySQL / ensure prüfen.'):format(res))
    cb({})
end

local function oxExecutePlaceholder(sqlWithQ, positional, cb)
    cb = cb or function() end
    local res = EcChat.MySqlResourceName()
    local ex = EcChat.MySqlExports()
    if not ex or type(ex.execute) ~= "function" then
        print(('[ec_chat_theme] MySql INSERT: unter „%s“ fehlt export „execute“. Config.MySQL prüfen.'):format(res))
        cb()
        return
    end
    ex:execute(sqlWithQ, positional or {}, cb)
end

local function mysqlAsyncWarnMissing()
    print(
        "[ec_chat_theme] MySql: Config.MySQL ist mysql-async, aber globales Objekt „MySQL“ fehlt — in fxmanifest unter server_scripts '@mysql-async/lib/MySQL.lua' eintragen.")
end

local function mysqlAsyncWarnAsync()
    print("[ec_chat_theme] MySql: gewählt mysql-async — „mysql-async“ nicht gestartet (ensure?).")
end

--- `SELECT`-artige Zeilen (keine Platzhalter; nur bereits validierte Identifiers im SQL eingebunden).
--- @param cb function(rows:table)
function EcChat.MySqlFetchAll(sql, cb)
    cb = cb or function() end

    if EcChat.MySqlFlavour() == "mysql-async" then
        local ar = EcChat.MySqlAsyncResourceName()
        if GetResourceState(ar) ~= "started" then
            mysqlAsyncWarnAsync()
            cb({})
            return
        end
        if not (MySQL and MySQL.Async and type(MySQL.Async.fetchAll) == "function") then
            mysqlAsyncWarnMissing()
            cb({})
            return
        end
        MySQL.Async.fetchAll(sql, {}, function(rows)
            cb(type(rows) == "table" and rows or {})
        end)
        return
    end

    oxFetchAllCb(sql, cb)
end

local function mysqlAsyncNamedInsert(tblValidated, pname, playerSrc, ident, msg, cb)
    cb = cb or function() end
    local sql = ("INSERT INTO `%s` (`playername`, `playerid`, `identifier`, `message`) VALUES (@playername, @playerid, @identifier, @message)"):format(tblValidated)
    if not (MySQL and MySQL.Async and type(MySQL.Async.execute) == "function") then
        mysqlAsyncWarnMissing()
        cb()
        return
    end
    MySQL.Async.execute(sql, {
        ["@playername"] = pname,
        ["@playerid"] = playerSrc,
        ["@identifier"] = ident,
        ["@message"] = msg,
    }, cb)
end

--- INSERT **chat_history**: **`?`** (oxmysql) oder **`@name`** (mysql-async) je nach **`Config.MySQL`**.
function EcChat.MySqlInsertChatHistoryRow(tblValidated, pname, playerSrc, ident, msg)
    tblValidated = tostring(tblValidated or "")
    if not EcChat.ValidateSqlTableName(tblValidated) then
        print("[ec_chat_theme] ChatHistory: ungültiger Tabellenname.")
        return
    end

    if EcChat.MySqlFlavour() == "mysql-async" then
        local ar = EcChat.MySqlAsyncResourceName()
        if GetResourceState(ar) ~= "started" then
            mysqlAsyncWarnAsync()
            return
        end
        mysqlAsyncNamedInsert(tblValidated, pname, playerSrc, ident, msg)
        return
    end

    local sqlOx = ("INSERT INTO `%s` (`playername`, `playerid`, `identifier`, `message`) VALUES (?, ?, ?, ?)"):format(tblValidated)
    oxExecutePlaceholder(sqlOx, {
        pname,
        playerSrc,
        ident,
        msg,
    })
end
