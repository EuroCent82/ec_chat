fx_version 'cerulean'
game 'gta5'

author 'EuroCent'
name 'ec_chat'
description 'Custom FiveM Chat, UI with autocomplete and quick actions'
version '1.2.29'

shared_scripts {
    'config.lua',
    'shared/sql_inventory.lua',
    'shared/staff_chat.lua',
    'shared/slash_debug.lua',
    'shared/rp_slash_boundary.lua',
    'shared/rp_command_config.lua',
    'shared/config_access.lua'
}

-- NUI: zuerst `cd ui` → `npm run build` (Ausgabe unter html/)
ui_page 'html/index.html'

files {
    'html/**',
    'sql/*.sql',
}

-- Kein Pflicht-'dependency oxmysql'; Standard in config.lua: Config.MySQL = "oxmysql" ("" ebenfalls möglich; Alternativlage: "mysql-async").
-- Bei **Config.MySQL = "mysql-async"**: vor anderen server_scripts einbinden, z. B.:
--   server_scripts { '@mysql-async/lib/MySQL.lua', ... }

client_scripts {
    'client/state.lua',
    'client/nui.lua',
    'client/item_autocomplete.lua',
    'client/suggestions.lua',
    'client/rp_overhead.lua',
    'client/settings.lua',
    'client/notify.lua',
    'client/check_group.lua',
    'client/chat_history_ui.lua',
    'client/chat_suppress.lua',
    'client/chat_controls.lua',
    'client/proximity.lua',
    'client/main.lua',
}

server_scripts {
    'server/mysql_adapter.lua',
    'server/helpers.lua',
    'server/rp_rules.lua',
    'server/chat_history.lua',
    'server/staff_txadmin.lua',
    'server/staff_chat.lua',
    'server/check_group.lua',
    'server/chat_slash_relay.lua',
    'server/item_catalog.lua',
    'server/weapon_catalog.lua',
    'server/item_suggest.lua',
    'server/suggestions.lua',
    'server/main.lua',
    'server/version_check.lua',
    'server/exports.lua',
}

exports {
    'addMessage',
    'addSuggestion',
    'addSuggestions',
    'removeSuggestion',
    'clear'
}

server_exports {
    'addMessage',
    'addSuggestion',
    'addSuggestions',
    'removeSuggestion',
    'clear'
}
