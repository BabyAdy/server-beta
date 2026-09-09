-- ===========================================================================
--  rpg-subs — SERVER
--
--  Coloane pe `users` (adaugate automat, cu ordinea ceruta):
--    premiumpoints  INT     -- imediat dupa `bank`
--    sub_legend     BIGINT  -- expiry unix (0 = inactiv)
--    sub_platinum   BIGINT
--    sub_gold       BIGINT
--
--  Statebag replicat pe fiecare player:  Player(src).state.subs = { legend=bool, platinum=bool, gold=bool }
--  (folosit de rpg-nametags). Serverul re-evalueaza expirarea periodic.
--
--  Comenzi:
--    /debugsub [sql id] [gold|platinum|legend] [zile] [ore] [minute]   (owner) — SETEAZA timpul
--    /removesub [sql id] [gold|platinum|legend]                        (owner) — pune 0
--    /shop [buy gold|platinum <zile>]                                          — cumpara ZILE cu Premium Points
--    /vip [text]                                                              — chat VIP (staff sau sub activa)
--
--  Legend NU se cumpara din /shop (buyable=false in shared/subs.lua) — doar plati / owner.
-- ===========================================================================

local DBG   = Config.Debug
local cache = {}   -- [src] = { accountId, charId, username, pp, subs = { gold=ts, platinum=ts, legend=ts } }

local function log(...) if DBG then print('[rpg-subs]', ...) end end
local function now() return os.time() end

local function accOf(src)
    local ok, acc = pcall(function() return exports['rpg-auth']:getAccount(src) end)
    return (ok and acc) or nil
end

-- ---- schema (adauga coloanele lipsa, respectand pozitia ceruta) --------
CreateThread(function()
    while GetResourceState('oxmysql') ~= 'started' do Wait(200) end
    Wait(700)   -- lasa rpg-level sa-si faca migrarile lui pe `users` intai

    local rows = MySQL.query.await([[
        SELECT COLUMN_NAME AS name FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users'
    ]]) or {}
    local have = {}
    for _, r in ipairs(rows) do have[r.name] = true end

    if not have.premiumpoints then
        MySQL.query.await("ALTER TABLE `users` ADD COLUMN `premiumpoints` INT NOT NULL DEFAULT 0 AFTER `bank`")
        have.premiumpoints = true
        print('[rpg-subs] users.premiumpoints adaugat (dupa `bank`)')
    end

    -- expiry unix per tip; 0 = inactiv. Ordinea fizica: premiumpoints -> legend -> platinum -> gold
    local afterCol = 'premiumpoints'
    for _, col in ipairs({ 'sub_legend', 'sub_platinum', 'sub_gold' }) do
        if not have[col] then
            MySQL.query.await(("ALTER TABLE `users` ADD COLUMN `%s` BIGINT NOT NULL DEFAULT 0 AFTER `%s`")
                :format(col, afterCol))
            print(('[rpg-subs] users.%s adaugat'):format(col))
        end
        afterCol = col
    end
    log('schema OK')
end)

-- ---- helpers stare ---------------------------------------------------
local function activeMap(src)
    local s = cache[src]
    if not s then return { legend = false, platinum = false, gold = false } end
    local t = now()
    return {
        legend   = (tonumber(s.subs.legend)   or 0) > t,
        platinum = (tonumber(s.subs.platinum) or 0) > t,
        gold     = (tonumber(s.subs.gold)     or 0) > t,
    }
end

local function pushState(src)
    local p = Player(src)
    if not p or not p.state then return end
    p.state:set('subs', activeMap(src), true)   -- replicat -> rpg-nametags
end

local function anyActive(src)
    local m = activeMap(src)
    return m.legend or m.platinum or m.gold
end

-- lista ordonata (legend, platinum, gold) de chei active pt. un src online
local function activeKeys(src)
    local s = cache[src]
    return Subs.activeList(s and s.subs or {}, now())
end

-- ---- DB writes -----------------------------------------------------
local function dbSetSub(accountId, key, expiryTs)
    MySQL.update.await(("UPDATE users SET `sub_%s` = ? WHERE id = ?"):format(key),
        { math.floor(expiryTs or 0), accountId })
end
local function dbSetPP(accountId, value)
    MySQL.update.await("UPDATE users SET premiumpoints = ? WHERE id = ?", { math.floor(value or 0), accountId })
end

-- aplica o subscriptie (SET absolut) — online (cache+state) sau offline (doar DB)
local function applySub(accountId, srcOrNil, key, expiryTs)
    expiryTs = math.max(0, math.floor(expiryTs or 0))
    dbSetSub(accountId, key, expiryTs)
    if srcOrNil and cache[srcOrNil] then
        cache[srcOrNil].subs[key] = expiryTs
        pushState(srcOrNil)
    end
