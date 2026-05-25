--[[
  Erkennung echter RP-Slash-Zeilen `/me` und `/do` ohne Präfix-Fallen:

  • `/doorlock`, `/doing`, `/document` dürfen **nicht** als `/do` zählen
    (`sub(1,3)=="/do"` oder `startswith("/do")` ist falsch).
  • Gleiches Muster für `/me` gegenüber längeren Befehlen (`/mess…` wird nicht `/me`).
]]

EcChat = EcChat or {}

--- @param lowerTrimmedLine gesamte Zeile, bereits **lowercase**, führende/trailing Spaces entfernt
--- @param verb **"me"** oder **"do"**
function EcChat.SlashRpVerbBoundary(lowerTrimmedLine, verb)
    if type(lowerTrimmedLine) ~= "string" or type(verb) ~= "string" or verb == "" then
        return false
    end
    verb = verb:lower()
    if verb ~= "me" and verb ~= "do" then
        return false
    end

    local p = "/" .. verb
    if lowerTrimmedLine == p then
        return true
    end

    --- Genau Slash + Verb + Leerzeichen (+ optional Rest)
    return lowerTrimmedLine:sub(1, #p + 1) == (p .. " ")
end
