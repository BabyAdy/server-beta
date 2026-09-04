-- ===========================================================================
--  rpg-level — server
--  Autoritate pentru: users.level, users.respectpoints, users.money, users.bank
--  Clientul poate DOAR să ceară "/buylevel" / "/stats"; serverul validează totul.
-- ===========================================================================

local Level = {}
local cache = {}   -- [src] = { accountId, username, level, rp, money, bank }
local DBG = true

-- ---- helperi -----------------------------------------------------------
local function accOf(src)
    local ok, acc = pcall(function() return exports['rpg-auth']:getAccount(src) end)
    return (ok and acc) and acc or nil
end

-- feedback în chat-ul EXISTENT (rpg-hud). channel: SUCCESS | ERROR | INFO
local function feedback(src, channel, text)
    local ok = pcall(function()
        exports['rpg-hud']:addChatMessage(src, { channel = channel, text = text })
    end)
    if not ok then
        TriggerClientEvent('chat:addMessage', src, { color = { 200, 180, 255 }, args = { 'LEVEL', text } })
    end
end

-- împinge economia către HUD-ul existent
local function pushHud(src)
    local s = cache[src]; if not s then return end
    TriggerClientEvent('hud:updateMoney', src, s.money)
    TriggerClientEvent('hud:updateBank',  src, s.bank)
    TriggerClientEvent('hud:updateLevel', src, s.level)   -- rpg-hud nu-l consumă încă; pregătit pt. viitor
end

-- ===========================================================================
--  MIGRAȚIE SCHEMĂ  (fără pierdere de date; rulează o dată la boot)
-- ===========================================================================
CreateThread(function()
    while GetResourceState('oxmysql') ~= 'started' do Wait(200) end
    Wait(500)

    local rows = MySQL.query.await([[
        SELECT COLUMN_NAME AS name FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users'
    ]]) or {}
    local have = {}
    for _, r in ipairs(rows) do have[r.name] = true end

    -- redenumiri istorice (dacă un proiect mai vechi are alte denumiri) -> date PĂSTRATE
    if have.rp and not have.respectpoints then
        MySQL.query.await("ALTER TABLE `users` CHANGE `rp` `respectpoints` INT NOT NULL DEFAULT 0")
        have.respectpoints = true
        print('[rpg-level] users.rp -> users.respectpoints (date păstrate)')
    end
    if have.bankmoney and not have.bank then
        MySQL.query.await("ALTER TABLE `users` CHANGE `bankmoney` `bank` BIGINT NOT NULL DEFAULT 1000")
        have.bank = true
        print('[rpg-level] users.bankmoney -> users.bank (date păstrate)')
    end
    if have.cash and not have.money then
        MySQL.query.await("ALTER TABLE `users` CHANGE `cash` `money` BIGINT NOT NULL DEFAULT 500")
        have.money = true
        print('[rpg-level] users.cash -> users.money (date păstrate)')
    end

    -- coloane lipsă -> se adaugă cu DEFAULT (rândurile existente primesc default-ul,
    -- valorile deja existente NU sunt atinse)
    local want = {
        level         = "INT NOT NULL DEFAULT 1",
        respectpoints = "INT NOT NULL DEFAULT 0",
        money         = "BIGINT NOT NULL DEFAULT 500",
        bank          = "BIGINT NOT NULL DEFAULT 1000",
        playtime        = "BIGINT UNSIGNED NOT NULL DEFAULT 0",   -- secunde de joc ACTIV (total)
        payday          = "INT UNSIGNED NOT NULL DEFAULT 3600",   -- secunde pana la urmatorul payday
        payday_playtime = "INT UNSIGNED NOT NULL DEFAULT 0",      -- secunde active ale ciclului de payday curent
    }
    for col, def in pairs(want) do
        if not have[col] then
            MySQL.query.await(("ALTER TABLE `users` ADD COLUMN `%s` %s"):format(col, def))
            print(('[rpg-level] Coloana users.%s adăugată (%s)'):format(col, def))
        end
    end
end)