end

-- adauga ZILE peste ce exista deja (stacking) — doar online
local function addSubDays(src, key, days)
    local s = cache[src]; if not s then return false end
    days = tonumber(days) or 0
    if days <= 0 or not Subs.isValid(key) then return false end
    local base = math.max(now(), tonumber(s.subs[key]) or 0)
    s.subs[key] = base + math.floor(days * 86400)
    dbSetSub(s.accountId, key, s.subs[key])
    pushState(src)
    return true, s.subs[key]
end

local function addPremiumPoints(src, amount)
    local s = cache[src]; if not s then return false end
    amount = math.floor(tonumber(amount) or 0)
    s.pp = math.max(0, (s.pp or 0) + amount)
    dbSetPP(s.accountId, s.pp)
    return true, s.pp
end

-- ---- ciclu de viata ----------------------------------------------
AddEventHandler('core:characterLoaded', function(src, charId, username)
    local acc = accOf(src)
    if not acc then return end
    local row = MySQL.single.await(
        'SELECT premiumpoints, sub_gold, sub_platinum, sub_legend FROM users WHERE id = ? LIMIT 1', { acc.id })
    cache[src] = {
        accountId = acc.id,
        charId    = charId,
        username  = username or (acc.username or GetPlayerName(src)),
        pp        = row and tonumber(row.premiumpoints) or 0,
        subs = {
            gold     = row and tonumber(row.sub_gold)     or 0,
            platinum = row and tonumber(row.sub_platinum) or 0,
            legend   = row and tonumber(row.sub_legend)   or 0,
        },
    }
    pushState(src)
    if DBG then
        local m = activeMap(src)
        log(('cont #%s (%s): PP %d | gold=%s platinum=%s legend=%s')
            :format(acc.id, cache[src].username, cache[src].pp,
                tostring(m.gold), tostring(m.platinum), tostring(m.legend)))
    end
end)

AddEventHandler('playerDropped', function()
    cache[source] = nil
end)

-- re-evalueaza expirarea (ex. o subscriptie a expirat cat era omul online)
CreateThread(function()
    while true do
        Wait((Config.RefreshSec or 60) * 1000)
        for src in pairs(cache) do
            pushState(src)
        end
    end
end)

-- ===========================================================================
--  FEEDBACK / BROADCAST
-- ===========================================================================
local function feedback(src, channel, text)
    if src <= 0 then return print(('[rpg-subs] %s: %s'):format(channel or 'INFO', text)) end
    local ok = pcall(function()
        exports['rpg-hud']:addChatMessage(src, { channel = channel or 'INFO', text = text })
    end)
    if not ok then
        TriggerClientEvent('chat:addMessage', src, { color = { 181, 123, 255 }, args = { 'SUBS', text } })
    end
end

local function issuer(src)
    if src <= 0 then return 'Consolă', 'Consolă' end
    local s = cache[src]
    local name = (s and s.username) or GetPlayerName(src) or ('src' .. src)
    local label = 'Staff'
    local ok, l = pcall(function() return exports['rpg-auth']:getStaffLabel(src) end)
    if ok and l and l ~= '' then label = l end
    return name, label
end

local function staffBroadcast(text)
    local color = (Staff and Staff.BROADCAST_COLOR) or '#ff5555'
    for _, pid in ipairs(GetPlayers()) do
        local t = tonumber(pid)
        local ok, allowed = pcall(function() return exports['rpg-auth']:hasStaffLevel(t, 'trialadmin') end)
        if ok and allowed == true then
            TriggerClientEvent('rpg-hud:chatMessage', t, { text = text, color = color, time = os.date('%H:%M') })
        end
    end
    print(('[rpg-subs][staff] %s'):format(text))
end

local function isAdmin(src)
    if src <= 0 then return true end
    local ok, allowed = pcall(function() return exports['rpg-auth']:hasStaffLevel(src, Config.AdminRank) end)
    return ok and allowed == true
end

-- rezolva un "sql id" (id de PERSONAJ) -> { accountId, username, src }
local function resolveTarget(charId)
    local ok, t = pcall(function() return exports['rpg-characters']:resolveCharacter(tonumber(charId)) end)
    if ok and t and t.accountId then return t end
    return nil
end

