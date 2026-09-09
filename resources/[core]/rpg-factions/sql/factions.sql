-- ===========================================================================
--  rpg-factions — schema
--  Import manual SAU automat la boot (server/database.lua -> ensureSchema).
--  Toate statement-urile sunt idempotente.
--
--  Compat: MySQL 5.7+ / MariaDB 10.2+.
--  `group` e cuvant rezervat MySQL -> se scrie MEREU cu backticks: `group`.
--  Coloanele JSON sunt LONGTEXT (parsate in Lua) pentru compat maxima intre
--  MySQL (JSON nativ) si MariaDB (JSON = alias LONGTEXT). NU se interogheaza
--  in interiorul JSON-ului -> LONGTEXT e suficient si portabil.
-- ===========================================================================

-- ---- users : coloane pentru factions (adaugate conditionat de database.lua
--      daca ruleaza pe un DB deja existent) ---------------------------------
-- ALTER TABLE `users`
--   ADD COLUMN `group`             INT UNSIGNED     NOT NULL DEFAULT 0,
--   ADD COLUMN `group_rank`        INT UNSIGNED     NOT NULL DEFAULT 0,
--   ADD COLUMN `group_join`        DATETIME         NULL DEFAULT NULL,
--   ADD COLUMN `group_warning`     TINYINT UNSIGNED NOT NULL DEFAULT 0,
--   ADD COLUMN `group_supervisor`  TINYINT(1)       NOT NULL DEFAULT 0,
--   ADD COLUMN `group_tester`      TINYINT(1)       NOT NULL DEFAULT 0,
--   ADD COLUMN `group_permissions` LONGTEXT         NULL;
-- ALTER TABLE `users` ADD INDEX `idx_users_group` (`group`);
-- ALTER TABLE `users` ADD INDEX `idx_users_group_rank` (`group`, `group_rank`);

-- ---- FACTIONS -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS `factions` (
    `id`            INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    `g_name`        VARCHAR(64)     NOT NULL,
    `g_color`       VARCHAR(9)      NOT NULL DEFAULT '#3498db',   -- #RRGGBB / #RRGGBBAA
    `g_type`        VARCHAR(32)     NOT NULL DEFAULT 'other',     -- police/ems/government/mechanic/gang/mafia/other/... (extensibil)
    `g_minlevel`    INT UNSIGNED    NOT NULL DEFAULT 0,
    `g_minhours`    INT UNSIGNED    NOT NULL DEFAULT 0,           -- ORE (adapter-ul converteste users.playtime -> ore)
    `g_application` TINYINT(1)      NOT NULL DEFAULT 0,           -- 0 = closed, 1 = open
    `g_maxmembers`  INT UNSIGNED    NOT NULL DEFAULT 0,           -- 0 = nelimitat
    `leader`        INT UNSIGNED    NOT NULL DEFAULT 0,           -- users.id (0 = none)
    `manager`       INT UNSIGNED    NOT NULL DEFAULT 0,           -- users.id (0 = none)
    `initial_rank`  INT UNSIGNED    NOT NULL DEFAULT 1,           -- rank_order acordat la join
    `hq_enter_x`    DOUBLE          NULL, `hq_enter_y` DOUBLE NULL, `hq_enter_z` DOUBLE NULL, `hq_enter_h` FLOAT NULL,
    `hq_leave_x`    DOUBLE          NULL, `hq_leave_y` DOUBLE NULL, `hq_leave_z` DOUBLE NULL, `hq_leave_h` FLOAT NULL,
    `hq_vw`         INT UNSIGNED    NOT NULL DEFAULT 0,           -- routing bucket (0 = fara HQ configurat)
    `created_at`    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_name` (`g_name`),
    KEY `idx_type` (`g_type`),
    KEY `idx_leader` (`leader`),
    KEY `idx_manager` (`manager`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ---- FACTION RANKS (o linie per rank; ierarhie prin rank_order) ---------
CREATE TABLE IF NOT EXISTS `faction_ranks` (
    `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `faction_id`  INT UNSIGNED NOT NULL,
    `rank_order`  INT UNSIGNED NOT NULL,           -- 1..N ; stocat in users.group_rank
    `name`        VARCHAR(48)  NOT NULL,           -- slug intern
    `label`       VARCHAR(48)  NOT NULL,           -- afisat
    `permissions` LONGTEXT     NULL,               -- JSON: { "invite": true, ..., "*": true }
    `salary`      INT UNSIGNED NOT NULL DEFAULT 0,
    `is_leader`   TINYINT(1)   NOT NULL DEFAULT 0,
    `is_coleader` TINYINT(1)   NOT NULL DEFAULT 0,
    `created_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_faction_order` (`faction_id`, `rank_order`),
    KEY `idx_faction` (`faction_id`),
    CONSTRAINT `fk_ranks_faction` FOREIGN KEY (`faction_id`)
        REFERENCES `factions` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ---- FACTION APPLICATIONS --------------------------------------------
CREATE TABLE IF NOT EXISTS `faction_applications` (
    `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `faction_id`  INT UNSIGNED NOT NULL,
    `user_id`     INT UNSIGNED NOT NULL,
    `status`      ENUM('pending','accepted','rejected','cancelled') NOT NULL DEFAULT 'pending',
    `message`     VARCHAR(500) NOT NULL DEFAULT '',
    `snapshot`    LONGTEXT     NULL,               -- JSON: { level, hours } la momentul aplicarii
    `reviewed_by` INT UNSIGNED NULL,               -- users.id
    `reviewed_at` DATETIME     NULL,
    `created_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_faction_status` (`faction_id`, `status`),
    KEY `idx_user`           (`user_id`),
    KEY `idx_user_status`    (`user_id`, `status`),
    CONSTRAINT `fk_apps_faction` FOREIGN KEY (`faction_id`)
        REFERENCES `factions` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ---- FACTION LOGS (audit; FARA FK -> logurile supravietuiesc stergerii) ----
CREATE TABLE IF NOT EXISTS `faction_logs` (
    `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `faction_id` INT UNSIGNED    NOT NULL,
    `actor_id`   INT UNSIGNED    NOT NULL DEFAULT 0,   -- users.id (0 = system/console)
    `target_id`  INT UNSIGNED    NOT NULL DEFAULT 0,   -- users.id (0 = n/a)
    `action`     VARCHAR(48)     NOT NULL,
    `reason`     VARCHAR(255)    NOT NULL DEFAULT '',
    `old_data`   LONGTEXT        NULL,                 -- JSON
    `new_data`   LONGTEXT        NULL,                 -- JSON
    `created_at` TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_faction_time` (`faction_id`, `created_at`),
    KEY `idx_actor`  (`actor_id`),
    KEY `idx_target` (`target_id`),
    KEY `idx_action` (`action`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
