-- ===========================================================================
--  rpg-tickets — server
--  Autoritate completa: DB (oxmysql), permisiuni staff, sync realtime NUI.
--  NUI  ->  client (fetch)  ->  TriggerServerEvent('rpg-tickets:request', ...)
--  server  ->  TriggerClientEvent('rpg-tickets:response' / :push, ...)  ->  NUI
-- ===========================================================================

local DBG = Config.Debug

-- ---------------------------------------------------------------------------
--  HELPERI
-- ---------------------------------------------------------------------------
local function acc(src)
    local ok, a = pcall(function() return exports['rpg-auth']:getAccount(src) end)
    return (ok and a) and a or nil
end

local function licenseOf(src)
    for _, id in ipairs(GetPlayerIdentifiers(src) or {}) do
        if id:sub(1, 8) == 'license:' then return id end
    end
    return nil
end

-- identitate completa a unui player (cont + license + grad staff)
local function identity(src)
    local a = acc(src)
    local lic = licenseOf(src) or ('src:' .. src)
    local staffRank, staffLevel, staffLabel, staffColor = '', 0, 'Civil', '#9aa0aa'
    local oks = pcall(function()
        staffRank  = exports['rpg-auth']:getStaff(src) or ''
        staffLevel = exports['rpg-auth']:getStaffLevel(src) or 0
        staffLabel = exports['rpg-auth']:getStaffLabel(src) or 'Civil'
        staffColor = exports['rpg-auth']:getStaffColor(src) or '#9aa0aa'
    end)
    return {
        src        = src,
        accountId  = a and a.id or nil,
        name       = (a and a.username) or GetPlayerName(src) or ('src' .. src),
        avatar     = a and a.avatar or nil,          -- users.avatar (link imgur) sau nil
        license    = lic,
        staff      = staffRank,
        staffLevel = staffLevel,
        staffLabel = staffLabel,
        staffColor = staffColor,
        isStaff    = staffLevel > 0,
    }
end

local function hasRank(src, rank)
    if src <= 0 then return true end
    local ok, allowed = pcall(function() return exports['rpg-auth']:hasStaffLevel(src, rank) end)
    return ok and allowed == true
end

-- notificare in chat-ul existent (rpg-hud). kind: SUCCESS | ERROR | INFO | STAFF
local function notify(src, kind, text)
    if not src or src <= 0 then
        if DBG then print(('[rpg-tickets] %s: %s'):format(kind or 'INFO', text)) end
        return
    end
    local ok = pcall(function()
        exports['rpg-hud']:addChatMessage(src, { channel = kind, text = text })
    end)
    if not ok then
        TriggerClientEvent('chat:addMessage', src, { color = { 190, 130, 255 }, args = { 'TICHETE', text } })
    end
end