-- ===========================================================================
--  /debugsub [sql id] [gold|platinum|legend] [zile] [ore] [minute]   (owner)
--  SETEAZA (absolut) timpul ramas pentru tipul cerut. 0 0 0 -> dezactiveaza.
-- ===========================================================================
RegisterCommand('debugsub', function(src, args)
    if not isAdmin(src) then
        return feedback(src, 'ERROR', 'Nu ai acces la această comandă.')
    end
    local charId = tonumber(args[1])
    local key    = tostring(args[2] or ''):lower()
    local days   = tonumber(args[3]) or 0
    local hours  = tonumber(args[4]) or 0
    local mins   = tonumber(args[5]) or 0

    if not charId or not Subs.isValid(key) then
        return feedback(src, 'ERROR', 'Folosire: /debugsub [sql id] [gold|platinum|legend] [zile] [ore] [minute]')
    end

    local total = math.floor(days) * 86400 + math.floor(hours) * 3600 + math.floor(mins) * 60
    if total < 0 then total = 0 end
    local expiry = (total > 0) and (now() + total) or 0

    local target = resolveTarget(charId)
    if not target then return feedback(src, 'ERROR', 'SQL id inexistent.') end

    applySub(target.accountId, target.src, key, expiry)

    local giverName, giverLabel = issuer(src)
    local human = (total > 0) and Subs.fmtRemaining(total) or 'dezactivată'
    feedback(src, 'SUCCESS', ('Subscripție %s pentru %s (#%s): %s.')
        :format(Subs.def(key).label, target.username or '?', charId, human))
    if target.src then
        feedback(target.src, 'INFO', (total > 0)
            and ('Ai primit subscripția %s: %s.'):format(Subs.def(key).label, human)
            or  ('Subscripția %s ți-a fost dezactivată.'):format(Subs.def(key).label))
    end
    staffBroadcast(('Staff: %s %s a setat subscripția %s pentru %s[%s] la %s.')
        :format(giverLabel, giverName, Subs.def(key).label, target.username or '?', charId, human))
end, false)

-- ===========================================================================
--  /removesub [sql id] [gold|platinum|legend]   (owner) — pune 0
-- ===========================================================================
RegisterCommand('removesub', function(src, args)
    if not isAdmin(src) then
        return feedback(src, 'ERROR', 'Nu ai acces la această comandă.')
    end
    local charId = tonumber(args[1])
    local key    = tostring(args[2] or ''):lower()
    if not charId or not Subs.isValid(key) then
        return feedback(src, 'ERROR', 'Folosire: /removesub [sql id] [gold|platinum|legend]')
    end
    local target = resolveTarget(charId)
    if not target then return feedback(src, 'ERROR', 'SQL id inexistent.') end

    applySub(target.accountId, target.src, key, 0)

    local giverName, giverLabel = issuer(src)
    feedback(src, 'SUCCESS', ('Subscripția %s a fost eliminată pentru %s (#%s).')
        :format(Subs.def(key).label, target.username or '?', charId))
    if target.src then
        feedback(target.src, 'INFO', ('Subscripția %s ți-a fost eliminată.'):format(Subs.def(key).label))
    end
    staffBroadcast(('Staff: %s %s a eliminat subscripția %s de la %s[%s].')
        :format(giverLabel, giverName, Subs.def(key).label, target.username or '?', charId))
end, false)

-- ===========================================================================
--  /shop  — cumpara ZILE de subscriptie cu Premium Points (gold / platinum).
--    /shop                         -> afiseaza preturi + soldul tau
--    /shop buy gold 30             -> 30 zile Gold
-- ===========================================================================
RegisterCommand('shop', function(src, args)
    if src <= 0 then return print('[rpg-subs] /shop e disponibila doar in joc.') end
    local s = cache[src]
    if not s then return feedback(src, 'ERROR', 'Date de cont neîncărcate.') end

    local sub = tostring(args[1] or ''):lower()
    if sub ~= 'buy' then
        feedback(src, 'INFO', ('Premium Points: %d'):format(s.pp or 0))
        for _, key in ipairs({ 'gold', 'platinum' }) do
            feedback(src, 'INFO', ('  %s — %d PP / zi   (ex: /shop buy %s 30)')
                :format(Subs.def(key).label, Config.ShopPricePerDay[key] or 0, key))
        end
        feedback(src, 'INFO', 'Legend nu se poate cumpăra (doar plăți).')
        return
    end

    local key  = tostring(args[2] or ''):lower()
    local days = math.floor(tonumber(args[3]) or 0)
    local def  = Subs.def(key)
    if not def or not def.buyable then
        return feedback(src, 'ERROR', 'Folosire: /shop buy [gold|platinum] [zile]')
    end
    if days < (Config.ShopMinDays or 1) or days > (Config.ShopMaxDays or 365) then
        return feedback(src, 'ERROR', ('Numărul de zile trebuie între %d și %d.')
            :format(Config.ShopMinDays or 1, Config.ShopMaxDays or 365))
    end

    local price = (Config.ShopPricePerDay[key] or 0) * days
    if price <= 0 then return feedback(src, 'ERROR', 'Preț indisponibil.') end
    if (s.pp or 0) < price then
        return feedback(src, 'ERROR', ('Nu ai destule Premium Points (îți trebuie %d, ai %d).'):format(price, s.pp or 0))
    end

    addPremiumPoints(src, -price)
    local _, newExpiry = addSubDays(src, key, days)

    feedback(src, 'SUCCESS', ('Ai cumpărat %d zile %s pentru %d PP. Activă încă: %s.')
        :format(days, def.label, price, Subs.fmtRemaining((newExpiry or now()) - now())))
    log(('src %s a cumparat %d zile %s (%d PP)'):format(src, days, key, price))
end, false)

