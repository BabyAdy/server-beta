-- ---------------------------------------------------------------------------
--  rpg-characters — un singur personaj per cont, fara identity.
--  Importa dupa rpg-auth (are FK catre `users`).
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `characters` (
    `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `account_id` INT UNSIGNED NOT NULL,
    `username`   VARCHAR(20)  NOT NULL,              -- copiat din cont (numele ales la register)
    `appearance` LONGTEXT     NOT NULL,              -- JSON (structura din shared/appearance.lua)
    `position`   VARCHAR(160) DEFAULT NULL,          -- JSON {x,y,z,h}
    `created_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_account` (`account_id`),
    CONSTRAINT `fk_char_account` FOREIGN KEY (`account_id`)
        REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
