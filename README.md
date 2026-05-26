<p align="center">
  <img src="docs/ec_chat_banner.png" alt="EC Chat — Custom FiveM Chat" width="100%" />
</p>

<p align="center">
  <img src="docs/ec_chat_logo.png" alt="EC Chat Logo" width="88" height="88" />
</p>

<h1 align="center">EC Chat</h1>

<p align="center">
  <strong>Professioneller FiveM-Chat</strong> mit Vue-3-NUI — RP-tauglich, staff-sicher, datenbankfähig.
</p>

<p align="center">
  <a href="https://github.com/EuroCent82/ec_chat/releases"><img src="https://img.shields.io/badge/Version-1.2.30-7cfc00?style=for-the-badge" alt="Version 1.2.30" /></a>
  <a href="https://github.com/EuroCent82/ec_chat/releases"><img src="https://img.shields.io/github/v/release/EuroCent82/ec_chat?style=for-the-badge&label=Release" alt="GitHub Release" /></a>
  <a href="./LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue?style=for-the-badge" alt="MIT License" /></a>
  <a href="https://github.com/EuroCent82/ec_chat"><img src="https://img.shields.io/badge/GitHub-EuroCent82%2Fec__chat-181717?style=for-the-badge&logo=github" alt="Repository" /></a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/FiveM-cerulean-111111?logo=fivem" alt="FiveM cerulean" />
  <img src="https://img.shields.io/badge/NUI-Vue%203-42b883?logo=vuedotjs&logoColor=white" alt="Vue 3" />
  <img src="https://img.shields.io/badge/MySQL-oxmysql%20%7C%20mysql--async-4479A1?logo=mysql&logoColor=white" alt="MySQL" />
  <a href="./readme_config.md"><img src="https://img.shields.io/badge/Doku-config.lua-DE-555" alt="Config-Doku DE" /></a>
</p>

<p align="center">
  Resource <code>ec_chat</code> · Autor <a href="https://github.com/EuroCent82">EuroCent82</a>
</p>

