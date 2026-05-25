--[[
  ec_chat_theme — Hauptkonfiguration

  Ausführliche Erklärungen, Beispiele und Hinweise (Deutsch): siehe readme_config.md
]]

Config = {}

--------------------------------------------------------------------------------
-- 1) Zentral · Infrastruktur
--    Wirkt auf Server- und Clientlogik (Debug-UI, DB-Zugriff für Historie/Items).
--------------------------------------------------------------------------------

--- Reserviert / Entwicklung: `true` = Debug-Button und Analysepanel in der NUI sowie erweiterte Slash-Diagnose (siehe `Config.Chat.slash`).
Config.Debug = false

  --- Beim Serverstart: fxmanifest-`version` mit GitHub-Release vergleichen (Console-Hinweis).
Config.VersionCheck = {
  enabled = true,
  repository = "EuroCent82/ec_chat",
  delayMs = 1500,
  --- `true`: auch „Version aktuell“ in der Konsole (sonst nur bei veralteter Version).
  printWhenUpToDate = true,
  --- `false`: HTTP-Fehler stumm (nur bei `Config.Debug`); Standard: Fehler kurz loggen.
  logErrors = true,
}

--- MySQL-Anbindung: **`"oxmysql"`** (Standard; Resource fest **`oxmysql`**) oder **`"mysql-async"`**.
--- Leere Zeichenfolge **`""`** verhält sich wie **`"oxmysql"`** (Abwärtskompatibilität).
--- Bei **mysql-async**: `ensure mysql-async` und in **fxmanifest.lua** `@mysql-async/lib/MySQL.lua` vor anderen **server_scripts** (siehe Kommentare dort).
Config.MySQL = "oxmysql"

--- Inventarmodell nur für Slash-Autocomplete (Items/Waffen-Tabellen) — **`shared/sql_inventory.lua`**:
--- **`nil`**, **`""`**, **`standard`**, **`esx`** (klassisches **ESX**): **`giveitem`** → **`tables.items`**. **`tables.weapons`** + **`giveweapon`** nur wenn ihr natives **`/giveweapon`** wirklich nutzt (**nicht nötig**, wenn Waffen **nur** per **`giveitem`** aus **`items`** kommen wie bei ox). Dort optional **`giveitemSuggestPrefix`** (zweite Tab. für eingeschränkte **`giveitem`**‑Vorschläge).
--- **`ox_inventory`** / **`ox`**: **`giveitem`** + **`tables.items`** — auch Waffengegenstände **`items`**; **`weapon_*`** filtert dort. **`tables.weapons`** wird nicht verwendet (**`giveitemSuggestPrefix`** entfällt).
Config.Inventory = "ox"

--------------------------------------------------------------------------------
-- 2) RP · `/me` und `/do` — **alles pro Befehl** in `Config.Me` / `Config.Do`
--
--    **`permission`**: `nil` = alle dürfen · flach `{ allow, identifier }` · benannte Blöcke (ODER).
--    **`maxLength`**: Zeichenlimit RP-Text (Zähler im Chat, kein Abschneiden).
--    **`overheadDuration`** / **`overheadDrawDistance`**: 3D-Text über dem Kopf.
--
--    Legacy (wird noch gelesen): ganzes `Config.Me`/`Config.Do` nur als Berechtigungstabelle **ohne** Meta-Felder.
--------------------------------------------------------------------------------

Config.Me = {
  maxLength = 120,
  overheadDuration = 12000,
  overheadDrawDistance = 25.0,
  --- `nil` = jeder darf /me
  permission = nil,
}

Config.Do = {
  maxLength = 120,
  overheadDuration = 12000,
  overheadDrawDistance = 25.0,
  permission = nil,
}

--[[  Berechtigung einschränken — `permission` ersetzen:

Config.Me = {
  maxLength = 120,
  overheadDuration = 12000,
  overheadDrawDistance = 25.0,
  permission = {
    team = {
      allow = true,
      identifier = { "license:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" },
    },
    alle = { allow = true, identifier = nil },
  },
}
]]

--------------------------------------------------------------------------------
-- 3) Chat-Verhalten (NUI-Fokus, Standard-Chat, Slash)
--------------------------------------------------------------------------------

Config.Chat = {
  --- Während Chat offen: Gameplay blocken (z. B. H = Hände heben)
  focus = {
    blockGameplayControls = true,
  },

  --- FiveM-System-Chat / Resource `chat` (SetTextChatEnabled, chatMessage)
  suppressDefault = {
    enabled = true,
    cancelChatMessageEvent = true,
    warnIfChatResourceRunning = true,
  },

  --- Slash nach Schließen der NUI (Timing, doorlock, Diagnose)
  slash = {
    deferredExecuteDelayMs = 75,
    doorlockExecuteFallbackDelayMs = 450,
    doorlockCommandPrincipal = nil,
    debugSlashRelay = false,
  },

  --- Say /me /do: nur in Nähe empfangen (HUD + Chat). Staff-Chat bleibt global.
  proximity = {
    enabled = true,
    --- Meter (Empfehlung 25–50)
    sayDistance = 35.0,
  },
}