-- ===========================================================================
--  ÎNCĂRCARE / INIȚIALIZARE
-- ===========================================================================
function Level.load(src)
    local acc = accOf(src)
    if not acc then return end
    local row = MySQL.single.await(
        'SELECT id, username, level, respectpoints, money, bank, playtime, payday, payday_playtime FROM users WHERE id = ? LIMIT 1',
        { acc.id })
    if not row then return end

    cache[src] = {
        accountId = row.id,
        username  = row.username,
        level     = row.level         or Config.Initial.level,
        rp        = row.respectpoints or Config.Initial.respectpoints,
        money     = row.money         or Config.Initial.money,
        bank      = row.bank          or Config.Initial.bank,

        -- playtime / payday / payday_playtime: contor în MEMORIE, sincronizat periodic cu DB (autosave)
        playtime     = tonumber(row.playtime) or 0,
        payday       = (row.payday ~= nil) and tonumber(row.payday) or Config.Payday.interval,
        -- activ acumulat ÎN CICLUL curent — restaurat din DB (disconnect/crash safe)
        paydayActive = tonumber(row.payday_playtime) or 0,
        paydayLock   = false,    -- protecție dublă acordare
        dirty        = false,
        lastActivityTick = os.time(),
    }
    pushHud(src)

    -- conectează timer-ul din HUD-ul EXISTENT la valoarea reală din DB
    TriggerClientEvent('hud:updatePaycheck', src, { seconds = cache[src].payday, running = true })

    if DBG then
        print(('[rpg-level] Încărcat cont #%s: Lv%d RP%d $%d bank $%d | playtime %ds, payday %ds')
            :format(row.id, cache[src].level, cache[src].rp, cache[src].money, cache[src].bank,
                    cache[src].playtime, cache[src].payday))
    end
end

function Level.reload(src)
    local s = cache[src]; if not s then return end
    local row = MySQL.single.await(
        'SELECT level, respectpoints, money, bank FROM users WHERE id = ? LIMIT 1', { s.accountId })
    if row then
        s.level = row.level; s.rp = row.respectpoints; s.money = row.money; s.bank = row.bank
        pushHud(src)
    end
end

-- personaj NOU -> setează valorile de start (o singură dată, la creare)
AddEventHandler('core:characterCreated', function(src)
    local acc = accOf(src)
    if not acc then return end
    MySQL.update.await(
        'UPDATE users SET level = ?, respectpoints = ?, money = ?, bank = ?, playtime = 0, payday = ?, payday_playtime = 0 WHERE id = ?',
        { Config.Initial.level, Config.Initial.respectpoints, Config.Initial.money, Config.Initial.bank,
          Config.Payday.interval, acc.id })
    if cache[src] then
        cache[src].level = Config.Initial.level
        cache[src].rp    = Config.Initial.respectpoints
        cache[src].money = Config.Initial.money
        cache[src].bank  = Config.Initial.bank
        cache[src].playtime     = 0
        cache[src].payday       = Config.Payday.interval
        cache[src].paydayActive = 0
        pushHud(src)
        TriggerClientEvent('hud:updatePaycheck', src, { seconds = Config.Payday.interval, running = true })
    end
    print(('[rpg-level] Valori de start acordate contului #%s (Lv1, 0 RP, $%d, bank $%d, playtime 0, payday %ds)')
        :format(acc.id, Config.Initial.money, Config.Initial.bank, Config.Payday.interval))
end)

-- încărcare la intrarea în lume (după characterCreated dacă e cazul -> load order)
AddEventHandler('core:characterLoaded', function(src)
    Level.load(src)
end)

-- ===========================================================================
--  SALVARE playtime + payday  (buffer în memorie -> DB periodic / la ieșire)
--  money/bank/level/rp se scriu imediat la fiecare modificare, deci nu aici.
-- ===========================================================================
function Level.persist(src)
    local s = cache[src]; if not s then return end
    MySQL.update.await('UPDATE users SET payday = ?, playtime = ?, payday_playtime = ? WHERE id = ?',
        { math.max(0, math.floor(s.payday)),
          math.max(0, math.floor(s.playtime)),
          math.max(0, math.floor(s.paydayActive)),
          s.accountId })
    s.dirty = false
end