> **Entwickler?** Quellcode, Build und Release-Flow: [`README.dev.md`](./README.dev.md) · privates Dev-Repo [`ec_chat_dev`](https://github.com/EuroCent82/ec_chat_dev)

---

## Überblick

**EC Chat** ersetzt die sichtbare Chat-Oberfläche durch eine moderne **NUI** — ohne eure bestehenden Chat-Exports und **`chat:addSuggestion`**-Integrationen zu brechen.

| Bereich | Kurzbeschreibung |
| --- | --- |
| **Oberfläche** | Dark-Industrial-UI, Presets, freies Ziehen, KVP-Speicherung |
| **RP** | `/me` · `/do` mit Rechte-Config, 3D-Overhead, Schnellbuttons |
| **Staff** | Eigene Aliase, rot markiert, nur für Berechtigte sichtbar |
| **Historie** | HUD mit Auto-Fade, Protokoll-Popup mit Zeitstempel |
| **Datenbank** | Item-/Waffen-Autocomplete, optionales `chat_history`-Log |
| **Kompatibilität** | ESX · ox_inventory · klassische Chat-Exports |

<p align="center">
  <img src="docs/ec_chat_history_concept_mockup.png" alt="EC Chat — Historie-Konzept" width="720" />
</p>

---

## Installation

### Voraussetzungen

| Komponente | Hinweis |
| --- | --- |
| **FiveM-Server** | `fx_version` **cerulean** |
| **MySQL** | [oxmysql](https://github.com/overextended/oxmysql) (empfohlen) oder **mysql-async** — nur für DB-Features |
| **Abhängigkeiten** | Kein hartes `dependency`; ohne MySQL läuft der Chat, DB-Features entfallen |

### Variante A — Release-ZIP (empfohlen)

1. Neuestes Release laden: **[github.com/EuroCent82/ec_chat/releases](https://github.com/EuroCent82/ec_chat/releases)**
2. `ec_chat.zip` entpacken nach `resources/[scripts]/ec_chat/`
3. Optional: `sql/chat_history.sql` ausführen, wenn `Config.ChatHistoryDatabase.enabled = true`
4. `config.lua` anpassen — siehe [`readme_config.md`](./readme_config.md)
5. In **`server.cfg`**:

   ```cfg
   ensure oxmysql
   ensure ec_chat
   ```

### Variante B — Git Clone

```bash
cd resources/[scripts]
git clone https://github.com/EuroCent82/ec_chat.git
```

Danach wie oben: SQL (optional), `config.lua`, `ensure ec_chat`.

---

## Bedienung

| Aktion | Standard |
| --- | --- |
| Chat öffnen | **T** (`+openEcChat`, in den Spiel-Einstellungen änderbar) |
| Eingabe-Historie | **↑** / **↓** |
| Vorschlagsliste | **Strg** + **↑** / **↓** · **Tab** zum Durchschalten |
| HUD-Historie ein / aus | **`/chat on`** · **`/chat off`** (Streamer-Modus) |
| Protokoll-Fenster | **Uhr-Icon** in der Chat-Leiste |
| Staff-Chat | z. B. **`/a Nachricht`** (nur mit Berechtigung) |
| ACE-Diagnose | **`/checkgroup`** (wenn aktiviert) |

---

## Konfiguration

Alle Optionen in **`config.lua`** — vollständig dokumentiert auf Deutsch:

**→ [`readme_config.md`](./readme_config.md)**

| Block | Inhalt |
| --- | --- |
| `Debug`, `MySQL`, `Inventory` | Diagnose, DB-Treiber, ESX vs. ox_inventory |
| `Me`, `Do` | RP-Befehle, Länge, Overhead, Berechtigungen |
| `Chat`, `StaffChat` | Slash-Relay, Team-Chat, CheckGroup |
| `SQL` | Item-/Waffen-Autocomplete aus MySQL |
| `Ui` | Branding, HUD-Historie, Sounds, Fade |
| `ChatHistoryDatabase` | Persistentes Server-Protokoll |

UI-Einstellungen ohne `config.lua` (Position, Fenster): [Anhang A in readme_config.md](./readme_config.md#anhang-a--ui-einstellungen-nicht-in-configlua).

---

## Funktionen im Detail

<details>
<summary><strong>Chat & Eingabe</strong></summary>

- Autocomplete für `chat:addSuggestion` und interne Vorschläge
- Eingabe-Historie per **↑** / **↓** (lokal im NUI)
- Slash-Relay mit Verzögerung; Sonderweg **ox_doorlock**
- Exports: `addMessage`, `addSuggestion`, `addSuggestions`, `removeSuggestion`, `clear`

</details>

<details>
<summary><strong>RP & Staff</strong></summary>

- **`/me`** und **`/do`** — je Befehl konfigurierbar (Länge, 3D-Overhead, `permission`)
- Staff-Aliase (`/a`, `/t`, …) nur für berechtigte Spieler sichtbar
- Darstellung: **rot** im Chat und in der Historie

</details>

<details>
<summary><strong>Historie & Datenbank</strong></summary>

- HUD-Nachrichten mit ESX-ähnlichem Auto-Fade
- Protokoll-Popup: `[DD.MM.YYYY HH:mm] - [Kanal] USER: Nachricht`
- `chat_history`-Tabelle für Support und Auditing
- `giveitem` / `giveweapon`-Autocomplete aus MySQL

</details>

---

## Version & Updates

Beim Serverstart vergleicht EC Chat die lokale **`fxmanifest`-Version** mit dem neuesten **[GitHub-Release](https://github.com/EuroCent82/ec_chat/releases)** und gibt einen Hinweis in der Server-Konsole aus (`Config.VersionCheck`).

---

## Projektstruktur (Runtime)

```text
ec_chat/
├── client/           # NUI, Vorschläge, Overhead, Historie
├── server/           # RP, Staff, chat_history, Slash-Relay
├── shared/           # Gemeinsame Config-Helfer
├── html/             # Gebaute NUI (Vue 3)
├── sql/              # chat_history.sql
├── docs/             # Banner, Logo, Screenshots
├── config.lua
├── readme_config.md  # Config-Referenz (DE)
├── fxmanifest.lua
├── LICENSE
└── README.md
```

---

## Lizenz

Dieses Projekt steht unter der **[MIT License](./LICENSE)**.

Copyright © 2025 [EuroCent82](https://github.com/EuroCent82)

---

<p align="center">
  <img src="docs/ec_chat_logo.png" alt="" width="40" height="40" />
  <br />
  <strong>EC Chat</strong> · FiveM · Vue 3 · RP-ready
  <br />
  <a href="./readme_config.md">Konfiguration</a> ·
  <a href="https://github.com/EuroCent82/ec_chat/releases">Releases</a> ·
  <a href="./LICENSE">Lizenz</a>
</p>
