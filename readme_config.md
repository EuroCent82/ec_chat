# Konfigurationshandbuch · `config.lua`

Vollständige Referenz zu **`config.lua`** der Resource **ec_chat** (Projekt **ec_chat_theme**). Sprache: **Deutsch**.

> **Überblick, Installation, Bedienung:** [`README.md`](./README.md)  
> **UI-only Einstellungen** (Position, Historie-Popup — ohne `config.lua`): [Anhang A](#anhang-a--ui-einstellungen-nicht-in-configlua)

---

## Inhaltsverzeichnis

1. [Reihenfolge der Blöcke](#reihenfolge-der-blöcke)
2. [Zentral: Debug, MySQL, Inventory](#1--zentral-debug-mysql-configinventory)
3. [RP: `/me` und `/do`](#2--rp-me-und-do-configme-configdo)
4. [Chat-Verhalten](#3--chat-verhalten-configchat)
5. [Staff-Chat und CheckGroup](#5--staff-chat-configstaffchat--configcheckgroup)
6. [SQL und Autocomplete](#6--sql-inventar-modell-configinventory--configsql)
7. [UI: Kopfzeile und HUD-Verlauf](#7--ui-configui)
8. [Persistente DB-Historie](#8--persistente-historie-configchathistorydatabase)
11. [Checkliste](#kurz-checkliste-nach-änderungen)
12. [Anhang A: UI-Einstellungen (KVP)](#anhang-a--ui-einstellungen-nicht-in-configlua)

---

## Reihenfolge der Blöcke

Die Datei **`config.lua`** bündelt verwandte Einstellungen — **ein Ort pro Thema**:

| Nr. | `config.lua`-Abschnitt | Zentralität |
| --- | --- | --- |
| **1** | `Config.Debug`, `Config.MySQL`, `Config.Inventory` | **Zentral** — Debug, DB, Inventar-Modell |
| **2** | `Config.Me`, `Config.Do` | **RP** — Berechtigung, Zeichenlimit, 3D-Overhead **je Befehl** |
| **3** | `Config.Chat` | **Chat** — Fokus, Standard-Chat unterdrücken, Slash-Timing |
| **5** | `Config.StaffChat`, `Config.CheckGroup` | **Team-Chat** + Diagnose |
| **6** | `Config.SQL` | **DB-Kataloge** für Autocomplete |
| **7** | `Config.Ui` | **NUI** — `brand`, `history` (lokaler HUD-Verlauf) |
| **8** | `Config.ChatHistoryDatabase` | **MySQL-Protokollierung** |

**Abwärtskompatibel:** Alte Top-Level-Keys (`Config.RpTextLimits`, `Config.ChatSlash`, `Config.UiBrand`, …) werden von **`shared/rp_command_config.lua`** und **`shared/config_access.lua`** weitergelesen, falls ihr sie noch nicht migriert habt.

---

## 1 · Zentral: Debug, MySQL (`Config.Inventory`)

### `Config.Debug` (boolean)

| Wert | Wirkung |
| --- | --- |
| **`true`** | Debug-Button und Analyse-Panel in der **NUI**; Slash-Diagnose standardmäßig mit aktiv (zusätzlich zu `Config.Chat.slash.debugSlashRelay`, siehe Abschnitt 3). |
| **`false`** | Empfohlen für **Live-Server** — weniger UI und Konsolenrauschen. |

### `Config.MySQL` (Zeichenkette)

Legt den **MySQL-/MariaDB-Stack** fest (`server/mysql_adapter.lua`).

| Wert | Bedeutung |
| --- | --- |
| **`"oxmysql"`** | **Empfohlen:** `exports["oxmysql"]` mit `query` / `execute`, Platzhalter **`?`**. |
| **`""`** | Wie **`"oxmysql"`** (Abwärtskompatibilität). |
| **`"mysql-async"`** | `MySQL.Async` — zusätzlich `@mysql-async/lib/MySQL.lua` in **`fxmanifest.lua`** **vor** den `server_scripts`. |

**Umgebung:**

- **oxmysql:** `ensure oxmysql` in **`server.cfg`**, dann diese Resource.
- **mysql-async:** `ensure mysql-async` + Manifest-Anpassung.
- **Verbindungsdaten** (Host, DB-Name, Zugang) liegen **nicht** in dieser Resource — nur in oxmysql/mysql-async wie beim Rest des Servers.

### `Config.Inventory` (Zeichenkette)

Steuert **`shared/sql_inventory.lua`** — welche Tabellen und Slash-Pfade für **Item-/Waffen-Autocomplete** gelten (Abschnitt 6).

| Wert | Bedeutung |
| --- | --- |
| **`nil`**, **`""`**, **`"standard"`**, **`"esx"`** | Klassisches ESX: **`giveitem`** → `tables.items`; optional **`giveweapon`** → `tables.weapons`; optional **`giveitemSuggestPrefix`** als Brücke. |
| **`"ox_inventory"`**, **`"ox"`** | Nur **`giveitem`** / **`tables.items`**; Waffen als Items; optional **`weaponNameMerge`**; **`tables.weapons`** wird **ignoriert**. |

---

## 2 · RP: `/me` und `/do` (`Config.Me`, `Config.Do`)

**Alles zu einem Befehl in einem Block** — kein separates `RpTextLimits` / `RpOverhead*` mehr nötig.

| Feld | Typ | Bedeutung |
| --- | --- | --- |
| **`maxLength`** | Zahl | Max. Zeichen im RP-Text (ohne `/me` bzw. `/do`); UI-Zähler, Server lehnt ab — kein Abschneiden. |
| **`overheadDuration`** | Zahl (ms) | 3D-Text über dem Kopf (z. B. **12000**). |
| **`overheadDrawDistance`** | Zahl (m) | Entfernung, ab der andere Clients den Text nicht mehr zeichnen. |
| **`permission`** | `nil` oder Tabelle | Wer den Befehl nutzen darf (siehe unten). |

### `permission = nil` = alle dürfen

Entspricht früher **`Config.Me = nil`** / **`Config.Do = nil`**.

### Berechtigung in `permission` (benannte Blöcke oder flach)

Unter **`permission`** gilt dieselbe Logik wie früher in der ganzen `Config.Me`-Tabelle:

| Feld | Bedeutung |
| --- | --- |
| **`allow`** | `true` / `false` |
| **`identifier`** | `nil` = alle (wenn erlaubt); Liste = Whitelist; `{ }` = niemand |

**ODER:** Mindestens ein passender Block → Zugriff.

### Beispiel (Team + alle)

```lua
Config.Me = {
  maxLength = 120,
  overheadDuration = 12000,
  overheadDrawDistance = 25.0,
  permission = {
    team = {
      allow = true,
      identifier = { "license:d123...", "license:d456..." },
    },
    oeffentlich = { allow = true, identifier = nil },
  },
}
```

### Legacy (ohne Migration)

- Ganzes **`Config.Me`/`Config.Do` nur als Berechtigungstabelle** (ohne `maxLength`, `permission`, …) — wie bisher.
- Alte Keys **`Config.RpTextLimits`**, **`Config.RpOverheadDuration`**, **`Config.RpOverheadDrawDistance`** — werden noch gelesen, wenn die neuen Felder fehlen.

---

## 3 · Chat-Verhalten (`Config.Chat`)

### `Config.Chat.focus`

| Feld | Bedeutung |
| --- | --- |
| **`blockGameplayControls`** | **`true`**: während Chat offen keine Gameplay-Tasten (z. B. **H**). |

### `Config.Chat.suppressDefault`

| Feld | Bedeutung |
| --- | --- |
| **`enabled`** | **`SetTextChatEnabled(false)`** usw. |
| **`cancelChatMessageEvent`** | **`chatMessage`** blocken |
| **`warnIfChatResourceRunning`** | Hinweis, wenn Resource **`chat`** noch läuft |

### `Config.Chat.slash`

Nach Schließen der NUI braucht `ExecuteCommand` oft eine kurze Verzögerung.

| Feld | Typ | Bedeutung |
| --- | --- | --- |
| **`deferredExecuteDelayMs`** | Zahl | Pause (ms) vor `ExecuteCommand` (normale Slash-Zeilen). |
| **`doorlockExecuteFallbackDelayMs`** | Zahl | Längere Pause nur für doorlock-Fallback. |
| **`doorlockCommandPrincipal`** | `nil` oder String | `nil` = Principal aus `ox_doorlock/config.lua`. |
| **`debugSlashRelay`** | boolean | Zusätzliche Slash-Relay-Logs (F8 / txAdmin). |

---

## 5 · Staff-Chat (`Config.StaffChat`) · `Config.CheckGroup`

### `Config.StaffChat`

| Feld | Bedeutung |
| --- | --- |
| **`enabled`** | `false` = Staff-Chat und Aliasse komplett aus. |
| **`command`** | String **oder** Liste — Aliasse **ohne** `/`, Kleinbuchstaben (z. B. `"a"`, `"t"` → `/a`, `/t`). Funktioniert auch in der **F8-Zeile** ohne Slash (`RegisterCommand`). |
| **`groups`** | ACE-Gruppen **ohne** `group.` — `"admin"` prüft `group.admin`. |
| **`permissionAces`** | Principals mit **`command allow`** (z. B. `"command"`) — OR zu `groups`. Wichtig für **txadmin**-Gruppen in `server.cfg`. |
| **`trustEsxGroup`** | `true`: ESX `xPlayer.getGroup()` gegen `groups` (z. B. txAdmin `setgroup … admin`). |
| **`trustTxAdmin`** | `true`: txAdmin-Panel-Admin nach `txAdmin:events:adminAuth`. |
| **`aceAllow`** | Zusätzliche Principals **vollständig** (OR), z. B. `"qbcore.admin"`. |
| **`color`** | `{ R, G, B }` (0–255) oder `{}` für Standard-Rotton — NUI: Klasse **`chat-line--staff`**. |

**Sichtbarkeit:** Nur berechtigte Clients empfangen Staff-Nachrichten (**live**, **HUD-Puffer**, **Historie-Popup**). Ohne Recht: weder Empfang noch Puffer; Server kann **`[Staff-Chat]`**-Hinweis senden. Abgelehnte Versuche können trotzdem in **`chat_history`** landen (Abschnitt 8).

#### Berechtigungswege (Übersicht)

| Weg | Prüfung in ec_chat |
| --- | --- |
| `server.cfg`: `add_ace group.txadmin command allow` | `permissionAces` + `groups` (z. B. `"txadmin"`) |
| ESX `/setgroup` / txAdmin-Konsole `setgroup` | `trustEsxGroup` + `groups` |
| txAdmin F4-Panel (eingeloggt) | `trustTxAdmin` |
| Nur `IsPlayerAceAllowed(..., "group.admin")` als Mitgliedschaft | **unzuverlässig** — kein Gruppenmitgliedschafts-Check |

#### Beispiel: ein Alias `mod`

```lua
Config.StaffChat = {
  enabled = true,
  command = { "mod" },
  groups = { "moderator", "admin" },
  permissionAces = { "command" },
  color = {},
}
```

### `Config.CheckGroup` (Diagnose `/checkgroup`)

| Feld | Bedeutung |
| --- | --- |
| **`enabled`** | `false` = Befehl in Chat, F8 und Server **aus**; kurzer Hinweis (sofern `notify` nicht `false`). |
| **`notify`** | Ergebnis: ox_lib / QBCore / ESX / GTA-Feed. |
| **`alsoChat`** | Zusätzlich eine Zeile in der EC-Chat-Liste. |
| **`showLicenseHint`** | Bei fehlender Gruppe: `license:` + Beispiel-`server.cfg`. |
| **`probeAce`** | Weitere ACE-Strings in der Prüfung. |
| **`serverLog`** | `true` / `false` / **`nil`** (= nur bei **`Config.Debug`**) → Report `[ec_chat_theme][checkgroup]` in der **Server-Konsole**. |

---

## 6 · SQL: Inventar-Modell · `Config.SQL`

**Ein** Schalter **`Config.SQL`** — das Inventar-Modell kommt aus **`Config.Inventory`** (Abschnitt 1).

### Voraussetzungen für Autocomplete

1. **`Config.SQL.enabled = true`**
2. **`Config.MySQL`** lauffähig
3. **`Config.Inventory`** passend zum Framework
4. Tabellen/Spalten in der DB vorhanden

### Obere Parameter (`Config.SQL`)

| Feld | Bedeutung |
| --- | --- |
| **`enabled`** | Master-Schalter serverseitiger Kataloge. |
| **`minSuggestionChars`** | Mindestlänge Suchstring vor Serverfilter. |
| **`maxSuggestionResults`** | Max. Treffer pro Antwort. |
| **`itemSuggestDebounceMs`** | NUI-Debouncing (ms). |
| **`itemSuggestAceGroups`** | Gruppen **ohne** `group.` — Fallback wenn kein `command.<alias>` gesetzt ist. |

### `tables.items`

| Feld | Bedeutung |
| --- | --- |
| **`table`**, **`name`**, **`label`** | Spalten der Item-Tabelle. |
| **`weaponNameMerge`** | **Ox:** zweite Tabelle in denselben Pool (Dedupe). Tabelle `{ table, name, label }`, **`false`**, **`nil`** = kein Merge. |
| **`autocomplete`** | `enabled`, `commands[]` mit `aliases` und `completeParamIndex`. |

### `completeParamIndex`

Argumente nach dem Befehl sind **1-basiert**. Beispiel `/giveitem 12 bread 3` → Index **2** = `bread`.

```lua
commands = {
  { aliases = { "giveitem", "give_item" }, completeParamIndex = 2 },
}
```

### `tables.weapons` (nur Standard/ESX, optional)

Wird geladen, wenn **nicht** Ox **und** mindestens eines zutrifft:

1. **`giveweapon`**-Autocomplete aktiv, **oder**
2. **`giveitemSuggestPrefix`** gesetzt (Brücke für `/giveitem`), **oder**
3. (Alt) **`giveitemSuggestWeaponsPrefix`** unter `items.autocomplete`.

| Feld | Bedeutung |
| --- | --- |
| **`table`**, **`name`**, **`label`** | Waffen-Tabelle in MySQL. |
| **`giveitemSuggestPrefix`** | `nil` = nur items; `true` = `"weapon_"`; String = eigenes Präfix; `false` = Brücke aus. |
| **`autocomplete`** | Slash **`giveweapon`**. |

**Ox:** `tables.weapons` wird **ignoriert**.

---

## 7 · UI (`Config.Ui`)

### `Config.Ui.brand` (Kopfzeile)

| Feld | Bedeutung |
| --- | --- |
| **`title`** | Text am Drag-Handle; `""` = ausblenden. |
| **`badge`** | Label (z. B. `LIVE`, `RP`); `false` / `""` = aus; `nil` = Standard **`LIVE`**. |

Wirksam nach Resource-**`restart`** bzw. neuem `chatLoaded`-Payload.

### `Config.Ui.history` (lokaler HUD-Verlauf)

Betrifft **nur** die **lokale Bildschirm-Anzeige** — **nicht** MySQL (Abschnitt 8).

| Feld | Bedeutung |
| --- | --- |
| **`enabled`** | HUD-Liste und Scroll-Verhalten (`true` Standard). |
| **`maxHistoryMessages`** | Max. Nachrichten im lokalen Puffer. |
| **`visibleHistoryLines`** | Sichtbare Zeilen ohne Scrollen. |
| **`autoHideHistoryMs`** | ESX-ähnlich: nach neuer Zeile einblenden, nach ms ausfaden; **`0`** = nie ausblenden. |
| **`toggleCommand`** | ohne `/`, z. B. `"chat"` → nur **`/chat on`** (Standard + Fade) und **`/chat off`** (Streamer, HUD aus). |
| **`toggleKey`** | Optional in `config.lua` auskommentiert — zusätzlicher Keymapping-Name. |
| **`persistStreamerPrivacyInKvp`** | `true`: Zustand „Historie aus“ in KVP **`ec_chat_theme_history_hidden`** zwischen Sessions. |

**Zusatz in der NUI** (kein `config.lua`-Feld): **Historie-Popup** (Uhr-Icon) mit Protokollzeilen `[DD.MM.YYYY HH:mm] - [Kanal] USER: Text` — siehe [Anhang A](#anhang-a--ui-einstellungen-nicht-in-configlua).

---

## 8 · Persistente Historie (`Config.ChatHistoryDatabase`)

| Feld | Bedeutung |
| --- | --- |
| **`enabled`** | `false` = keine INSERTs (Not-Aus / fehlende Migration). |
| **`table`** | Zieltabelle (Standard: `chat_history`, DDL: **`sql/chat_history.sql`**). |

| Spalte | Inhalt |
| --- | --- |
| `playername` | FiveM `GetPlayerName` (nicht IC-Name) |
| `playerid` | Server-**source** zum Zeitpunkt |
| `identifier` | bevorzugt **`license:`** |
| `message` | Volltext |
| `created_at` | Zeitstempel |

Läuft **unabhängig** vom lokalen HUD-Ausblenden (`/chat off`), sofern nicht per Config deaktiviert.

**Hinweis:** Kein vollständiges Datenschutz-Compliance-Werkzeug — rechtliche/serverinterne Regeln zusätzlich beachten.

---

## Kurz-Checkliste nach Änderungen

1. **`Config.MySQL`** ↔ **`server.cfg`** (oxmysql vs. mysql-async).
2. Bei **mysql-async**: **`fxmanifest.lua`** mit `MySQL.lua`-Include?
3. Migration **`chat_history`**, wenn **`ChatHistoryDatabase.enabled`**?
4. **`Config.Inventory`** und Tabellen **`items`** / optional **`weapons`**?
5. **`weaponNameMerge`** (Ox) oder **`giveitemSuggestPrefix`** / **`giveweapon`** (Standard)?
6. Vorschläge fehlen? → **`itemSuggestAceGroups`** und/oder **`command.<alias>`**?
7. **`Config.StaffChat`**: `groups`, `permissionAces`, ggf. `trustEsxGroup` / `trustTxAdmin`?
8. Live: **`Config.Debug`** und **`CheckGroup.enabled`** wie gewünscht?
9. NUI nach Config-Änderung: Resource-**restart**; nach Code-Änderung: **`npm run build`**.

---

## Anhang A · UI-Einstellungen (nicht in `config.lua`)

Diese Werte werden **pro Spieler** in der Resource-KVP **`ec_chat_theme_settings`** gespeichert (`client/settings.lua`, NUI-Callback **`saveSettings`**). Sie erscheinen **nicht** in `config.lua`, sind aber Teil des Gesamtprodukts.

| Feld (JSON) | Bedeutung |
| --- | --- |
| **`showMeButton`** / **`showDoButton`** | Schnellbuttons in der Eingabezeile. |
| **`positionPreset`** | Chat-Konsole: Preset (`bottom-left`, …). |
| **`manualMoveEnabled`**, **`manualX`**, **`manualY`** | Konsole frei positionieren. |
| **`historyHudMoveEnabled`**, **`historyHudX`**, **`historyHudY`** | HUD-Nachrichtenliste (`#messages-wrap`) verschieben. |
| **`historyPopupMoveEnabled`**, **`historyPopupX`**, **`historyPopupY`** | Historie-**Popup** (Protokoll) verschieben. |

**Historie-Popup:** Uhr-Icon → scrollbares Protokoll aller empfangenen Zeilen (Kanäle: **StaffChat**, **Me**, **Do**, **Chat**); Leeren-Button; Tooltips auf Icon-Buttons; Reset für HUD-/Popup-Position.

**Streamer-Modus:** `/chat off` setzt zusätzlich **`historyPrivacyHidden`** (optional persistent über **`persistStreamerPrivacyInKvp`**).

---

*Konfigurationsdokumentation · ec_chat_theme · Version siehe `fxmanifest.lua` / `README.md`.*