function Level.saveAllDirty()
    for _, pid in ipairs(GetPlayers()) do          -- listă vie -> sigură dacă cineva pleacă în timpul await-ului
        local src = tonumber(pid)
        local s = cache[src]
        if s and s.dirty then Level.persist(src) end
    end
end

AddEventHandler('playerDropped', function()
    local src = source
    if cache[src] then
        Level.persist(src)          -- disconnect / kick -> salvează secundele REALE rămase
    end
    cache[src] = nil
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for src in pairs(cache) do Level.persist(src) end   -- restart resursă -> nu pierde progresul
end)

-- autosave periodic (crash-safe: nu ne bazăm doar pe playerDropped)
CreateThread(function()
    while true do
        Wait(Config.Autosave.interval * 1000)
        Level.saveAllDirty()
        -- resincronizează HUD-ul cu timer-ul real (contra drift-ului de pe client)
        for _, pid in ipairs(GetPlayers()) do
            local src = tonumber(pid)
            local s = cache[src]
            if s then
                TriggerClientEvent('hud:updatePaycheck', src,
                    { seconds = math.max(0, math.floor(s.payday)), running = true })
            end
        end
    end
end)

-- ===========================================================================
--  /buylevel  — TRANZACȚIE ATOMICĂ
-- ===========================================================================
function Level.buy(src)
    local s = cache[src]
    if not s then
        return feedback(src, 'ERROR', 'Statisticile tale nu sunt încărcate. Reintră pe server.')
    end

    local cur = s.level
    local req = Config.nextRequirement(cur)   -- întoarce mereu ceva (nu există max level)

    -- suficiente Respect Points? (nu se scade nimic dacă nu)
    if s.rp < req.rp then
        return feedback(src, 'ERROR',
            ('Nu ai suficiente Respect Points. Necesare: %d RP.'):format(req.rp))
    end

    -- suficienți bani CASH (users.money, NU bank)? (nu se scade nimic dacă nu)
    if s.money < req.money then
        return feedback(src, 'ERROR',
            ('Nu ai suficienți bani cash. Necesari: %s$.'):format(Config.formatMoney(req.money)))
    end

    -- Verificare + scădere RP + scădere money + creștere level  =>  UN SINGUR UPDATE condiționat.
    -- Dacă starea din DB nu mai corespunde (race / altă tranzacție), WHERE nu se potrivește
    -- și nu se modifică nimic -> stare consistentă garantată.
    local affected = MySQL.update.await([[
        UPDATE users
        SET level         = level + 1,
            respectpoints = respectpoints - ?,
            money         = money - ?
        WHERE id = ?
          AND level = ?
          AND respectpoints >= ?
          AND money >= ?
    ]], { req.rp, req.money, s.accountId, cur, req.rp, req.money })

    if not affected or affected < 1 then
        Level.reload(src)   -- resincronizează din DB, nimic pierdut
        return feedback(src, 'ERROR', 'Tranzacție eșuată (date modificate între timp). Încearcă din nou.')
    end

    s.level = cur + 1
    s.rp    = s.rp - req.rp
    s.money = s.money - req.money
    pushHud(src)

    feedback(src, 'SUCCESS', ('Ai avansat la Level %d! Ai cheltuit %d Respect Points și %s$.')
        :format(s.level, req.rp, Config.formatMoney(req.money)))

    TriggerEvent('rpg-level:levelUp', src, s.level, cur)   -- hook pentru notificări / rewards viitoare
    if DBG then print(('[rpg-level] cont #%s: Lv%d -> Lv%d (-%d RP, -$%d)')
        :format(s.accountId, cur, s.level, req.rp, req.money)) end
end

RegisterCommand('buylevel', function(src)
    if src <= 0 then
        print('[rpg-level] /buylevel nu poate fi rulat din consolă.')
        return
    end
    Level.buy(src)
end, false)

