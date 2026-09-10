-- rpg-duty — outfit-ul de factiune salvat, per personaj + factiune
CREATE TABLE IF NOT EXISTS `faction_outfits` (
  `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `char_id`    INT UNSIGNED NOT NULL,
  `faction_id` INT UNSIGNED NOT NULL,
  `outfit`     LONGTEXT     NOT NULL,   -- JSON: { comp = { ["11"]={d,t}, ... }, prop = { ["0"]={d,t}, ... } }
  `updated_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_char_faction` (`char_id`, `faction_id`),
  KEY `idx_faction` (`faction_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
