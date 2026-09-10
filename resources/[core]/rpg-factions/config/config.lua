-- ===========================================================================
--  rpg-factions — CONFIG (shared client + server)
--
--  DB = source of truth pentru datele facțiunilor (factions / faction_ranks /
--  applications / logs). Config-ul e pentru: security, defaults, UI, interaction.
-- ===========================================================================
Config = {}

Config.Debug = true

-- ---- COMANDA / KEYBIND ------------------------------------------------
Config.Command = 'faction'
Config.Keybind = ''                 -- '' = doar /faction ; ex. 'F6'

-- ---- PLAYTIME -------------------------------------------------------
-- Framework.GetPlaytimeHours foloseste asta pt. conversia users.playtime -> ore.
-- Serverul acesta stocheaza playtime in SECUNDE -> 3600. Pune 60 daca e in minute.
Config.PlaytimeSecondsPerHour = 3600

-- ===========================================================================
--  PERMISIUNI — lista master (validare + UI). Orice cheie ne-listata e respinsa.
-- ===========================================================================
Config.Permissions = {
    'view_members', 'view_applications', 'view_logs',
    'invite', 'kick', 'promote', 'demote',
    'manage_warnings', 'manage_applications', 'review_applications',
    'manage_members', 'manage_permissions',
    'manage_supervisors', 'manage_testers',
    'manage_hq',
    -- CRITICE (vezi mai jos) — nu se acorda automat prin `*`
    'manage_ranks', 'manage_settings', 'set_leader', 'set_manager', 'delete_faction',
}

-- set derivat (lookup rapid) — populat mai jos
Config._PermSet = {}
for _, p in ipairs(Config.Permissions) do Config._PermSet[p] = true end

-- Permisiunile CRITICE se acorda DOAR daca:
--   userul are cheia explicit `true` in group_permissions,  SAU
--   rank-ul lui are `is_leader = 1`.
-- `*` (wildcard) NU le acorda.
Config.CriticalPermissions = {
    manage_ranks = true, manage_settings = true,
    set_leader = true, set_manager = true, delete_faction = true,
}

-- Permisiuni adaugate automat cand group_supervisor = 1 (peste rank).
Config.SupervisorPermissions = {
    view_members = true, view_applications = true,
    manage_warnings = true, manage_applications = true,
}

-- Permisiuni adaugate automat cand group_tester = 1 (peste rank).
Config.TesterPermissions = {
    view_applications = true, review_applications = true,
}

-- ===========================================================================
--  RANK-URI IMPLICITE — folosite DOAR la crearea unei facțiuni noi
--  (dupa aceea sunt editabile in DB / prin manage_ranks).
--  rank_order 1 = cel mai jos. Ultimul = Leader (is_leader). Penultimul = Co-Leader.
-- ===========================================================================
Config.DefaultRanks = {
    { order = 1, name = 'rank1',   label = 'Rank 1',    salary = 0,
      permissions = { view_members = true } },
    { order = 2, name = 'rank2',   label = 'Rank 2',    salary = 0,
      permissions = { view_members = true, invite = true } },
    { order = 3, name = 'rank3',   label = 'Rank 3',    salary = 0,
      permissions = { view_members = true, invite = true, manage_warnings = true, view_applications = true } },
    { order = 4, name = 'rank4',   label = 'Rank 4',    salary = 0,
      permissions = { view_members = true, invite = true, manage_warnings = true, view_applications = true,
                      promote = true, demote = true, kick = true } },
    { order = 5, name = 'rank5',   label = 'Rank 5',    salary = 0,
      permissions = { view_members = true, invite = true, manage_warnings = true, view_applications = true,
                      promote = true, demote = true, kick = true, manage_applications = true,
                      manage_members = true, view_logs = true } },
    { order = 6, name = 'coleader', label = 'Co-Leader', salary = 0, is_coleader = true,
      permissions = { ['*'] = true } },
    { order = 7, name = 'leader',   label = 'Leader',    salary = 0, is_leader = true,
      permissions = { ['*'] = true } },
}
Config.DefaultInitialRank = 1        -- rank_order acordat la join

-- ===========================================================================
--  WARNING
-- ===========================================================================
Config.Warning = { min = 0, max = 100 }

-- ===========================================================================
--  TIPURI DE FACȚIUNE (UI + validare la creare). Primul = default.
-- ===========================================================================
Config.FactionTypes = { 'department', 'peacefull', 'hitman', 'gang' }

-- ===========================================================================
--  SECURITY
-- ===========================================================================
Config.Security = {
    eventCooldownMs   = 400,      -- anti-spam per src per event
    hqRadius          = 3.0,      -- m: raza server-side pt. HQ enter/leave
    maxLogsPerPage    = 25,
    maxMembersPerPage = 50,
    logSuspicious     = true,     -- logheaza tentativele de exploit in faction_logs
    -- staff (rpg-auth) care poate folosi comenzile de administrare globala
    adminRank         = 'manager',
}

-- ===========================================================================
--  UI
-- ===========================================================================
Config.UI = {
    -- ce butoane din dashboard sunt gatuite de ce permisiune
    tabs = {
        members      = 'view_members',
        applications = 'view_applications',
        logs         = 'view_logs',
        manage       = 'manage_members',   -- „Manage" apare daca ai cel putin una din perm. de management
        hq           = nil,                -- HQ apare daca esti membru + faction are hq_vw ~= 0
    },
}

return Config
