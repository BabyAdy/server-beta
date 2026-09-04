-- ===========================================================================
--  rpg-auth — server
--
--  NOTĂ SECURITATE (dev): parolele sunt stocate ca SHA-256(salt + parolă),
--  hash-ul fiind calculat de MySQL prin SHA2(). Pentru PRODUCȚIE înlocuiește
--  cu un KDF real (bcrypt / argon2), ex. resursa `bcrypt` sau un modul node.
-- ===========================================================================

local sessions = {}   -- [src] = { id, username, staff }
local cooldown = {}    -- [src] = last request ms

math.randomseed(os.time())

-- ----- migratie schema (coloane pe users + tabela beta_redemptions) --------
CreateThread(function()
    while GetResourceState('oxmysql') ~= 'started' do Wait(200) end
    Wait(400)

    -- coloane lipsa -> se adauga cu DEFAULT (randurile existente primesc default-ul,
    -- valorile deja existente NU sunt atinse)
    local want = {
        staff  = "VARCHAR(25) NOT NULL DEFAULT ''",
        avatar = "VARCHAR(300) DEFAULT NULL",

        -- licente (credit de ore, acordat de staff prin /agl -- vezi rpg-licences); 0 = fara licenta
        driving_licence_hours = "INT UNSIGNED NOT NULL DEFAULT 0",
        weapon_licence_hours  = "INT UNSIGNED NOT NULL DEFAULT 0",
        flying_licence_hours  = "INT UNSIGNED NOT NULL DEFAULT 0",
        sailing_licence_hours = "INT UNSIGNED NOT NULL DEFAULT 0",
    }
    local rows = MySQL.query.await([[
        SELECT COLUMN_NAME AS name FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users'
    ]]) or {}
    local have = {}
    for _, r in ipairs(rows) do have[r.name] = true end

    for col, def in pairs(want) do
        if not have[col] then
            MySQL.query.await(('ALTER TABLE `users` ADD COLUMN `%s` %s'):format(col, def))
            print(('[rpg-auth] Coloana `users`.`%s` a fost adaugata.'):format(col))
        end
    end

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `beta_redemptions` (
            `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `code`        VARCHAR(48)  NOT NULL,
            `account_id`  INT UNSIGNED NOT NULL,
            `reward`      VARCHAR(48)  NOT NULL,
            `redeemed_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `uniq_code` (`code`)
        ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
    ]])
end)

-- ----- helpers staff --------------------------------------------------
local function staffOf(src)
    local s = sessions[src]
    return (s and s.staff and s.staff ~= '') and s.staff or nil
end

