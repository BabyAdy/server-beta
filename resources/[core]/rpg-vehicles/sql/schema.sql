-- ---------------------------------------------------------------------------
--  rpg-vehicles — schema
--  Se creeaza AUTOMAT la pornirea resursei (server/main.lua -> ensureSchema).
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `personal_vehicles` (
    `id`         INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    `owner`      INT UNSIGNED    NOT NULL,               -- users.id al proprietarului
    `model`      VARCHAR(64)     NOT NULL,               -- numele de model folosit la spawn
    `plate`      VARCHAR(12)     NOT NULL,
    `park_x`     FLOAT           DEFAULT NULL,           -- ultima locatie /park (unde spawneaza [Spawn])
    `park_y`     FLOAT           DEFAULT NULL,
    `park_z`     FLOAT           DEFAULT NULL,
    `park_h`     FLOAT           DEFAULT NULL,
    `mods`       LONGTEXT        DEFAULT NULL,           -- JSON: tuning-ul salvat la fiecare despawn
    `odometer`   FLOAT           NOT NULL DEFAULT 0,     -- kilometri parcursi (cumulat)
    `locked`     TINYINT(1)      NOT NULL DEFAULT 1,     -- 1 = incuiat
    `created_by` INT UNSIGNED    DEFAULT NULL,           -- users.id al staff-ului care a creat vehiculul
    `created_at` TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_plate` (`plate`),
    KEY `idx_owner` (`owner`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