-- ===========================================================================
--  ACTIVE PLAYTIME  —  clientul raportează DOAR "activ / inactiv" + fereastra.
--  Serverul acumulează (mărginit de timpul real scurs). SERVER AUTHORITY.
-- ===========================================================================
RegisterNetEvent('rpg-level:activityTick', function(active, windowSeconds)
    local src = source
    local s = cache[src]
    if not s then return end

    windowSeconds = tonumber(windowSeconds) or 0
    if windowSeconds < 1 or windowSeconds > 15 then return end   -- fereastră sanity

    -- ANTI-EXPLOIT: nu poate depăși timpul REAL scurs de la ultimul tick reușit.
    -- Dacă vin mai multe tick-uri în aceeași secundă, cele în plus se ignoră
    -- (lastActivityTick NU se actualizează -> următorul tick acoperă tot golul).
    local now     = os.time()
    local elapsed = now - (s.lastActivityTick or now)
    if elapsed < 1 then return end
    s.lastActivityTick = now

    local grant = math.min(windowSeconds, elapsed)

    if active == true then
        s.playtime     = s.playtime + grant       -- total (users.playtime)
        s.paydayActive = s.paydayActive + grant   -- activ în ciclul de payday curent
        s.dirty = true
    end
end)

-- ===========================================================================
--  PAYDAY  —  countdown server-side (memorie) + tranzacție atomică la 00:00
-- ===========================================================================
function Level.runPayday(src)
    local s = cache[src]
    if not s then return end
    if s.paydayLock then return end   -- DUPLICATE PAYDAY PROTECTION
    s.paydayLock = true

    local activeSecs = s.paydayActive
    local eligible   = activeSecs >= Config.Payday.minActiveSeconds

    -- reset timer + secunde active pentru NOUL ciclu (indiferent de eligibilitate)
    s.payday       = Config.Payday.interval
    s.paydayActive = 0
    s.dirty = true

    if eligible then
        -- ORDINEA din spec: dobânda pe soldul de bancă ÎNAINTE de salariu
        local bankBefore = s.bank
        local rate       = Config.interestRate(bankBefore)
        local interest   = math.floor(bankBefore * rate)
        local bankDelta  = interest + Config.Payday.salary
        local rpDelta    = Config.Payday.respectReward

        -- TRANZACȚIE ATOMICĂ: bank + RP + payday (+ reset ciclu) într-un SINGUR UPDATE
        local affected = MySQL.update.await([[
            UPDATE users
            SET bank            = bank + ?,
                respectpoints   = respectpoints + ?,
                payday          = ?,
                playtime        = ?,
                payday_playtime = 0
            WHERE id = ?
        ]], { bankDelta, rpDelta, Config.Payday.interval, math.max(0, math.floor(s.playtime)), s.accountId })

        if affected and affected >= 1 then
            s.bank = s.bank + bankDelta
            s.rp   = s.rp + rpDelta
            s.dirty = false            -- tocmai am persistat playtime+payday aici
            pushHud(src)

            TriggerClientEvent('rpg-level:payday', src, {
                activeSeconds = activeSecs,
                rp            = rpDelta,
                salary        = Config.Payday.salary,
                interest      = interest,
                ratePercent   = rate * 100,
            })
            TriggerEvent('rpg-level:paydayGranted', src, {
                rp = rpDelta, salary = Config.Payday.salary, interest = interest, activeSeconds = activeSecs })

            print(('[rpg-level] Payday cont #%s: +%d RP, +$%d salariu, +$%d dobândă (%.2f%%) | bank $%d -> $%d')
                :format(s.accountId, rpDelta, Config.Payday.salary, interest, rate * 100, bankBefore, s.bank))
        else
            -- UPDATE nu a atins niciun rând (cont șters?) -> nu s-a acordat nimic;
            -- timer-ul rămâne resetat în memorie, autosave-ul îl va persista.
            print(('[rpg-level] Payday cont #%s: UPDATE 0 rânduri, recompensă neacordată.'):format(s.accountId))
        end
    else
        -- neeligibil: doar resetul ciclului se persistă (fără salariu/RP/dobândă)
        MySQL.update.await('UPDATE users SET payday = ?, playtime = ?, payday_playtime = 0 WHERE id = ?',
            { Config.Payday.interval, math.max(0, math.floor(s.playtime)), s.accountId })
        s.dirty = false
        if DBG then print(('[rpg-level] Payday RATAT cont #%s (activ %ds < %ds necesare)')
            :format(s.accountId, activeSecs, Config.Payday.minActiveSeconds)) end
    end

    -- resincronizează timer-ul din HUD-ul EXISTENT la 60:00
    TriggerClientEvent('hud:updatePaycheck', src, { seconds = Config.Payday.interval, running = true })
    s.paydayLock = false
