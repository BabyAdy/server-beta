-- ===========================================================================
--  rpg-jobs — schema
--  Rulat AUTOMAT la pornire (server/database.lua -> ensureSchema), sau importa
--  manual acest fisier. Toate statement-urile sunt idempotente.
--
--  Relatii:
--     users.id  ->  player_job_data.user_id
--     jobs.id   ->  player_job_data.job_id
--     users.job ->  jobs.id  (0 = unemployed; scalar, jobul ACTIV al playerului)
-- ===========================================================================

-- ---- users.job : coloana adaugata pe tabela existenta -------------------
--  (database.lua o adauga si prin ALTER conditionat daca ruleaza pe un DB vechi)
-- ALTER TABLE `users` ADD COLUMN `job` INT UNSIGNED NOT NULL DEFAULT 0;

-- ---- JOBURI (oglinda persistenta a Config.Jobs; seeded la boot) ---------
CREATE TABLE IF NOT EXISTS `jobs` (
    `id`            INT UNSIGNED    NOT NULL,               -- ID FIX (din config), NU auto-increment
    `name`          VARCHAR(48)     NOT NULL,
    `label`         VARCHAR(64)     NOT NULL,
    `min_level`     INT UNSIGNED    NOT NULL DEFAULT 1,
    `base_pay_min`  INT UNSIGNED    NOT NULL DEFAULT 0,
    `base_pay_max`  INT UNSIGNED    NOT NULL DEFAULT 0,
    `required_tasks` INT UNSIGNED   NOT NULL DEFAULT 5,     -- panouri / tura
    `max_skill`     INT UNSIGNED    NOT NULL DEFAULT 5,
    `skill_shifts`  VARCHAR(255)    NOT NULL DEFAULT '0,15,30,45,60',  -- CSV: ture cumulate / skill
    `created_at`    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_name` (`name`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ---- PROGRES PLAYER PER JOB (persistent) -------------------------------
CREATE TABLE IF NOT EXISTS `player_job_data` (
    `id`               INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `user_id`          INT UNSIGNED  NOT NULL,              -- users.id
    `job_id`           INT UNSIGNED  NOT NULL,              -- jobs.id
    `skill`            INT UNSIGNED  NOT NULL DEFAULT 1,
    `completed_shifts` INT UNSIGNED  NOT NULL DEFAULT 0,    -- ture reusite (folosit la avansarea skill-ului)
    `total_shifts`     INT UNSIGNED  NOT NULL DEFAULT 0,    -- ture pornite (audit)
    `total_earnings`   BIGINT UNSIGNED NOT NULL DEFAULT 0,  -- $ castigati cumulat din job
    `last_shift_at`    TIMESTAMP     NULL DEFAULT NULL,
    `created_at`       TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`       TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_user_job` (`user_id`, `job_id`),
    KEY `idx_user` (`user_id`),
    KEY `idx_job`  (`job_id`),
    CONSTRAINT `fk_pjd_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_pjd_job`  FOREIGN KEY (`job_id`)  REFERENCES `jobs`  (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
