-- ===========================================================================
--  rpg-garages — schema
--  Rulat AUTOMAT la pornirea resursei (server/main.lua -> ensureSchema),
--  sau manual: importa acest fisier in baza de date din server.cfg.
--
--  Relatii:
--     users.id  ->  personal_vehicle.owner_id  ->  vehicle_tunning.vehicle_id
-- ===========================================================================

-- ---- GARAGE-uri (locatii pe harta) ---------------------------------------
CREATE TABLE IF NOT EXISTS `rpg_garages` (
    `id`         INT UNSIGNED                     NOT NULL AUTO_INCREMENT,
    `type`       ENUM('Vehicle','Heli','Boat')    NOT NULL DEFAULT 'Vehicle',
    `x`          DOUBLE                           NOT NULL,
    `y`          DOUBLE                           NOT NULL,
    `z`          DOUBLE                           NOT NULL,
    `h`          FLOAT                            NOT NULL DEFAULT 0,
    `created_by` INT UNSIGNED                     DEFAULT NULL,   -- users.id al staff-ului
    `created_at` TIMESTAMP                        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ---- VEHICULE PERSONALE (masini + moto + heli + avioane + barci) ---------
CREATE TABLE IF NOT EXISTS `personal_vehicle` (
    `id`           INT UNSIGNED                  NOT NULL AUTO_INCREMENT,
    `model_name`   VARCHAR(64)                   NOT NULL,             -- cod de spawn (ex. 'sultan')
    `display_name` VARCHAR(96)                   NOT NULL,             -- nume afisat (ex. 'Karin Sultan')
    `vehicle_type` ENUM('Vehicle','Heli','Boat') NOT NULL DEFAULT 'Vehicle',
    `owner_id`     INT UNSIGNED                  NOT NULL,             -- users.id
    `owner_name`   VARCHAR(32)                   NOT NULL,             -- users.username
    `faction`      VARCHAR(40)                   NOT NULL DEFAULT '',  -- '' = vehicul personal; altfel slug facțiune
    `garage_id`    INT UNSIGNED                  DEFAULT NULL,         -- ultimul garage in care a fost parcat
    `odometer`     DOUBLE                        NOT NULL DEFAULT 0,   -- kilometri cumulati
    `fuel`         FLOAT                         NOT NULL DEFAULT 100, -- 0..100
    -- TINYINT (NU TINYINT(1)): oxmysql converteste TINYINT(1) in boolean.
    `status`       TINYINT                       NOT NULL DEFAULT 0,   -- 0 = locked, 1 = unlocked
    `stored`       TINYINT                       NOT NULL DEFAULT 1,   -- 1 = in garage, 0 = scos/spawnat
    `plate`        VARCHAR(12)                   NOT NULL,
    `created_at`   TIMESTAMP                     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_plate` (`plate`),
    KEY `idx_owner`   (`owner_id`),
    KEY `idx_faction` (`faction`),
    KEY `idx_garage`  (`garage_id`),
    KEY `idx_type`    (`vehicle_type`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ---- TUNING (o linie per vehicul, config in JSON validat server-side) ----
CREATE TABLE IF NOT EXISTS `vehicle_tunning` (
    `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `vehicle_id` INT UNSIGNED NOT NULL,               -- personal_vehicle.id
    `owner_id`   INT UNSIGNED NOT NULL,               -- personal_vehicle.owner_id (redundant, pt. index/audit)
    `data`       LONGTEXT     DEFAULT NULL,           -- JSON: culori/mods/neon/xenon/wheels/livery/plate/...
    `updated_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_vehicle` (`vehicle_id`),
    KEY `idx_owner` (`owner_id`),
    CONSTRAINT `fk_tunning_vehicle`
        FOREIGN KEY (`vehicle_id`) REFERENCES `personal_vehicle` (`id`)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