--------------------------------------------------------------------------------
-- 5) Staff-/Team-Chat (ACE, eigene Kommando-Aliasse)
--------------------------------------------------------------------------------

Config.StaffChat = {
  --- false = Staff-Chat und Aliasse komplett aus
  enabled = true,

  --- Slash ohne `/`, nach Normalisierung klein — ein String oder eine Liste von Aliassen
  command = { "a", "t" },

  --- Namen wie in **server.cfg** / ESX **`/setgroup`** (ohne `group.`). Beispiel Euro-Test: **`txadmin`** + **`admin`**.
  groups = {
    "admin",
    "txadmin",
  },

  --- FiveM-ACE: Spieler mit **`add_ace group.<X> command allow`** (z. B. **group.txadmin** in eurer server.cfg).
  permissionAces = {
    "command",
  },

  --- **`true`**: ESX **`xPlayer.getGroup()`** gegen **`groups`** (txAdmin/ESX **`setgroup … admin`**).
  trustEsxGroup = false,

  --- **`true`**: txAdmin-Panel-Admin nach F4-Menü-Auth (**`txAdmin:events:adminAuth`**).
  trustTxAdmin = false,

  --- Zusätzliche Principals **vollständig** (OR zu allem oben).
  aceAllow = {
    --- "qbcore.admin",
  },

  --- Farbe `{ R, G, B }` oder leer `{}` für Standard-Rotton (NUI: Klasse `chat-line--staff`)
  color = {},
}

--- Diagnose **`/checkgroup`** — prüft FiveM-ACE **`group.<name>`** (siehe **`StaffChat.groups`**), **nicht** txAdmin-Panel-`setgroup`.
Config.CheckGroup = {
  --- **`false`**: `/checkgroup` (F8, Chat, Server-Event) komplett aus — z. B. Live-Server ohne Diagnose-Command
  enabled = false,

  --- **`true`**: ox_lib / QBCore / ESX / GTA-Feed (je nach Server)
  notify = false,
  --- Zusätzlich eine Zeile in der EC-Chat-Liste (nur sinnvoll wenn der Chat offen bleibt)
  alsoChat = false,
  --- Bei „keine Gruppe“: deine **license:** in der Notify + Beispiel-`server.cfg`-Zeilen
  showLicenseHint = true,
  --- Nur Diagnose: weitere ACE-Strings testen (z. B. ob du **`group.superadmin`** hast, aber nicht **`group.admin`**)
  probeAce = {
    "group.superadmin",
    "group.god",
    "group.mod",
    "group.moderator",
    "group.admin",
  },
  --- **`true`** = kompletter Report in die **Server-Konsole** (txAdmin Live / FXServer) · **`nil`** = nur bei **`Config.Debug`**
  serverLog = false,
}

--------------------------------------------------------------------------------
-- 6) Datenbank · Kataloge für Slash-Autocomplete — ein **`Config.SQL`**, Steuerung über **`Config.Inventory`** (readme_config.md)
--    Benötigt lauffähigen Treiber gemäß `Config.MySQL` und passende Tabellen.
--------------------------------------------------------------------------------

