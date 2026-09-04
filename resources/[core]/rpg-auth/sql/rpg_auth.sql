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
    `staff`      VARCHAR(25)     NOT NULL DEFAULT '',    -- slug grad staff (vezi shared/staff.lua); '' = civil

    -- progresie & economie (rpg-level). Default-urile = valorile de start la CREAREA caracterului.
    `level`         INT             NOT NULL DEFAULT 1,
    `respectpoints` INT             NOT NULL DEFAULT 0,
    `money`         BIGINT          NOT NULL DEFAULT 500,   -- cash
    `bank`          BIGINT          NOT NULL DEFAULT 1000,
    `playtime`         BIGINT UNSIGNED NOT NULL DEFAULT 0,     -- TOTAL secunde de joc ACTIV (nu float; UI-ul face HH.MM)
    `payday`           INT UNSIGNED    NOT NULL DEFAULT 3600,  -- secunde ramase pana la urmatorul payday (0..3600)
    `payday_playtime`  INT UNSIGNED    NOT NULL DEFAULT 0,     -- secunde ACTIVE acumulate in ciclul de payday CURENT (se reseteaza la fiecare payday)

    `last_login` TIMESTAMP       NULL DEFAULT NULL,
    `last_ip`    VARCHAR(45)     DEFAULT NULL,
    `created_at` TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_username` (`username`),
    UNIQUE KEY `uniq_email` (`email`),
    KEY `idx_identifier` (`identifier`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- coduri beta folosite (fiecare cod o singura data)
CREATE TABLE IF NOT EXISTS `beta_redemptions` (
    `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code`        VARCHAR(48)  NOT NULL,
    `account_id`  INT UNSIGNED NOT NULL,
    `reward`      VARCHAR(48)  NOT NULL,
    `redeemed_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_code` (`code`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
