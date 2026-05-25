--[[ /me · /do — ein Block je Befehl: `Config.Me` / `Config.Do` (Berechtigung, Länge, Overhead).
    Abwärtskompatibel: `nil`, flache/benannte `permission`-Tabellen, alte `Config.RpTextLimits` / `Config.RpOverhead*`. ]]

EcChat = EcChat or {}

local META_KEYS = {
    maxLength = true,
    overheadDuration = true,
    overheadDrawDistance = true,
    permission = true,
    enabled = true,
}

local function clampLimit(raw, fallback)
    local n = tonumber(raw)
    if not n or n < 1 then
        return fallback
    end
    return math.floor(math.min(n, 2000))
end

local function clampMs(raw, fallback)
    local n = tonumber(raw)
    if not n or n < 0 then
        return fallback
    end
    return math.floor(n)
end

local function clampDist(raw, fallback)
    local n = tonumber(raw)
    if not n or n < 0 then
        return fallback
    end
    return n + 0.0
end

function EcChat.RpCommandBlock(kind)
    if kind == "do" then
        return Config.Do
    end
    return Config.Me
end

local function usesNewMeDoShape(cfg)
    if type(cfg) ~= "table" then
        return false
    end
    for key in pairs(cfg) do
        if META_KEYS[key] then
            return true
        end
    end
    return false
end

--- Nur Berechtigungs-Regeln (`nil` = alle); nicht die ganze `Config.Me`-Tabelle mit Meta-Feldern.
function EcChat.RpPermissionRules(kind)
    local cfg = EcChat.RpCommandBlock(kind)
    if cfg == nil then
        return nil
    end
    if type(cfg) ~= "table" then
        return nil
    end
    if usesNewMeDoShape(cfg) then
        return cfg.permission
    end
    return cfg
end

function EcChat.RpMeMaxLength()
    local cfg = EcChat.RpCommandBlock("me")
    if type(cfg) == "table" and cfg.maxLength ~= nil then
        return clampLimit(cfg.maxLength, 120)
    end
    local legacy = rawget(Config, "RpTextLimits")
    if type(legacy) == "table" then
        return clampLimit(legacy.meMaxLength, 120)
    end
    return 120
end

function EcChat.RpDoMaxLength()
    local cfg = EcChat.RpCommandBlock("do")
    if type(cfg) == "table" and cfg.maxLength ~= nil then
        return clampLimit(cfg.maxLength, 120)
    end
    local legacy = rawget(Config, "RpTextLimits")
    if type(legacy) == "table" then
        return clampLimit(legacy.doMaxLength, 120)
    end
    return 120
end

function EcChat.RpOverheadDuration(kind)
    local cfg = EcChat.RpCommandBlock(kind)
    if type(cfg) == "table" and cfg.overheadDuration ~= nil then
        return clampMs(cfg.overheadDuration, 12000)
    end
    return clampMs(rawget(Config, "RpOverheadDuration"), 12000)
end

function EcChat.RpOverheadDrawDistanceForKind(kind)
    local cfg = EcChat.RpCommandBlock(kind)
    if type(cfg) == "table" and cfg.overheadDrawDistance ~= nil then
        return clampDist(cfg.overheadDrawDistance, 25.0)
    end
    return clampDist(rawget(Config, "RpOverheadDrawDistance"), 25.0)
end

function EcChat.RpOverheadDrawDistance()
    local me = EcChat.RpOverheadDrawDistanceForKind("me")
    local distDo = EcChat.RpOverheadDrawDistanceForKind("do")
    return math.max(me, distDo)
end

function EcChat.ValidateRpMessageText(kind, text)
    if type(text) ~= "string" then
        return false, "empty"
    end
    local msg = text:gsub("^%s+", ""):gsub("%s+$", "")
    if msg == "" then
        return false, "empty"
    end
    local maxLen = kind == "do" and EcChat.RpDoMaxLength() or EcChat.RpMeMaxLength()
    if #msg > maxLen then
        return false, kind == "do" and "do_too_long" or "me_too_long"
    end
    return true, nil
end

function EcChat.RpTextLimitsPayload()
    return {
        meMaxLength = EcChat.RpMeMaxLength(),
        doMaxLength = EcChat.RpDoMaxLength(),
    }
end
