--[[ /me und /do: Config.Me / Config.Do auswerten ]]

EcChat = EcChat or {}

local defaultRpConfig = {
    allow = true,
    identifier = nil
}

--- nil / "" = alle; eine Zeichenkette oder Liste = Whitelist; nur "" in Liste = wie „alle“; {} = niemand
local function playerMatchesIdentifierRule(playerSrc, identifierRule)
    if identifierRule == nil or identifierRule == "" then
        return true
    end

    if type(identifierRule) == "string" then
        identifierRule = { identifierRule }
    end

    if type(identifierRule) ~= "table" then
        return false
    end

    if #identifierRule == 0 then
        return false
    end

    local nonempty = {}
    for _, required in ipairs(identifierRule) do
        if type(required) == "string" and required ~= "" then
            nonempty[#nonempty + 1] = required
        end
    end

    if #nonempty == 0 and #identifierRule > 0 then
        return true
    end

    if #nonempty == 0 then
        return false
    end

    local playerIdentifiers = GetPlayerIdentifiers(playerSrc)
    for _, required in ipairs(nonempty) do
        for _, have in ipairs(playerIdentifiers) do
            if have == required then
                return true
            end
        end
    end

    return false
end

--- Flaches Schema: { allow = ?, identifier = ? }
local function isRpCommandAllowedFlat(playerSrc, cfg)
    local c = cfg
    if type(c) ~= "table" then
        c = defaultRpConfig
    end

    if c.allow == false then
        return false
    end

    return playerMatchesIdentifierRule(playerSrc, c.identifier)
end

--- Erkennt benannte Unterblöcke (z. B. moderatoren = { allow = , identifier = })
local function hasNamedRuleBlocks(cfg)
    if type(cfg) ~= "table" then
        return false
    end

    local skip = {
        allow = true,
        identifier = true,
        maxLength = true,
        overheadDuration = true,
        overheadDrawDistance = true,
        permission = true,
        enabled = true,
    }

    for key, rule in pairs(cfg) do
        if type(key) == "string" and not skip[key] and type(rule) == "table" then
            if rule.allow ~= nil or rule.identifier ~= nil then
                return true
            end
        end
    end

    return false
end

--- Benannte Blöcke: Spieler darf, wenn mindestens EINE Regel zutrifft (ODER).
local function isRpCommandAllowedNamed(playerSrc, cfg)
    local skip = {
        allow = true,
        identifier = true,
        maxLength = true,
        overheadDuration = true,
        overheadDrawDistance = true,
        permission = true,
        enabled = true,
    }

    for key, rule in pairs(cfg) do
        if type(key) == "string" and not skip[key] and type(rule) == "table" then
            if rule.allow ~= false then
                if playerMatchesIdentifierRule(playerSrc, rule.identifier) then
                    return true
                end
            end
        end
    end

    return false
end

--- cfg = nil → keine Regel = alle dürfen
function EcChat.IsRpCommandAllowed(playerSrc, cfg)
    if cfg == nil then
        return true
    end

    if type(cfg) ~= "table" then
        return isRpCommandAllowedFlat(playerSrc, defaultRpConfig)
    end

    if hasNamedRuleBlocks(cfg) then
        return isRpCommandAllowedNamed(playerSrc, cfg)
    end

    return isRpCommandAllowedFlat(playerSrc, cfg)
end

function EcChat.GetPermissionsForPlayer(playerSrc)
    return {
        canUseMe = EcChat.IsRpCommandAllowed(playerSrc, EcChat.RpPermissionRules("me")),
        canUseDo = EcChat.IsRpCommandAllowed(playerSrc, EcChat.RpPermissionRules("do")),
        canUseStaffChat = EcChat.IsStaffChatMember(playerSrc),
        staffChatAliases = EcChat.GetStaffChatAliases()
    }
end