end

-- countdown: UN SINGUR thread pentru toți playerii (nu unul per player).
-- Doar memorie: scade payday cu 1/secundă. NIMIC în DB aici (vezi autosave).
CreateThread(function()
    while true do
        Wait(1000)
        for _, pid in ipairs(GetPlayers()) do        -- listă vie -> sigură dacă cineva pleacă în await-ul din runPayday
            local src = tonumber(pid)
            local s = cache[src]
            if s and type(s.payday) == 'number' then
                if s.payday > 0 then
                    s.payday = s.payday - 1
                    s.dirty  = true
                end
                if s.payday <= 0 and not s.paydayLock then
                    Level.runPayday(src)
                end
            end
        end
    end
end)

-- ===========================================================================
--  /stats  — trimite DOAR statisticile proprii ale playerului autentificat
-- ===========================================================================
RegisterNetEvent('rpg-level:requestStats', function()
    local src = source
    local s = cache[src]
    if not s then
        return feedback(src, 'ERROR', 'Statisticile tale nu sunt încărcate încă.')
    end

    local req = Config.nextRequirement(s.level)   -- mereu prezent (nu există max level)
    TriggerClientEvent('rpg-level:openStats', src, {
        id       = s.accountId,        -- users.id
        username = s.username,
        level    = s.level,
        rp       = s.rp,
        money    = s.money,
        bank     = s.bank,
        playtime = s.playtime,         -- secunde -> UI afișează HH.MM
        next     = { rp = req.rp, money = req.money },
    })
end)

-- ===========================================================================
--  API PENTRU ALTE RESURSE (jobs / quests / achievements / rewards viitoare)
-- ===========================================================================
local function setField(src, field, value)
    local s = cache[src]; if not s then return false end
    value = math.floor(tonumber(value) or 0)
    if value < 0 then value = 0 end
    MySQL.update.await(('UPDATE users SET `%s` = ? WHERE id = ?'):format(field), { value, s.accountId })
    if field == 'respectpoints' then s.rp = value else s[field] = value end
    pushHud(src)
    return true
end

local function addField(src, field, delta)
    local s = cache[src]; if not s then return false end
    local cur = (field == 'respectpoints') and s.rp or s[field]
    return setField(src, field, cur + (tonumber(delta) or 0))
end

exports('getStats', function(src) return cache[src] end)
exports('getLevel', function(src) return cache[src] and cache[src].level or Config.Initial.level end)
exports('getRP',    function(src) return cache[src] and cache[src].rp or 0 end)
exports('getMoney', function(src) return cache[src] and cache[src].money or 0 end)
exports('getBank',  function(src) return cache[src] and cache[src].bank or 0 end)

exports('addRP',    function(src, n) return addField(src, 'respectpoints', n) end)
exports('addMoney', function(src, n) return addField(src, 'money', n) end)
exports('addBank',  function(src, n) return addField(src, 'bank', n) end)
exports('setMoney', function(src, v) return setField(src, 'money', v) end)
exports('setBank',  function(src, v) return setField(src, 'bank', v) end)
exports('setRP',    function(src, v) return setField(src, 'respectpoints', v) end)

exports('levelRequirement', function(targetLevel)
    return Config.LevelRequirements[targetLevel] or Config.LevelFormula(targetLevel)
end)
exports('canBuyLevel', function(src)
    local s = cache[src]; if not s then return false end
    local req = Config.nextRequirement(s.level)
    return s.rp >= req.rp and s.money >= req.money
end)

-- ===========================================================================
--  COMENZI STAFF  —  /give · /debugsec · /debugpayday   (necesită staff >= owner)
--  "sql id" = users.id (același id afișat în /stats ca „SQL ID”).
--  Țintele trebuie să fie ONLINE (comenzile operează pe starea vie: cache + HUD).
-- ===========================================================================

-- poate rula comanda: consolă sau staff cu grad >= minRank
local function staffCmdAllowed(src, minRank)
    if src <= 0 then return true end
    local ok, allowed = pcall(function() return exports['rpg-auth']:hasStaffLevel(src, minRank) end)
    return ok and allowed == true