-- ----- helpers -------------------------------------------------------------
local function genSalt(len)
    len = len or 32
    local chars, out = '0123456789abcdef', {}
    for i = 1, len do
        local n = math.random(1, #chars)
        out[i] = chars:sub(n, n)
    end
    return table.concat(out)
end

local function getLicense(src)
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:sub(1, 8) == 'license:' then return id end
    end
    return nil
end

-- ===========================================================================
--  vMenu — acces TOTAL (inclusiv functiile dezactivate implicit) pentru:
--    - contul cu users.id = 1
--    - staff >= manager (include automat owner, care e superior lui manager)
--  Foloseste mecanismul PROPRIU al vMenu: ACE "vMenu.Everything" (vezi
--  server.cfg: add_ace group.rpg_vmenu_full "vMenu.Everything" allow).
--  Nu atingem resources/vMenu/config/permissions.cfg -- doar acordam/retragem
--  dinamic apartenenta la grupul dedicat, in functie de cont/grad.
-- ===========================================================================
local VMENU_GROUP = 'rpg_vmenu_full'
local vmenuGranted = {}   -- [src] = "identifier.license:..." (cui i-am acordat deja)

local function vmenuQualifies(accountId, rank)
    return tonumber(accountId) == 1 or Staff.level(rank or '') >= Staff.level('manager')
end

local function vmenuApply(src, accountId, rank, license)
    license = license or getLicense(src)
    if not license then return end
    local principal = 'identifier.' .. license

    local qualifies = vmenuQualifies(accountId, rank)
    local already = vmenuGranted[src]

    if qualifies and not already then
        ExecuteCommand(('add_principal %s group.%s'):format(principal, VMENU_GROUP))
        vmenuGranted[src] = principal
        print(('[rpg-auth] vMenu: acces total ACORDAT contului #%s'):format(accountId))
    elseif not qualifies and already then
        ExecuteCommand(('remove_principal %s group.%s'):format(already, VMENU_GROUP))
        vmenuGranted[src] = nil
        print(('[rpg-auth] vMenu: acces total RETRAS contului #%s'):format(accountId))
    end
end

local function trim(s)
    return (tostring(s or ''):gsub('^%s*(.-)%s*$', '%1'))
end

local function respond(src, id, ok, message, data)
    TriggerClientEvent('rpg-auth:response', src, id, ok, message, data)
end

local function throttled(src)
    local now = GetGameTimer()
    if cooldown[src] and (now - cooldown[src]) < Config.RequestCooldown then
        return true
    end
    cooldown[src] = now
    return false
end

local EMAIL_RE = '^[%w%.%%%+%-_]+@[%w%.%-]+%.%a%a+$'
local USER_RE  = '^[%w%._%-]+$'

-- ----- REGISTER ----------------------------------------------------------
local function handleRegister(src, id, p)
    local username = trim(p and p.username)
    local email    = trim(p and p.email):lower()
    local password = tostring(p and p.password or '')
    local confirm  = tostring(p and p.confirm or '')

    if #username < Config.MinUsername or #username > Config.MaxUsername then
        return respond(src, id, false, ('Username-ul trebuie să aibă între %d și %d caractere.'):format(Config.MinUsername, Config.MaxUsername))
    end
    if not username:match(USER_RE) then
        return respond(src, id, false, 'Username-ul poate conține doar litere, cifre, . _ -')
    end
    if not email:match(EMAIL_RE) then
        return respond(src, id, false, 'Adresa de email este invalidă.')
    end
    if #password < Config.MinPassword or #password > Config.MaxPassword then
        return respond(src, id, false, ('Parola trebuie să aibă între %d și %d caractere.'):format(Config.MinPassword, Config.MaxPassword))
    end
    if password ~= confirm then
        return respond(src, id, false, 'Parolele nu coincid.')
    end

    local license = getLicense(src)
    if Config.BindIdentifierOnRegister and not license then
        return respond(src, id, false, 'Nu am putut identifica contul tău Cfx/FiveM.')
    end

    if MySQL.scalar.await('SELECT 1 FROM users WHERE username = ? LIMIT 1', { username }) then
        return respond(src, id, false, 'Acest username este deja folosit.')
    end
    if MySQL.scalar.await('SELECT 1 FROM users WHERE email = ? LIMIT 1', { email }) then
        return respond(src, id, false, 'Există deja un cont cu acest email.')
    end
    if Config.OneAccountPerIdentifier and license then
        if MySQL.scalar.await('SELECT 1 FROM users WHERE identifier = ? LIMIT 1', { license }) then
            return respond(src, id, false, 'Ai deja un cont creat pe acest profil.')
        end
    end

    local salt = genSalt(32)
    local insertId = MySQL.insert.await([[
        INSERT INTO users (username, email, password, salt, identifier, created_at)
        VALUES (?, ?, SHA2(CONCAT(?, ?), 256), ?, ?, NOW())
    ]], {
        username, email,
        salt, password,   -- SHA2(CONCAT(salt, password), 256)
        salt,
        Config.BindIdentifierOnRegister and license or nil,
    })

    if not insertId then
        return respond(src, id, false, 'Eroare la crearea contului. Încearcă din nou.')
    end

    print(('[rpg-auth] Cont nou #%d "%s" (%s)'):format(insertId, username, license or 'fără license'))
    return respond(src, id, true, 'Cont creat cu succes! Te poți autentifica acum.')
end

-- ----- LOGIN -----------------------------------------------------------
local function handleLogin(src, id, p)
    local username = trim(p and p.username)
    local password = tostring(p and p.password or '')

    if username == '' or password == '' then
        return respond(src, id, false, 'Completează username-ul și parola.')
    end

    local row = MySQL.single.await([[
        SELECT id, username, identifier, banned, ban_reason, staff, avatar
        FROM users
        WHERE username = ? AND password = SHA2(CONCAT(salt, ?), 256)
        LIMIT 1
    ]], { username, password })

    if not row then
        return respond(src, id, false, 'Username sau parolă incorecte.')
    end
    if row.banned == 1 then
        return respond(src, id, false, ('Cont banat. %s'):format(row.ban_reason or ''))
    end

    local license = getLicense(src)
    if Config.RequireIdentifierMatch and row.identifier and license and row.identifier ~= license then
        return respond(src, id, false, 'Acest cont este legat de alt profil FiveM.')
    end

    MySQL.update.await(
        'UPDATE users SET last_login = NOW(), last_ip = ?, identifier = COALESCE(identifier, ?) WHERE id = ?',
        { GetPlayerEndpoint(src), license, row.id }
    )

    sessions[src] = { id = row.id, username = row.username, staff = row.staff or '', avatar = row.avatar }
    local ply = Player(src)
    if ply and ply.state then
        ply.state:set('authed', true, true)
        ply.state:set('accountId', row.id, true)
        ply.state:set('accountName', row.username, true)
        ply.state:set('staff', row.staff or '', true)
    end
    vmenuApply(src, row.id, row.staff or '', license)

    print(('[rpg-auth] Login: %s (acc #%d) — src %d'):format(row.username, row.id, src))
    return respond(src, id, true, ('Bine ai revenit, %s!'):format(row.username))
end

-- ----- RECOVER (placeholder) --------------------------------------------
local function handleRecover(src, id, p)
    return respond(src, id, true, 'Recuperarea parolei nu este încă disponibilă. Contactează un administrator.')
end

-- ----- router --------------------------------------------------------------
RegisterNetEvent('rpg-auth:request', function(name, id, payload)
    local src = source
    if type(id) ~= 'number' then return end
    if throttled(src) then
        return respond(src, id, false, 'Prea multe cereri. Așteaptă o secundă.')
    end

    if name == 'login' then
        handleLogin(src, id, payload)
    elseif name == 'register' then
        handleRegister(src, id, payload)
    elseif name == 'recover' then
        handleRecover(src, id, payload)
    end
end)

RegisterNetEvent('rpg-auth:finalize', function()
    local src = source
    local sess = sessions[src]
    if not sess then return end
    -- Hook pentru framework: aici încarcă/oferă selecția de personaje.
    TriggerEvent('core:playerLoggedIn', src, sess.id, sess.username)
end)

AddEventHandler('playerDropped', function()
    local src = source
    sessions[src] = nil
    cooldown[src] = nil
    vmenuGranted[src] = nil
end)

-- ----- export pentru alte resurse ---------------------------------------
exports('getAccount', function(src)
    return sessions[src]
end)

exports('isAuthed', function(src)
    return sessions[src] ~= nil
end)

-- ===========================================================================
--  STAFF API
-- ===========================================================================
exports('getStaff',      function(src) return staffOf(src) or '' end)
exports('getStaffLevel', function(src) return Staff.level(staffOf(src)) end)
exports('getStaffLabel', function(src) return Staff.label(staffOf(src)) end)
exports('getStaffColor', function(src) return Staff.color(staffOf(src)) end)
exports('isStaff',       function(src) return Staff.level(staffOf(src)) > 0 end)
exports('hasStaffLevel', function(src, minRank)
    return Staff.level(staffOf(src)) >= Staff.level(minRank)
end)

exports('getStaffByAccountId', function(accountId)
    accountId = tonumber(accountId)
    for _, sess in pairs(sessions) do
        if sess.id == accountId then
            return (sess.staff and sess.staff ~= '') and sess.staff or nil
        end
    end
    local v = MySQL.scalar.await('SELECT staff FROM users WHERE id = ?', { accountId })
    return (v and v ~= '') and v or nil
end)

-- seteaza gradul (rank = '' -> retrage). Nu valideaza ierarhia apelantului;
-- comenzile (rpg-hud) fac verificarea "poti acorda doar sub nivelul tau".
exports('setStaff', function(accountId, rank)
    accountId = tonumber(accountId)
    if not accountId then return false end
    rank = rank or ''
    if rank ~= '' and not Staff.exists(rank) then return false end

    MySQL.update.await('UPDATE users SET staff = ? WHERE id = ?', { rank, accountId })

    for s, sess in pairs(sessions) do
        if sess.id == accountId then
            sess.staff = rank
            local ply = Player(s)
            if ply and ply.state then ply.state:set('staff', rank, true) end
            TriggerClientEvent('core:staffUpdated', s, rank, Staff.label(rank), Staff.color(rank))
            TriggerEvent('core:staffUpdated', s, rank)
            vmenuApply(s, accountId, rank)
        end
    end
    return true
end)

exports('redeemBeta', function(src, code)
    local sess = sessions[src]
    if not sess then return { ok = false, error = 'Neautentificat.' } end

    code = tostring(code or ''):lower():gsub('%s', '')
    local reward = Config.BetaCodes and Config.BetaCodes[code]
    if not reward then return { ok = false, error = 'Cod invalid.' } end

    if MySQL.scalar.await('SELECT 1 FROM beta_redemptions WHERE code = ? LIMIT 1', { code }) then
        return { ok = false, error = 'Codul a fost deja folosit.' }
    end

    local id = MySQL.insert.await(
        'INSERT INTO beta_redemptions (code, account_id, reward) VALUES (?, ?, ?)',
        { code, sess.id, reward })
    if not id then return { ok = false, error = 'Eroare la înregistrarea codului.' } end

    local rewardLabel = reward
    if Staff.exists(reward) then
        MySQL.update.await('UPDATE users SET staff = ? WHERE id = ?', { reward, sess.id })
        sess.staff = reward
        local ply = Player(src)
        if ply and ply.state then ply.state:set('staff', reward, true) end
        rewardLabel = Staff.label(reward)
        TriggerClientEvent('core:staffUpdated', src, reward, Staff.label(reward), Staff.color(reward))
        TriggerEvent('core:staffUpdated', src, reward)
        vmenuApply(src, sess.id, reward)
    end

    print(('[rpg-auth] Beta "%s" folosit de cont #%d -> %s'):format(code, sess.id, reward))
    return { ok = true, reward = reward, rewardLabel = rewardLabel }
end)
