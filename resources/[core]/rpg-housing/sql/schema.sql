-- ---------------------------------------------------------------------------
--  rpg-housing — schema
--  Se creeaza AUTOMAT la pornirea resursei (server/main.lua -> ensureSchema).
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `houses` (
    `id`            INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    `owner`         INT UNSIGNED    NOT NULL DEFAULT 0,     -- users.id ; 0 = fara proprietar -> afisat "ADMBOT"
    `price`         BIGINT          NOT NULL DEFAULT 0,
    `interior_type` VARCHAR(48)     NOT NULL,               -- cheie in Config.InteriorTypes (rpg-housing/shared/config.lua)
    `x`             FLOAT           NOT NULL,
    `y`             FLOAT           NOT NULL,
    `z`             FLOAT           NOT NULL,
    `heading`       FLOAT           NOT NULL DEFAULT 0,
    `created_by`    INT UNSIGNED    DEFAULT NULL,           -- users.id al staff-ului care a creat casa
    `created_at`    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_owner` (`owner`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