-- lista de src-uri online cu grad >= rank
local function onlineStaff(rank)
    local out = {}
    for _, pid in ipairs(GetPlayers()) do
        local t = tonumber(pid)
        if hasRank(t, rank or Config.StaffOpenRank) then out[#out + 1] = t end
    end
    return out
end

-- trimite un push NUI catre toti staff-ii online
local function pushStaff(kind, payload)
    for _, t in ipairs(onlineStaff(Config.StaffOpenRank)) do
        TriggerClientEvent('rpg-tickets:push', t, kind, payload)
    end
end

local function pushTo(src, kind, payload)
    if src and src > 0 then TriggerClientEvent('rpg-tickets:push', src, kind, payload) end
end

local function reply(src, reqId, ok, data)
    TriggerClientEvent('rpg-tickets:response', src, reqId, ok == true, data)
end

-- src online al unui player dupa license / server id salvat in ticket
local function resolveTicketPlayer(row)
    if not row then return nil end
    for _, pid in ipairs(GetPlayers()) do
        local t = tonumber(pid)
        if licenseOf(t) == row.player_identifier then return t end
    end
    -- fallback: server id (doar daca inca e acelasi player conectat)
    local sid = tonumber(row.player_id)
    if sid and GetPlayerName(sid) and licenseOf(sid) == row.player_identifier then return sid end
    return nil
end

-- ---------------------------------------------------------------------------
--  SHAPERS (row DB -> obiect NUI)
-- ---------------------------------------------------------------------------
local function hm(ts)   -- "2026-09-04 01:19:33" -> "01:19"
    if not ts then return '' end
    return tostring(ts):match('%d%d:%d%d') or tostring(ts)
end

local function shapeTicket(r)
    return {
        id         = r.id,
        category   = r.category,
        reason     = r.reason,
        status     = r.status,                       -- active | claimed | closed
        playerName = r.player_name,
        playerId   = r.player_id,
        staffName  = r.staff_name,
        claimedBy  = r.claimed_by,                    -- license staff (folosit doar la filtrul "ale mele", nu se afiseaza)
        rating     = r.rating,
        time       = hm(r.created_at),
        createdAt  = tostring(r.created_at or ''),
        claimedAt  = r.claimed_at and tostring(r.claimed_at) or nil,
        closedAt   = r.closed_at and tostring(r.closed_at) or nil,
    }
end

local function shapeMsg(r)
    return {
        id       = r.id,
        ticketId = r.ticket_id,
        sender   = r.sender_name,
        isStaff  = (tonumber(r.is_staff) or 0) == 1,
        text     = r.message,
        time     = hm(r.created_at),
    }
end

-- ---------------------------------------------------------------------------
--  SCHEMA — creare automata la boot
-- ---------------------------------------------------------------------------
local function ensureSchema()
    local sql = LoadResourceFile(GetCurrentResourceName(), 'sql/schema.sql')
    if sql then
        for stmt in (sql .. '\n'):gmatch('(.-);%s*\n') do
            local s = stmt:gsub('%-%-[^\n]*', ''):gsub('^%s+', ''):gsub('%s+$', '')
            if s ~= '' then MySQL.query.await(s) end
        end
    end

    -- ensure-columns (in caz ca exista o versiune mai veche a tabelelor)
    local function have(tbl)
        local rows = MySQL.query.await([[
            SELECT COLUMN_NAME AS name FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ?
        ]], { tbl }) or {}
        local h = {}
        for _, r in ipairs(rows) do h[r.name] = true end
        return h
    end
    local function ensure(tbl, want)
        local h = have(tbl)
        for col, def in pairs(want) do
            if not h[col] then
                MySQL.query.await(('ALTER TABLE `%s` ADD COLUMN `%s` %s'):format(tbl, col, def))
                print(('[rpg-tickets] %s.%s adaugat'):format(tbl, col))
            end
        end
    end
    ensure('tickets', {
        rating     = 'TINYINT DEFAULT NULL',
        claimed_at = 'TIMESTAMP NULL DEFAULT NULL',
        closed_at  = 'TIMESTAMP NULL DEFAULT NULL',
    })
    ensure('staff_stats', {
        rating_count         = 'INT NOT NULL DEFAULT 0',
        avg_response_seconds = 'INT NOT NULL DEFAULT 0',
        money_accrued        = 'BIGINT NOT NULL DEFAULT 0',
        money_claimed        = 'BIGINT NOT NULL DEFAULT 0',
        fpt                  = 'INT NOT NULL DEFAULT 0',
        monthly_reset_at     = "DATE NOT NULL DEFAULT '1970-01-01'",
    })

    if DBG then print('[rpg-tickets] schema OK') end
end

CreateThread(function()
    while GetResourceState('oxmysql') ~= 'started' do Wait(200) end
    Wait(400)
    ensureSchema()
end)

-- ---------------------------------------------------------------------------
--  REWARDS — helperi
-- ---------------------------------------------------------------------------
local function firstOfNextMonthStr()
    local t = os.date('*t')
    local y, m = t.year, t.month + 1
    if m > 12 then m = 1; y = y + 1 end
    return ('%04d-%02d-01'):format(y, m)
end

local function dateToEpoch(dstr)   -- "YYYY-MM-DD" -> epoch la 00:00
    local y, m, d = tostring(dstr):match('(%d+)-(%d+)-(%d+)')
    if not y then return 0 end
    return os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 0, min = 0, sec = 0 })
end

-- alege valoarea dintr-un map {threshold=value} dupa cel mai mare threshold <= level
local function pickByLevel(map, level)
    local bestT, bestV = -1, 0
    for t, v in pairs(map) do
        if level >= t and t > bestT then bestT, bestV = t, v end
    end
    return bestV
end