Config.SQL = {
  --- Gesamtschalter für serverseitige SQL-Features (Katalog-Vorschläge)
  enabled = true,

  --- Mindestlänge der Suchzeichenkette, bevor der Server filtert (`requestId`)
  minSuggestionChars = 1,

  --- Maximale Treffer pro Antwort (Server sortiert nach Relevanz)
  maxSuggestionResults = 30,

  --- Wartezeit (ms) im NUI vor der Server-Anfrage (Debouncing gegen Tipp-Spam)
  itemSuggestDebounceMs = 180,

  --- Optional: gleiche Ace-„Gruppen“-Logik wie Staff — ohne `group.`-Präfix. Erlaubt Item-Vorschlags-Anfragen, wenn `command.<befehl>` nicht gesetzt ist (z. B. nur ACE `group.admin` auf dem Dev-Server).
  --- Leere Liste `{}` = nur noch `command.<alias>` (siehe `server/item_suggest.lua`).
  itemSuggestAceGroups = {
    "admin",
  },

  --- **`tables`** (Kurzfassung)
  --- • **Ox_inventory** (**`Config.Inventory`** = **`ox_inventory`** / **`ox`**): **`giveitem`**‑Autocomplete = **`tables.items`** **plus** (Standard in dieser **`config.lua`**) Merge aus **`tables.items.weaponNameMerge`** (**typisch:** DB‑Tabelle **`weapons`** mit **`name`/`label`** — oft enthält **`items`** den **`weapon_*`‑Code nicht**, dann kommen Treffer nur über den Merge). Block **`tables.weapons`** ⇒ **`nil`** (**`/giveweapon`**‑Konfig wird unter Ox nicht genutzt).
  --- • **Klassisches ESX** (**`Config.Inventory`** = **`nil`** / **`esx`** …): Standard **`giveitem`** → **`items`**. Zusätzlich **`giveweapon`** nur wenn ihr das Kommando wirklich nutzt → dann eigener **`tables.weapons`** (z.B. `weapons` / `weapons`-View). **`giveitemSuggestPrefix`** dort optional, wenn ihr **wirklich** zweite Tab. für **`giveitem`** braucht.
  --- ALT (Abwärtskompatibilität): **`giveitemSuggestWeaponsPrefix`** unter **`items.autocomplete`**.

  tables = {
    items = {
      table = "items",
      name = "name",
      label = "label",
      --- **Nur Ox:** zusätzliche Zeilen für **`giveitem`**‑Autocomplete (**ein** Pool mit **`items`**, Duplikate fallen weg).
      ---
      --- **`weaponNameMerge = false`** ⇒ zweiten **`SELECT`** abschalten (**nur** **`items`**).
      ---
      --- Standard unten: **`weapons`** (**`name`**, **`label`**) wie klassisches ESX — bei anderem Tabellen-/Spaltennamen hier anpassen (z. B. Tippfehler **`wepaons`**).
      ---
      weaponNameMerge = {
        table = "weapons",
        name = "name",
        label = "label",
      },
      autocomplete = {
        --- Bei **ox_inventory** (`Config.Inventory`): „Waffen“ sind hier **wie jedes andere Item** — du vergibst sie mit **`giveitem`**; **`weapon_*`‑Text** kommt in die Liste über **`weaponNameMerge`** **oder** muss bereits in **`items`** stehen.
        enabled = true,
        --- `aliases` ohne `/` · `completeParamIndex`: Positionszahl des zu vervollständigenden Arguments (Bsp. unter readme_config.md)
        commands = {
          {
            aliases = { "giveitem", "give_item" },
            completeParamIndex = 2,
          },
        },
      },
    },

    --- Bei **Ox** (`Config.Inventory` = **`ox`** / **`ox_inventory`**): **`weapons = nil`** — Waffen vergebt ihr mit **`giveitem`**; die DB‑**`weapons`**‑Tabelle steckt unter **`tables.items.weaponNameMerge`** (**Slash‑Autocomplete**, nicht **`tables.weapons`**).
    ---
    --- **Nur klassisches ESX:** Block **`giveweapon`** + ggf. **`giveitemSuggestPrefix`** nur aktiv, wenn ihr **kein Ox** nutzt und wirklich eine **zweite** Tab. (**`giveweapon`**) verwendet.
    --[[ ohne ox_inventory, mit giveweapon — Beispiel (auskommentiert):
    weapons = {
      table = "weapons",
      name = "name",
      label = "label",
      giveitemSuggestPrefix = nil,
      autocomplete = {
        enabled = true,
        commands = { { aliases = { "giveweapon", "give_weapon" }, completeParamIndex = 2 } },
      },
    },
    ]]
    weapons = nil,
  },
}

--------------------------------------------------------------------------------
-- 7) UI · Darstellung (Kopfzeile, lokaler HUD-Verlauf)
--------------------------------------------------------------------------------

Config.Ui = {
  --- Drag-Handle: Marke + Badge
  brand = {
    title = "EC CHAT",
    badge = "LIVE",
  },

  --- Lokaler Verlauf im HUD (keine MySQL) — Abschnitt 8 DB separat
  history = {
    enabled = true,
    maxHistoryMessages = 15,
    visibleHistoryLines = 5,
    autoHideHistoryMs = 12000,
    toggleCommand = "chat",
    --- toggleKey = "F10",
    persistStreamerPrivacyInKvp = true,
  },

  --- 8-Bit-Piep bei eingehenden Nachrichten (NUI, `assets/sounds/*.wav`)
  sounds = {
    --- Ein kurzer Piep für Say /me /do / System (nur wenn Chat **zu** ist)
    enabled = true,
    --- Piep-Piep für Staff-Chat (immer, auch bei offenem Chat)
    staffEnabled = true,
    --- Lautstärke normaler Chat 0.0–1.0
    volume = 0.35,
    --- Lautstärke Staff-Chat 0.0–1.0
    staffVolume = 0.50,
    --- Zusätzliche Spieler-Notify (ox_lib / QBCore / ESX / GTA-Feed) bei Staff-Nachricht, wenn Chat zu ist
    staffNotifyWhenClosed = true,
  },
}

--------------------------------------------------------------------------------
-- 8) Datenbank · Persistente Chat-Historie (`chat_history`-Tabelle)
--    `enabled = false` nur als Not-Aus; Normalbetrieb mit gültiger Migration (siehe `sql/chat_history.sql`).
--------------------------------------------------------------------------------

--[[
  Spalten: playername (GetPlayerName), playerid (source), identifier (license:…), message, created_at.
]]

Config.ChatHistoryDatabase = {
  --- INSERT über `server/mysql_adapter.lua` gemäß `Config.MySQL`
  enabled = true,

  --- Zieltabelle nach eurer Migration — Standard wie beiliegende SQL
  table = "chat_history",
}
