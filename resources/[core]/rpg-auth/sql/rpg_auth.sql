-- ---------------------------------------------------------------------------
--  rpg-auth — schema conturi
--  Importă în baza de date configurată în server.cfg (ex. rpg_dev).
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `users` (
    `id`         INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    `username`   VARCHAR(20)     NOT NULL,
    `email`      VARCHAR(190)    NOT NULL,
    `password`   CHAR(64)        NOT NULL,               -- SHA-256 hex (dev). Vezi nota din server/main.lua
    `salt`       CHAR(32)        NOT NULL,
    `identifier` VARCHAR(60)     DEFAULT NULL,           -- license: al contului Cfx
    `banned`     TINYINT(1)      NOT NULL DEFAULT 0,
    `ban_reason` VARCHAR(255)    DEFAULT NULL,
    `last_login` TIMESTAMP       NULL DEFAULT NULL,
    `last_ip`    VARCHAR(45)     DEFAULT NULL,
    `created_at` TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_username` (`username`),
    UNIQUE KEY `uniq_email` (`email`),
    KEY `idx_identifier` (`identifier`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