local function payoutFor(level)  return pickByLevel(Config.Rewards.payoutByLevel, level) end
local function milestoneFptFor(level) return pickByLevel(Config.Rewards.milestoneFptByLevel, level) end

-- creeaza randul staff_stats daca lipseste + aplica reset lunar daca e cazul. Intoarce randul.
local function ensureStaffRow(license, name)
    local row = MySQL.single.await('SELECT * FROM staff_stats WHERE identifier = ? LIMIT 1', { license })
    if not row then
        MySQL.update.await([[
            INSERT INTO staff_stats (identifier, staff_name, monthly_reset_at)
            VALUES (?, ?, ?)
            ON DUPLICATE KEY UPDATE staff_name = VALUES(staff_name)
        ]], { license, name or '?', firstOfNextMonthStr() })
        row = MySQL.single.await('SELECT * FROM staff_stats WHERE identifier = ? LIMIT 1', { license })
    end
    if not row then return nil end

    -- reset lunar
    if os.time() >= dateToEpoch(row.monthly_reset_at) then
        MySQL.update.await([[
            UPDATE staff_stats
            SET tickets_closed_monthly = 0, money_accrued = 0, money_claimed = 0, monthly_reset_at = ?
            WHERE identifier = ?
        ]], { firstOfNextMonthStr(), license })
        row.tickets_closed_monthly = 0
        row.money_accrued = 0
        row.money_claimed = 0
        row.monthly_reset_at = firstOfNextMonthStr()
        if DBG then print(('[rpg-tickets] reset lunar pentru %s'):format(license)) end
    end

    -- nume la zi
    if name and name ~= '' and row.staff_name ~= name then
        MySQL.update.await('UPDATE staff_stats SET staff_name = ? WHERE identifier = ?', { name, license })
        row.staff_name = name
    end
    return row
end

local function shapeRewards(row, level)
    local accrued   = tonumber(row.money_accrued) or 0
    local claimed   = tonumber(row.money_claimed) or 0
    local claimable = math.max(0, accrued - claimed)
    local monthly   = tonumber(row.tickets_closed_monthly) or 0
    local milestone = Config.Rewards.milestone
    return {
        monthlyClosed = monthly,
        totalClosed   = tonumber(row.tickets_closed_total) or 0,
        moneyAccrued  = accrued,
        moneyClaimed  = claimed,
        moneyClaimable = claimable,
        fpt           = tonumber(row.fpt) or 0,
        perTicket     = payoutFor(level),
        fptPerTickets = Config.Rewards.fptPerTickets,
        milestone     = milestone,
        milestoneReached = monthly >= milestone,
        milestoneFpt  = milestoneFptFor(level),
        resetAt       = tostring(row.monthly_reset_at),
        resetInSeconds = math.max(0, dateToEpoch(row.monthly_reset_at) - os.time()),
    }
end