-- ===========================================================================
--  /vip [text]  — chat special: staff SAU jucatori cu o subscriptie activa.
--  Render (rpg-hud):  (icon-pc) [icon-grad-staff?] [icoane subs...] Username (sql id): text  — mov.
--  Ordinea subs: Legend | Platinum | Gold  (Subs.ORDER).
-- ===========================================================================
local function vipChat(src, text)
    text = tostring(text or ''):gsub('^%s+', ''):gsub('%s+$', '')
    if text == '' then
        return feedback(src, 'ERROR', ('Folosire: /%s [text]'):format(Config.ChatCommand))
    end

    local isStaff = false
    do
        local ok, lvl = pcall(function() return exports['rpg-auth']:isStaff(src) end)
        isStaff = ok and lvl == true
    end
    if not isStaff and not anyActive(src) then
        return feedback(src, 'ERROR', 'Nu ai acces la acest chat (necesită subscripție activă sau staff).')
    end

    local s = cache[src]
    local name = (s and s.username) or GetPlayerName(src) or '?'
    local charId = (s and s.charId) or 0

    -- icon de grad (daca e staff)
    local staffIcon, staffColor
    if isStaff then
        local slug = exports['rpg-auth']:getStaff(src)
        staffIcon  = Staff.iconSvg(slug)
        staffColor = Staff.color(slug)
    end

    -- iconuri subs ACTIVE, in ordinea Legend | Platinum | Gold
    local subIcons = {}
    for _, key in ipairs(activeKeys(src)) do
        local d = Subs.def(key)
        if d then subIcons[#subIcons + 1] = { key = key, icon = d.icon, color = d.color } end
    end

    local payload = {
        channel    = 'VIP',
        vip        = true,
        author     = name,
        id         = charId,
        text       = text,
        time       = os.date('%H:%M'),
        color      = Config.ChatColor,
        staffIcon  = staffIcon,
        staffColor = staffColor,
        subs       = subIcons,
    }

    -- destinatari: staff (orice grad) SAU jucatori cu subscriptie activa
    for _, pid in ipairs(GetPlayers()) do
        local t = tonumber(pid)
        local okS, st = pcall(function() return exports['rpg-auth']:isStaff(t) end)
        if (okS and st == true) or anyActive(t) then
            TriggerClientEvent('rpg-hud:chatMessage', t, payload)
        end
    end
    print(('[vip-chat] %s (%s): %s'):format(name, tostring(charId), text))
end

RegisterCommand(Config.ChatCommand, function(src, args, raw)
    if src <= 0 then return end
    vipChat(src, raw:match('^%S+%s+(.*)$') or '')
end, false)

-- ===========================================================================
--  EXPORTS (pt. alte resurse / "actiuni ce vor urma pe server")
-- ===========================================================================
exports('hasSub',          function(src, key) return activeMap(src)[key] == true end)
exports('anyActiveSub',    function(src) return anyActive(src) end)
exports('activeSubs',      function(src) return activeKeys(src) end)             -- {legend,platinum,gold} ordonat
exports('getSubExpiry',    function(src, key) local s = cache[src]; return s and tonumber(s.subs[key]) or 0 end)
exports('addSubDays',      function(src, key, days) return addSubDays(src, key, days) end)
exports('getPremiumPoints',function(src) return cache[src] and cache[src].pp or 0 end)
exports('addPremiumPoints',function(src, amount) return addPremiumPoints(src, amount) end)
exports('setPremiumPoints',function(src, value)
    local s = cache[src]; if not s then return false end
    s.pp = math.max(0, math.floor(tonumber(value) or 0))
    dbSetPP(s.accountId, s.pp)
    return true, s.pp
end)