end

-- numele de cont (users.username) + label-ul de grad al lui src
local function cmdIssuer(src)
    if src <= 0 then return 'Consolă', 'Consolă' end
    local s = cache[src]
    local name = (s and s.username) or GetPlayerName(src) or ('src' .. src)
    local label = 'Staff'
    local ok, l = pcall(function() return exports['rpg-auth']:getStaffLabel(src) end)
    if ok and l and l ~= '' then label = l end
    return name, label
end

-- src online al unui cont (users.id) -> src, cache-entry  (nil dacă offline)
local function srcByAccountId(accountId)
    accountId = tonumber(accountId)
    if not accountId then return nil end
    for _, pid in ipairs(GetPlayers()) do
        local t = tonumber(pid)
        local s = cache[t]
        if s and s.accountId == accountId then return t, s end
    end
    return nil
end

-- trimite un mesaj în chat DOAR staff-ului online cu grad >= minRank (mereu roșu — Staff.BROADCAST_COLOR)
local function staffBroadcast(minRank, text)
    for _, pid in ipairs(GetPlayers()) do
        local t = tonumber(pid)
        local ok, allowed = pcall(function() return exports['rpg-auth']:hasStaffLevel(t, minRank) end)
        if ok and allowed == true then
            TriggerClientEvent('rpg-hud:chatMessage', t, { text = text, color = Staff.BROADCAST_COLOR, time = os.date('%H:%M') })
        end
    end
    print(('[rpg-level][staff] %s'):format(text))
end

-- /give [sql id] [money|bank|pp|rp] [amount]  — ADAUGĂ amount la câmpul țintei
--   money -> users.money (cash) | bank -> users.bank
--   rp    -> users.respectpoints | pp -> users.payday_playtime (secunde active din ciclul curent)
RegisterCommand('give', function(src, args)
    if not staffCmdAllowed(src, 'owner') then
        return feedback(src, 'ERROR', 'Nu ai acces la această comandă.')
    end

    local targetId = tonumber(args[1])
    local kind     = tostring(args[2] or ''):lower()
    local amount   = tonumber(args[3])
    local FIELD    = { money = 'money', bank = 'bank', rp = 'respectpoints', pp = 'pp' }

    if not targetId or not FIELD[kind] or not amount then
        return feedback(src, 'ERROR', 'Folosire: /give [sql id] [money|bank|pp|rp] [amount]')
    end
    amount = math.floor(amount)

    local tsrc, s = srcByAccountId(targetId)
    if not tsrc or not s then
        return feedback(src, 'ERROR', ('Contul #%s nu este online.'):format(targetId))
    end

    if kind == 'pp' then
        s.paydayActive = math.max(0, math.floor(s.paydayActive + amount))
        s.dirty = true
    else
        addField(tsrc, FIELD[kind], amount)
    end

    local giverName, giverLabel = cmdIssuer(src)
    feedback(src,  'SUCCESS', ('Ai dat %s %s lui %s (#%s).'):format(amount, kind, s.username, targetId))
    feedback(tsrc, 'INFO',    ('Un membru staff ți-a acordat %s %s.'):format(amount, kind))

    -- broadcast: staff >= trialadmin
    staffBroadcast('trialadmin',
        ('Staff: %s %s give %s for %s[%s] amount %s!'):format(
            giverLabel, giverName, kind, s.username, targetId, amount))

    print(('[rpg-level] /give: %s(#%s) -> %s +%s %s'):format(giverName, src, s.username, amount, kind))
end, false)

-- /debugsec [sql id] [payday_playtime]  — SETează secundele active din ciclul de payday curent
RegisterCommand('debugsec', function(src, args)
    if not staffCmdAllowed(src, 'owner') then
        return feedback(src, 'ERROR', 'Nu ai acces la această comandă.')
    end

    local targetId = tonumber(args[1])
    local secs     = tonumber(args[2])
    if not targetId or not secs then
        return feedback(src, 'ERROR', 'Folosire: /debugsec [sql id] [payday_playtime]')
    end
    secs = math.max(0, math.floor(secs))

    local tsrc, s = srcByAccountId(targetId)
    if not tsrc or not s then
        return feedback(src, 'ERROR', ('Contul #%s nu este online.'):format(targetId))
    end

    s.paydayActive = secs
    s.dirty = true

    local giverName = (cmdIssuer(src))
    feedback(src, 'SUCCESS', ('payday_playtime setat la %ds pentru %s (#%s).'):format(secs, s.username, targetId))

    -- broadcast: staff >= manager
    staffBroadcast('manager',
        ('[DEV]:  %s use /debugsec for %s [%s]'):format(giverName, s.username, targetId))
end, false)

