-- rpg-doors — usi cu incuietoare (server-authoritative)
CREATE TABLE IF NOT EXISTS `doors` (
  `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `label`      VARCHAR(64)  NOT NULL DEFAULT 'Usa',
  `model`      BIGINT       NOT NULL,
  `x`          DOUBLE       NOT NULL,
  `y`          DOUBLE       NOT NULL,
  `z`          DOUBLE       NOT NULL,
  `heading`    DOUBLE       NOT NULL DEFAULT 0,
  `locked`     TINYINT      NOT NULL DEFAULT 1,
  `created_by` INT UNSIGNED NULL,
  `created_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