-- ---------------------------------------------------------------------------
--  QUERIES
-- ---------------------------------------------------------------------------
local function myTickets(license)
    local rows = MySQL.query.await([[
        SELECT * FROM tickets WHERE player_identifier = ?
        ORDER BY (status = 'closed') ASC, created_at DESC LIMIT 50
    ]], { license }) or {}
    local out = {}
    for _, r in ipairs(rows) do out[#out + 1] = shapeTicket(r) end
    return out
end

local function staffTickets()
    local rows = MySQL.query.await([[
        SELECT * FROM tickets WHERE status IN ('active','claimed')
        ORDER BY (status = 'active') DESC, created_at ASC LIMIT 100
    ]]) or {}
    local out = {}
    for _, r in ipairs(rows) do out[#out + 1] = shapeTicket(r) end
    return out
end

local function ticketMessages(ticketId)
    local rows = MySQL.query.await([[
        SELECT * FROM ticket_messages WHERE ticket_id = ? ORDER BY id ASC
    ]], { ticketId }) or {}
    local out = {}
    for _, r in ipairs(rows) do out[#out + 1] = shapeMsg(r) end
    return out
end

local function getTicket(ticketId)
    return MySQL.single.await('SELECT * FROM tickets WHERE id = ? LIMIT 1', { ticketId })
end

-- statistici pentru sectiunea STATISTICI (mine + global)
local function buildStats(license, name, level)
    local mine = ensureStaffRow(license, name) or {}
    local g = MySQL.single.await([[
        SELECT
          (SELECT COUNT(*) FROM tickets WHERE status = 'active')  AS open_active,
          (SELECT COUNT(*) FROM tickets WHERE status = 'claimed') AS open_claimed,
          (SELECT COUNT(*) FROM tickets WHERE status = 'closed' AND closed_at >= CURDATE()) AS closed_today,
          (SELECT COUNT(*) FROM tickets WHERE status = 'closed'
                 AND YEAR(closed_at) = YEAR(CURDATE()) AND MONTH(closed_at) = MONTH(CURDATE())) AS closed_month,
          (SELECT IFNULL(ROUND(AVG(TIMESTAMPDIFF(SECOND, created_at, claimed_at))),0)
                 FROM tickets WHERE claimed_at IS NOT NULL) AS avg_claim_seconds,
          (SELECT IFNULL(ROUND(AVG(TIMESTAMPDIFF(SECOND, created_at, closed_at))),0)
                 FROM tickets WHERE closed_at IS NOT NULL)  AS avg_close_seconds
    ]]) or {}

    return {
        mine = {
            name          = mine.staff_name,
            closedTotal   = tonumber(mine.tickets_closed_total) or 0,
            closedMonthly = tonumber(mine.tickets_closed_monthly) or 0,
            rating        = tonumber(mine.rating) or 5.0,
            ratingCount   = tonumber(mine.rating_count) or 0,
            avgResponseSeconds = tonumber(mine.avg_response_seconds) or 0,
            fpt           = tonumber(mine.fpt) or 0,
        },
        global = {
            openActive   = tonumber(g.open_active) or 0,
            openClaimed  = tonumber(g.open_claimed) or 0,
            closedToday  = tonumber(g.closed_today) or 0,
            closedMonth  = tonumber(g.closed_month) or 0,
            avgClaimSeconds = tonumber(g.avg_claim_seconds) or 0,
            avgCloseSeconds = tonumber(g.avg_close_seconds) or 0,
        },
        rewards = shapeRewards(mine, level),
    }
end

-- ---------------------------------------------------------------------------
--  ACTIUNI  (dispatch din rpg-tickets:request)
-- ---------------------------------------------------------------------------
local lastMsgAt = {}   -- [src] = tick  (rate-limit mesaje)
local Actions = {}

-- --- player: bootstrap meniu ---
function Actions.bootstrap(src)
    local me = identity(src)
    return true, { self = me, tickets = myTickets(me.license), categories = Config.Categories }
end

-- --- staff: bootstrap meniu ---
function Actions.staffBootstrap(src)
    if not hasRank(src, Config.StaffOpenRank) then return false, { error = 'Fara permisiune.' } end
    local me = identity(src)
    return true, {
        self    = me,
        tickets = staffTickets(),
        stats   = buildStats(me.license, me.name, me.staffLevel),
    }
end

function Actions.fetchMyTickets(src)
    return true, { tickets = myTickets(identity(src).license) }
end

function Actions.fetchStaffTickets(src)
    if not hasRank(src, Config.StaffOpenRank) then return false, { error = 'Fara permisiune.' } end
    return true, { tickets = staffTickets() }
end

function Actions.openTicket(src, data)
    local t = getTicket(tonumber(data and data.ticketId))
    if not t then return false, { error = 'Ticket inexistent.' } end
    local me = identity(src)
    local isOwner = t.player_identifier == me.license
    if not isOwner and not hasRank(src, Config.StaffOpenRank) then
        return false, { error = 'Fara acces la acest ticket.' }
    end
    return true, { ticket = shapeTicket(t), messages = ticketMessages(t.id) }
end

function Actions.createTicket(src, data)
    local me = identity(src)
    local category = tostring(data and data.category or '')
    local reason   = tostring(data and data.reason or ''):gsub('^%s+', ''):gsub('%s+$', '')

    local okCat = false
    for _, c in ipairs(Config.Categories) do if c == category then okCat = true break end end
    if not okCat then category = Config.Categories[1] end

    if #reason < Config.MinReasonLength then
        return false, { error = ('Descriere prea scurta (min %d caractere).'):format(Config.MinReasonLength) }
    end
    if #reason > Config.MaxReasonLength then reason = reason:sub(1, Config.MaxReasonLength) end

    local openCount = tonumber(MySQL.scalar.await([[
        SELECT COUNT(*) FROM tickets WHERE player_identifier = ? AND status IN ('active','claimed')
    ]], { me.license })) or 0
    if openCount >= Config.MaxOpenTicketsPerPlayer then
        return false, { error = ('Ai deja %d tichete deschise. Asteapta raspuns.'):format(openCount) }
    end

    local id = MySQL.insert.await([[
        INSERT INTO tickets (player_identifier, player_name, player_id, category, reason)
        VALUES (?, ?, ?, ?, ?)
    ]], { me.license, me.name, src, category, reason })
    if not id then return false, { error = 'Eroare la salvare. Incearca din nou.' } end

    MySQL.insert.await([[
        INSERT INTO ticket_messages (ticket_id, sender_name, sender_identifier, message, is_staff)
        VALUES (?, ?, ?, ?, 0)
    ]], { id, me.name, me.license, reason })

    local t = shapeTicket(getTicket(id))

    -- realtime -> toti staff-ii
    pushStaff('ticketUpsert', { ticket = t })
    for _, st in ipairs(onlineStaff(Config.StaffOpenRank)) do
        notify(st, 'STAFF', ('Ticket nou #%d (%s) de la %s [%d].'):format(id, category, me.name, src))
    end
    notify(src, 'SUCCESS', ('Ticket #%d trimis. Un membru staff il va prelua in curand.'):format(id))

    if DBG then print(('[rpg-tickets] #%d creat de %s (%s)'):format(id, me.name, me.license)) end
    return true, { ticket = t, tickets = myTickets(me.license) }
end

function Actions.claimTicket(src, data)
    if not hasRank(src, Config.StaffClaimRank) then return false, { error = 'Fara permisiune.' } end
    local me = identity(src)
    local id = tonumber(data and data.ticketId)
    if not id then return false, { error = 'ID lipsa.' } end

    -- atomic: preia doar daca inca e 'active'
    local affected = MySQL.update.await([[
        UPDATE tickets SET status = 'claimed', claimed_by = ?, staff_name = ?, claimed_at = NOW()
        WHERE id = ? AND status = 'active'
    ]], { me.license, me.name, id })
    if not affected or affected < 1 then
        return false, { error = 'Ticketul a fost deja preluat sau inchis.' }
    end

    ensureStaffRow(me.license, me.name)
    local t = shapeTicket(getTicket(id))

    pushStaff('ticketUpsert', { ticket = t })
    local owner = resolveTicketPlayer(getTicket(id))
    if owner then
        pushTo(owner, 'ticketUpsert', { ticket = t })
        notify(owner, 'SUCCESS', ('Ticketul tau #%d a fost preluat de %s.'):format(id, me.name))
    end
    notify(src, 'INFO', ('Ai preluat ticketul #%d.'):format(id))
    return true, { ticket = t }
end

function Actions.sendMessage(src, data)
    local id   = tonumber(data and data.ticketId)
    local text = tostring(data and data.message or ''):gsub('^%s+', ''):gsub('%s+$', '')
    if not id or text == '' then return false, { error = 'Mesaj gol.' } end
    if #text > Config.MaxMessageLength then text = text:sub(1, Config.MaxMessageLength) end

    local now = GetGameTimer()
    if lastMsgAt[src] and (now - lastMsgAt[src]) < Config.MessageRateLimitMs then
        return false, { error = 'Prea repede. Asteapta o secunda.' }
    end
    lastMsgAt[src] = now

    local t = getTicket(id)
    if not t then return false, { error = 'Ticket inexistent.' } end
    if t.status == 'closed' then return false, { error = 'Ticketul este inchis.' } end

    local me = identity(src)
    local isOwner = t.player_identifier == me.license
    local canStaff = hasRank(src, Config.StaffOpenRank)
    if not isOwner and not canStaff then return false, { error = 'Fara acces la acest ticket.' } end
    -- in propriul ticket vorbeste ca JUCATOR chiar daca e staff
    local asStaff = (not isOwner) and canStaff

    MySQL.insert.await([[
        INSERT INTO ticket_messages (ticket_id, sender_name, sender_identifier, message, is_staff)
        VALUES (?, ?, ?, ?, ?)
    ]], { id, me.name, me.license, text, asStaff and 1 or 0 })

    local msg = { ticketId = id, sender = me.name, isStaff = asStaff, text = text, time = os.date('%H:%M') }

    -- sync -> proprietar (daca online) + toti staff-ii
    local owner = resolveTicketPlayer(t)
    if owner and owner ~= src then pushTo(owner, 'message', msg) end
    for _, st in ipairs(onlineStaff(Config.StaffOpenRank)) do
        if st ~= src then pushTo(st, 'message', msg) end
    end
    return true, { message = msg }
end

-- gradul (Staff.level) al unui license, chiar daca e offline (citit din users.staff)
local function staffLevelOfLicense(license)
    if not license or license == '' then return 0 end
    for _, pid in ipairs(GetPlayers()) do
        local t = tonumber(pid)
        if licenseOf(t) == license then
            local ok, lv = pcall(function() return exports['rpg-auth']:getStaffLevel(t) end)
            if ok and lv then return lv end
        end
    end
    local slug = MySQL.scalar.await('SELECT staff FROM users WHERE identifier = ? LIMIT 1', { license })
    return Staff.level(slug or '')
end

-- ---- HAINE STAFF: da itemul potrivit gradului in inventar --------------
local PIECE_LABEL = { mask = 'Mască', tshirt = 'Tricou', hoodie = 'Hanorac' }

-- garderoba pentru un slug de grad; daca lipseste, coboara la cel mai apropiat
-- grad INFERIOR care are o intrare in Config.StaffWardrobe.
local function wardrobeFor(slug)
    local set = Config.StaffWardrobe[slug or '']
    if set then return set end
    local myLvl = Staff.level(slug or '')
    local bestLvl, best = -1, nil
    for rankSlug, s in pairs(Config.StaffWardrobe) do
        local lvl = Staff.level(rankSlug)
        if lvl <= myLvl and lvl > bestLvl then bestLvl, best = lvl, s end
    end
    return best
end

function Actions.giveWardrobe(src, data)
    if not hasRank(src, Config.StaffOpenRank) then return false, { error = 'Fara permisiune.' } end

    local piece = tostring(data and data.piece or '')
    if not PIECE_LABEL[piece] then return false, { error = 'Piesa necunoscuta.' } end

    local slug = ''
    pcall(function() slug = exports['rpg-auth']:getStaff(src) or '' end)
    local set = wardrobeFor(slug)
    local itemId = set and set[piece]
    if not itemId then return false, { error = 'Gradul tau nu are haine definite.' } end

    local ch
    pcall(function() ch = exports['rpg-characters']:getCharacter(src) end)
    if not ch or not ch.id then return false, { error = 'Personaj neincarcat.' } end

    local added = false
    pcall(function() added = exports['rpg-inventory']:Add(ch.id, itemId, 1) end)
    if not added then return false, { error = 'Inventar plin sau item invalid.' } end

    notify(src, 'SUCCESS', ('%s staff adăugat în inventar. Echipează din inventar (I).'):format(PIECE_LABEL[piece]))
    if DBG then print(('[rpg-tickets] giveWardrobe: src %s (grad %s) -> %s'):format(src, slug, itemId)) end
    return true, { item = itemId, piece = piece }
end

function Actions.closeTicket(src, data)
    local id = tonumber(data and data.ticketId)
    if not id then return false, { error = 'ID lipsa.' } end
    local t = getTicket(id)
    if not t then return false, { error = 'Ticket inexistent.' } end
    if t.status == 'closed' then return false, { error = 'Deja inchis.' } end

    local me = identity(src)
    local isOwner = t.player_identifier == me.license
    local isStaff = hasRank(src, Config.StaffClaimRank)
    if not isOwner and not isStaff then return false, { error = 'Fara permisiune.' } end

    MySQL.update.await("UPDATE tickets SET status = 'closed', closed_at = NOW() WHERE id = ?", { id })

    -- rating (1..5) lasat de proprietar la inchidere
    local rating = tonumber(data and data.rating)
    if rating and rating >= 1 and rating <= 5 then
        MySQL.update.await('UPDATE tickets SET rating = ? WHERE id = ?', { math.floor(rating), id })
    end

    -- staff-ul creditat = cel care a preluat (claimed_by); daca nimeni si closer-ul e staff -> el
    local creditLicense = (t.claimed_by ~= nil and t.claimed_by ~= '') and t.claimed_by or nil
    local creditName    = t.staff_name
    if not creditLicense and isStaff then
        creditLicense, creditName = me.license, me.name
    end

    if creditLicense then
        local level = staffLevelOfLicense(creditLicense)
        local row   = ensureStaffRow(creditLicense, creditName)
        if row then
            local prevMonthly = tonumber(row.tickets_closed_monthly) or 0
            local newTotal    = (tonumber(row.tickets_closed_total) or 0) + 1
            local newMonthly  = prevMonthly + 1
            local newAccrued  = (tonumber(row.money_accrued) or 0) + payoutFor(level)

            -- FPT: 1 la fiecare N tichete inchise (lunar) + bonus la pragul lunar
            local per    = math.max(1, Config.Rewards.fptPerTickets)
            local newFpt = (tonumber(row.fpt) or 0)
                         + (math.floor(newMonthly / per) - math.floor(prevMonthly / per))
            if prevMonthly < Config.Rewards.milestone and newMonthly >= Config.Rewards.milestone then
                newFpt = newFpt + milestoneFptFor(level)
            end

            -- timp mediu de preluare (rulant) — diff exact calculat de MySQL
            local avg = tonumber(row.avg_response_seconds) or 0
            if t.claimed_at then
                local diff = tonumber(MySQL.scalar.await(
                    'SELECT TIMESTAMPDIFF(SECOND, created_at, claimed_at) FROM tickets WHERE id = ?', { id })) or 0
                local n = math.max(0, newTotal - 1)
                avg = math.floor((avg * n + diff) / (n + 1))
            end

            MySQL.update.await([[
                UPDATE staff_stats
                SET tickets_closed_total = ?, tickets_closed_monthly = ?,
                    money_accrued = ?, fpt = ?, avg_response_seconds = ?
                WHERE identifier = ?
            ]], { newTotal, newMonthly, newAccrued, newFpt, avg, creditLicense })
        end
    end

    local shaped = shapeTicket(getTicket(id))
    pushStaff('ticketClosed', { ticket = shaped })
    local owner = resolveTicketPlayer(t)
    if owner then
        pushTo(owner, 'ticketClosed', { ticket = shaped })
        if not isOwner then notify(owner, 'INFO', ('Ticketul tau #%d a fost inchis de staff.'):format(id)) end
    end
    -- staff-ul creditat, daca e online, primeste STATS + REWARDS la zi
    if creditLicense then
        for _, st in ipairs(onlineStaff(Config.StaffOpenRank)) do
            if licenseOf(st) == creditLicense then
                local sd = identity(st)
                pushTo(st, 'stats', buildStats(sd.license, sd.name, sd.staffLevel))
            end
        end
    end
    notify(src, 'SUCCESS', ('Ticket #%d inchis.'):format(id))
    return true, { ticket = shaped }
end

function Actions.fetchStats(src)
    if not hasRank(src, Config.StaffOpenRank) then return false, { error = 'Fara permisiune.' } end
    local me = identity(src)
    return true, buildStats(me.license, me.name, me.staffLevel)
end

function Actions.fetchRewards(src)
    if not hasRank(src, Config.StaffOpenRank) then return false, { error = 'Fara permisiune.' } end
    local me = identity(src)
    local row = ensureStaffRow(me.license, me.name)
    return true, { rewards = shapeRewards(row or {}, me.staffLevel) }
end

function Actions.claimRewards(src)
    if not hasRank(src, Config.StaffOpenRank) then return false, { error = 'Fara permisiune.' } end
    local me = identity(src)
    local row = ensureStaffRow(me.license, me.name)
    if not row then return false, { error = 'Fara date.' } end

    local accrued   = tonumber(row.money_accrued) or 0
    local claimed   = tonumber(row.money_claimed) or 0
    local claimable = math.max(0, accrued - claimed)
    if claimable < Config.Rewards.minClaim then
        return false, { error = 'Nimic de revendicat.' }
    end

    local ok = false
    if Config.Rewards.claimToBank then
        local pok, done = pcall(function() return exports['rpg-level']:addBank(src, claimable) end)
        ok = pok and done == true
    end
    if not ok then return false, { error = 'Nu am putut vira banii (esti logat in rpg-level?).' } end

    MySQL.update.await('UPDATE staff_stats SET money_claimed = money_claimed + ? WHERE identifier = ?',
        { claimable, me.license })

    notify(src, 'SUCCESS', ('Ai revendicat $%s in banca.'):format(claimable))
    local newRow = ensureStaffRow(me.license, me.name)
    return true, { rewards = shapeRewards(newRow or {}, me.staffLevel), claimed = claimable }
end

-- --- TP / BRING ---
local function doTeleport(src, data, bring)
    if not hasRank(src, Config.StaffTeleportRank) then return false, { error = 'Fara permisiune.' } end
    local id = tonumber(data and data.ticketId)
    local target
    if id then
        target = resolveTicketPlayer(getTicket(id))
    elseif data and data.serverId then
        target = tonumber(data.serverId)
    end
    if not target or not GetPlayerName(target) then
        return false, { error = 'Jucatorul nu este online.' }
    end
    if bring then
        TriggerClientEvent('rpg-tickets:bringTo', target, src)
        notify(src, 'INFO', ('Ai adus jucatorul %s.'):format(GetPlayerName(target)))
    else
        TriggerClientEvent('rpg-tickets:tpTo', src, target)
        notify(src, 'INFO', ('Te-ai teleportat la %s.'):format(GetPlayerName(target)))
    end
    return true, {}
end

function Actions.tpToPlayer(src, data) return doTeleport(src, data, false) end
function Actions.bringPlayer(src, data) return doTeleport(src, data, true) end

-- ---------------------------------------------------------------------------
--  ROUTER
-- ---------------------------------------------------------------------------
RegisterNetEvent('rpg-tickets:request', function(reqId, name, data)
    local src = source
    if type(reqId) ~= 'number' or type(name) ~= 'string' then return end
    local fn = Actions[name]
    if not fn then return reply(src, reqId, false, { error = 'Actiune necunoscuta.' }) end

    -- actiunile intorc (okBool, payloadTable)
    local pok, aok, payload = pcall(fn, src, data)
    if not pok then
        print(('[rpg-tickets] EROARE in actiunea %s: %s'):format(name, tostring(aok)))
        return reply(src, reqId, false, { error = 'Eroare interna.' })
    end
    reply(src, reqId, aok == true, (type(payload) == 'table') and payload or {})
end)

-- ---------------------------------------------------------------------------
--  COMENZI  /tpto  /bring   (si din consola / F8 cu ACE)
-- ---------------------------------------------------------------------------
RegisterCommand(Config.Commands.tpTo, function(src, args)
    if src <= 0 then return end
    if not hasRank(src, Config.StaffTeleportRank) then
        return notify(src, 'ERROR', 'Fara permisiune.')
    end
    local n = tonumber(args[1])
    if not n then return notify(src, 'ERROR', ('Folosire: /%s [ticketId | serverId]'):format(Config.Commands.tpTo)) end
    -- incearca intai ca ticketId, apoi ca serverId
    local t = getTicket(n)
    doTeleport(src, t and { ticketId = n } or { serverId = n }, false)
end, false)

RegisterCommand(Config.Commands.bring, function(src, args)
    if src <= 0 then return end
    if not hasRank(src, Config.StaffTeleportRank) then
        return notify(src, 'ERROR', 'Fara permisiune.')
    end
    local n = tonumber(args[1])
    if not n then return notify(src, 'ERROR', ('Folosire: /%s [ticketId | serverId]'):format(Config.Commands.bring)) end
    local t = getTicket(n)
    doTeleport(src, t and { ticketId = n } or { serverId = n }, true)
end, false)

-- ---------------------------------------------------------------------------
--  cleanup
-- ---------------------------------------------------------------------------
AddEventHandler('playerDropped', function()
    lastMsgAt[source] = nil
end)

-- ---------------------------------------------------------------------------
--  EXPORTS (pt. alte resurse)
-- ---------------------------------------------------------------------------
exports('createTicketFor', function(src, category, reason)
    local ok, res = Actions.createTicket(src, { category = category, reason = reason })
    return ok, res
end)
exports('getOpenTicketCount', function()
    return tonumber(MySQL.scalar.await("SELECT COUNT(*) FROM tickets WHERE status IN ('active','claimed')")) or 0
end)
