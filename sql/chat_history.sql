-- ec_chat_theme — `chat_history` (über **Config.MySQL**: oxmysql oder mysql-async).
-- Einmal ausführen: dieselbe Datenbank wie euer Server-Connector (oxmysql/mysql-async etc.). README: Abschnitt „Datenbank · chat_history“.
CREATE TABLE IF NOT EXISTS `chat_history` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `playername` VARCHAR(128) NOT NULL COMMENT 'FiveM GetPlayerName, nicht IC-Name',
  `playerid` INT NOT NULL COMMENT 'Server source zum Zeitpunkt',
  `identifier` VARCHAR(128) NOT NULL COMMENT 'Primär-ID (license:…)',
  `message` TEXT NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_identifier_created` (`identifier`, `created_at`),
  KEY `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
