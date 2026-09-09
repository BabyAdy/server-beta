-- ===========================================================================
--  rpg-factions — DATABASE  (server)
--  Schema install/migratie + helperi DB de nivel jos + tranzactii + JSON.
--  Nu contine logica de business (aceea e in factions/members/applications).
-- ===========================================================================

DB = {}

local DBG = Config.Debug

-- ---- JSON safe --------------------------------------------------------
function DB.decode(s)
    if type(s) ~= 'string' or s == '' then return {} end
    local ok, v = pcall(json.decode, s)
    return (ok and type(v) == 'table') and v or {}
end
function DB.encode(t)
    return json.encode(type(t) == 'table' and t or {})
end

-- ---- SCHEMA --------------------------------------------------------
local USERS_COLS = {
    { 'group',             "INT UNSIGNED NOT NULL DEFAULT 0" },
    { 'group_rank',        "INT UNSIGNED NOT NULL DEFAULT 0" },
    { 'group_join',        "DATETIME NULL DEFAULT NULL" },
    { 'group_warning',     "TINYINT UNSIGNED NOT NULL DEFAULT 0" },
    { 'group_supervisor',  "TINYINT(1) NOT NULL DEFAULT 0" },
    { 'group_tester',      "TINYINT(1) NOT NULL DEFAULT 0" },
    { 'group_permissions', "LONGTEXT NULL" },
}

local function columnExists(table_, col)
    local n = MySQL.scalar.await([[
        SELECT COUNT(*) FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?
    ]], { table_, col })
    return (tonumber(n) or 0) > 0
end
local function indexExists(table_, idx)
    local n = MySQL.scalar.await([[
        SELECT COUNT(*) FROM information_schema.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND INDEX_NAME = ?
    ]], { table_, idx })
    return (tonumber(n) or 0) > 0
end

function DB.ensureSchema()
    local sql = LoadResourceFile(GetCurrentResourceName(), 'sql/factions.sql')
    if sql then
        for stmt in (sql .. '\n'):gmatch('(.-);%s*\n') do
            local s = stmt:gsub('%-%-[^\n]*', ''):gsub('^%s+', ''):gsub('%s+$', '')
            if s ~= '' then MySQL.query.await(s) end
        end
    end

    -- users.* — adaugate conditionat (`group` = cuvant rezervat -> backticks)
    for _, c in ipairs(USERS_COLS) do
        if not columnExists('users', c[1]) then
            MySQL.query.await(('ALTER TABLE `users` ADD COLUMN `%s` %s'):format(c[1], c[2]))
            print(('[rpg-factions] users.%s adaugata.'):format(c[1]))
        end
    end
    if not indexExists('users', 'idx_users_group') then
        MySQL.query.await('ALTER TABLE `users` ADD INDEX `idx_users_group` (`group`)')
    end
    if not indexExists('users', 'idx_users_group_rank') then
        MySQL.query.await('ALTER TABLE `users` ADD INDEX `idx_users_group_rank` (`group`, `group_rank`)')
    end

    if DBG then print('[rpg-factions] schema OK') end
end

-- ---- tranzactie atomica (oxmysql). queries = { { sql, params }, ... } ---
--  Returneaza true daca TOATE au reusit, altfel false (rollback automat).
function DB.transaction(queries)
    local ok, res = pcall(function() return MySQL.transaction.await(queries) end)
    return ok and res ~= false
end

-- ---- helperi de citire ----------------------------------------------
function DB.userRow(uid)
    if not uid then return nil end
    return MySQL.single.await([[
        SELECT id, username, level, playtime,
               `group`, group_rank, group_join, group_warning,
               group_supervisor, group_tester, group_permissions
        FROM users WHERE id = ? LIMIT 1
    ]], { uid })
end

function DB.factionRow(fid)
    if not fid then return nil end
    return MySQL.single.await('SELECT * FROM factions WHERE id = ? LIMIT 1', { fid })
end

function DB.rankRows(fid)
    return MySQL.query.await(
        'SELECT * FROM faction_ranks WHERE faction_id = ? ORDER BY rank_order ASC', { fid }) or {}
end

function DB.memberCount(fid)
    return tonumber(MySQL.scalar.await('SELECT COUNT(*) FROM users WHERE `group` = ?', { fid })) or 0
end