-- /debugpayday [sql id]  — setează payday = 10s (test rapid al ciclului de payday)
RegisterCommand('debugpayday', function(src, args)
    if not staffCmdAllowed(src, 'owner') then
        return feedback(src, 'ERROR', 'Nu ai acces la această comandă.')
    end

    local targetId = tonumber(args[1])
    if not targetId then
        return feedback(src, 'ERROR', 'Folosire: /debugpayday [sql id]')
    end

    local tsrc, s = srcByAccountId(targetId)
    if not tsrc or not s then
        return feedback(src, 'ERROR', ('Contul #%s nu este online.'):format(targetId))
    end

    s.payday = 10
    s.dirty  = true
    TriggerClientEvent('hud:updatePaycheck', tsrc, { seconds = s.payday, running = true })

    local giverName = (cmdIssuer(src))
    feedback(src, 'SUCCESS', ('payday setat la 10s pentru %s (#%s). Ciclul rulează în ~10s.'):format(s.username, targetId))

    -- broadcast: staff >= manager
    staffBroadcast('manager',
        ('[DEV]:  %s use /debugpayday for %s [%s]'):format(giverName, s.username, targetId))
end, false)

-- ===========================================================================
--  COMENZI DE TEST  (consolă server sau ACE ph.admin) — utile la testare
-- ===========================================================================
local function admin(src) return src == 0 or IsPlayerAceAllowed(src, 'ph.admin') end

RegisterCommand('addrp', function(src, args)
    local target = tonumber(args[1]) or src
    local amount = tonumber(args[2])
    if not admin(src) or not amount then return end
    if addField(target, 'respectpoints', amount) then
        feedback(target, 'INFO', ('Ai primit %d Respect Points.'):format(amount))
    end
end, false)

RegisterCommand('setcash', function(src, args)
    local target = tonumber(args[1]) or src
    local amount = tonumber(args[2])
    if not admin(src) or not amount then return end
    setField(target, 'money', amount)
end, false)

RegisterCommand('setbank', function(src, args)
    local target = tonumber(args[1]) or src
    local amount = tonumber(args[2])
    if not admin(src) or not amount then return end
    setField(target, 'bank', amount)
end, false)

-- /setpayday <secunde>  — sare timer-ul de payday aproape de 0 pentru test
RegisterCommand('setpayday', function(src, args)
    if not admin(src) then return end
    local target = tonumber(args[2]) and tonumber(args[1]) or src
    local secs   = tonumber(args[2]) or tonumber(args[1])
    local s = cache[target]
    if s and secs then
        s.payday = math.max(0, math.floor(secs)); s.dirty = true
        TriggerClientEvent('hud:updatePaycheck', target, { seconds = s.payday, running = true })
    end
end, false)

-- /setpaydayactive <secunde>  — setează secundele active din ciclul curent (test)
RegisterCommand('setpaydayactive', function(src, args)
    if not admin(src) then return end
    local target = tonumber(args[2]) and tonumber(args[1]) or src
    local secs   = tonumber(args[2]) or tonumber(args[1])
    local s = cache[target]
    if s and secs then s.paydayActive = math.max(0, math.floor(secs)); s.dirty = true end
end, false)

-- /setplaytime <secunde>  — setează playtime total (test)
RegisterCommand('setplaytime', function(src, args)
    if not admin(src) then return end
    local target = tonumber(args[2]) and tonumber(args[1]) or src
    local secs   = tonumber(args[2]) or tonumber(args[1])
    local s = cache[target]
    if s and secs then s.playtime = math.max(0, math.floor(secs)); s.dirty = true end
end, false)
