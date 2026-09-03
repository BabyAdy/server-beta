-- ---------------------------------------------------------------------------
--  rpg-inventory — persistenta
--
--  characters ──1:1──> inventories ──1:N──> inventory_items
--
--  `inventories` e generic: owner_type poate fi 'character', 'ground', 'stash',
--  'trunk', 'glovebox', 'business', 'faction' ... (doar 'character' e folosit
--  activ acum; restul sunt pregatite in schema pentru extindere).
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `inventories` (
    `id`         VARCHAR(64)  NOT NULL,               -- ex: 'char:12', 'stash:police1'
    `owner_type` VARCHAR(24)  NOT NULL,
    `owner_id`   VARCHAR(64)  NOT NULL,
    `max_weight` DECIMAL(8,2) NOT NULL DEFAULT 0.00,  -- rezervat (capacitatea e pe sloturi)
    `slots`      INT UNSIGNED NOT NULL DEFAULT 100,   -- capacitatea containerului (sloturi)
    `pos_x`      FLOAT        DEFAULT NULL,
    `pos_y`      FLOAT        DEFAULT NULL,
    `pos_z`      FLOAT        DEFAULT NULL,
    `fast_slots` JSON         DEFAULT NULL,            -- { "1": 7, "2": null, ... } (map index->grid slot)
    `created_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_owner` (`owner_type`, `owner_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `inventory_items` (
    `id`           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `inventory_id` VARCHAR(64)     NOT NULL,
    `item_id`      VARCHAR(48)     NOT NULL,           -- FK logic catre item definitions (in cod)
    `slot`         VARCHAR(16)     NOT NULL,           -- '1'..'25' (grid) sau 'shirt','armor',... (echipament)
    `quantity`     INT UNSIGNED    NOT NULL DEFAULT 1,
    `metadata`     JSON            DEFAULT NULL,       -- { durability, ammo, phoneNumber, component/drawable/texture, ... }
    `created_at`   TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`   TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_inv` (`inventory_id`),
    CONSTRAINT `fk_invitems_inv` FOREIGN KEY (`inventory_id`)
        REFERENCES `inventories` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
