-- ---------------------------------------------------------------------------
--  rpg-tickets — schema
--  Se creeaza AUTOMAT la pornirea resursei (server/main.lua -> ensureSchema).
--  Poti rula si manual acest fisier in baza de date configurata in server.cfg.
-- ---------------------------------------------------------------------------

-- ===== TICHETE ============================================================
CREATE TABLE IF NOT EXISTS `tickets` (
    `id`                INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    `player_identifier` VARCHAR(64)     NOT NULL,               -- license: al jucatorului (stabil intre sesiuni)
    `player_name`       VARCHAR(64)     NOT NULL,               -- users.username la momentul deschiderii
    `player_id`         INT             NOT NULL DEFAULT 0,     -- server id la momentul deschiderii (informativ)
    `category`          VARCHAR(64)     NOT NULL,
    `reason`            TEXT            NOT NULL,
    `status`            ENUM('active','claimed','closed') NOT NULL DEFAULT 'active',
    `claimed_by`        VARCHAR(64)     DEFAULT NULL,           -- license: staff-ului care a preluat (NULL = neatribuit)
    `staff_name`        VARCHAR(64)     DEFAULT NULL,           -- users.username al staff-ului
    `rating`            TINYINT         DEFAULT NULL,           -- 1..5 lasat de jucator la inchidere
    `created_at`        TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `claimed_at`        TIMESTAMP       NULL DEFAULT NULL,      -- pt. "timp mediu de preluare"
    `closed_at`         TIMESTAMP       NULL DEFAULT NULL,      -- pt. "timp mediu de rezolvare"
    PRIMARY KEY (`id`),
    KEY `idx_status`     (`status`),
    KEY `idx_player`     (`player_identifier`),
    KEY `idx_claimed_by` (`claimed_by`),
    KEY `idx_created`    (`created_at`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ===== MESAJE DIN TICHETE =================================================
CREATE TABLE IF NOT EXISTS `ticket_messages` (
    `id`                INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    `ticket_id`         INT UNSIGNED    NOT NULL,
    `sender_name`       VARCHAR(64)     NOT NULL,
    `sender_identifier` VARCHAR(64)     NOT NULL,
    `message`           TEXT            NOT NULL,
    `is_staff`          TINYINT(1)      NOT NULL DEFAULT 0,
    `created_at`        TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_ticket` (`ticket_id`),
    CONSTRAINT `fk_msg_ticket` FOREIGN KEY (`ticket_id`) REFERENCES `tickets` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ===== STATISTICI + REWARDS STAFF ========================================
CREATE TABLE IF NOT EXISTS `staff_stats` (
    `identifier`             VARCHAR(64) NOT NULL,              -- license: staff-ului
    `staff_name`             VARCHAR(64) NOT NULL,
    `tickets_closed_total`   INT         NOT NULL DEFAULT 0,
    `tickets_closed_monthly` INT         NOT NULL DEFAULT 0,
    `rating`                 FLOAT       NOT NULL DEFAULT 5.0,  -- media rating-urilor primite
    `rating_count`           INT         NOT NULL DEFAULT 0,    -- cate rating-uri au intrat in medie
    `avg_response_seconds`   INT         NOT NULL DEFAULT 0,    -- media (create_at -> claimed) rulanta
    `money_accrued`          BIGINT      NOT NULL DEFAULT 0,    -- bani stransi luna curenta (din payout per ticket)
    `money_claimed`          BIGINT      NOT NULL DEFAULT 0,    -- din money_accrued, cat a virat deja in banca
    `fpt`                    INT         NOT NULL DEFAULT 0,    -- FPLAYT points (moneda permanenta)
    `monthly_reset_at`       DATE        NOT NULL DEFAULT '1970-01-01', -- data la care se face urmatorul reset lunar
    `updated_at`             TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`identifier`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
