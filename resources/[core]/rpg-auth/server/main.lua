-- ===========================================================================
--  rpg-auth — server
--
--  NOTĂ SECURITATE (dev): parolele sunt stocate ca SHA-256(salt + parolă),
--  hash-ul fiind calculat de MySQL prin SHA2(). Pentru PRODUCȚIE înlocuiește
--  cu un KDF real (bcrypt / argon2), ex. resursa `bcrypt` sau un modul node.
-- ===========================================================================

local sessions = {}   -- [src] = { id, username }
local cooldown = {}    -- [src] = last request ms

math.randomseed(os.time())

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
        SELECT id, username, identifier, banned, ban_reason
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

    sessions[src] = { id = row.id, username = row.username }
    local ply = Player(src)
    if ply and ply.state then
        ply.state:set('authed', true, true)
        ply.state:set('accountId', row.id, true)
        ply.state:set('accountName', row.username, true)
    end

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
end)

-- ----- export pentru alte resurse ---------------------------------------
exports('getAccount', function(src)
    return sessions[src]
end)

exports('isAuthed', function(src)
    return sessions[src] ~= nil
end)
