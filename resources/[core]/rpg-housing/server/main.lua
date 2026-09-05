-- ===========================================================================
--  rpg-housing — server
--  Autoritate: creare case (/createhouse, staff), tabela `houses`, rezolvarea
--  numelui proprietarului (owner=0 -> "ADMBOT").
-- ===========================================================================

local DBG = true
local cache = {}   -- [id] = casa "shaped" (vezi shapeHouse)

-- ---- helperi -----------------------------------------------------------
local function accOf(src)
    local ok, a = pcall(function() return exports['rpg-auth']:getAccount(src) end)
    return (ok and a) and a or nil
end

local function feedback(src, channel, text)
    local ok = pcall(function()
        exports['rpg-hud']:addChatMessage(src, { channel = channel, text = text })
    end)
    if not ok then
        TriggerClientEvent('chat:addMessage', src, { color = { 190, 130, 255 }, args = { 'HOUSING', text } })
    end
end

local function canStaffCmd(src, minRank)
    if src <= 0 then return true end
    local ok, allowed = pcall(function() return exports['rpg-auth']:hasStaffLevel(src, minRank) end)
    return ok and allowed == true
end

local function cmdIssuer(src)
    if src <= 0 then return 'Consolă', 'Consolă' end
    local acc = accOf(src)
    local name = (acc and acc.username) or GetPlayerName(src) or ('src' .. src)
    local label = 'Staff'
    local ok, l = pcall(function() return exports['rpg-auth']:getStaffLabel(src) end)
    if ok and l and l ~= '' then label = l end
    return name, label
end

-- mesaj DOAR pt. staff online cu grad >= minRank (mereu roșu — Staff.BROADCAST_COLOR)
local function staffBroadcast(minRank, text)
    for _, pid in ipairs(GetPlayers()) do
        local t = tonumber(pid)
        local ok, allowed = pcall(function() return exports['rpg-auth']:hasStaffLevel(t, minRank) end)
        if ok and allowed == true then
            TriggerClientEvent('rpg-hud:chatMessage', t, { text = text, color = Staff.BROADCAST_COLOR, time = os.date('%H:%M') })
        end
    end
    print(('[rpg-housing][staff] %s'):format(text))
end

local function fmtMoney(n)
    n = math.floor(tonumber(n) or 0)
    local s, out = tostring(n), ''
    for i = 1, #s do
        if i > 1 and (#s - i + 1) % 3 == 0 then out = out .. '.' end
        out = out .. s:sub(i, i)
    end
    return out
end

-- owner=0 -> "ADMBOT" (cerut explicit); altfel numele contului din users.username
local function ownerNameOf(ownerId)
    ownerId = tonumber(ownerId) or 0
    if ownerId == 0 then return 'ADMBOT' end
    local name = MySQL.scalar.await('SELECT username FROM users WHERE id = ? LIMIT 1', { ownerId })
    return name or ('#' .. ownerId)
end

local function shapeHouse(row)
    local def = Config.InteriorTypes[row.interior_type]
    return {
        id            = row.id,
        owner         = tonumber(row.owner) or 0,
        ownerName     = ownerNameOf(row.owner),
        price         = tonumber(row.price) or 0,
        interiorType  = row.interior_type,
        interiorLabel = def and def.label or row.interior_type,
        coords        = vector3(row.x, row.y, row.z),
        heading       = tonumber(row.heading) or 0.0,
        interiorVw    = tonumber(row.interior_vw) or tonumber(row.id) or 0,   -- VW cat timp esti in casa
    }
end

-- ===========================================================================
--  SCHEMA — creare automata la boot
-- ===========================================================================
local function ensureSchema()
    local sql = LoadResourceFile(GetCurrentResourceName(), 'sql/schema.sql')
    if sql then
        for stmt in (sql .. '\n'):gmatch('(.-);%s*\n') do
            local s = stmt:gsub('%-%-[^\n]*', ''):gsub('^%s+', ''):gsub('%s+$', '')
            if s ~= '' then MySQL.query.await(s) end
        end
    end

    -- migratie: coloana interior_vw pe tabele deja existente (fara pierdere de date)
    local hasVw = MySQL.scalar.await([[
        SELECT COUNT(*) FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'houses' AND COLUMN_NAME = 'interior_vw'
    ]])
    if (tonumber(hasVw) or 0) == 0 then
        MySQL.query.await("ALTER TABLE `houses` ADD COLUMN `interior_vw` INT UNSIGNED NOT NULL DEFAULT 0")
        print('[rpg-housing] Coloana houses.interior_vw adaugata.')
    end
    -- fiecare casa care inca are 0 -> interior_vw = id-ul ei
    MySQL.query.await("UPDATE `houses` SET `interior_vw` = `id` WHERE `interior_vw` = 0")

    if DBG then print('[rpg-housing] schema OK') end
end

local function loadAll()
    local rows = MySQL.query.await('SELECT * FROM houses') or {}
    cache = {}
    for _, r in ipairs(rows) do cache[r.id] = shapeHouse(r) end
    if DBG then print(('[rpg-housing] %d case încărcate.'):format(#rows)) end
end

-- ===========================================================================
--  SYNC -> client (la login / la cerere) + broadcast la creare
-- ===========================================================================
local function allHousesList()
    local out = {}
    for _, h in pairs(cache) do out[#out + 1] = h end
    return out
end

CreateThread(function()
    while GetResourceState('oxmysql') ~= 'started' do Wait(200) end
    Wait(400)
    ensureSchema()
    loadAll()
    -- restart de resursa pe server -> re-trimite lista tuturor playerilor conectati
    for _, pid in ipairs(GetPlayers()) do
        TriggerClientEvent('rpg-housing:sync', tonumber(pid), allHousesList())
    end
end)

AddEventHandler('core:characterLoaded', function(src)
    TriggerClientEvent('rpg-housing:sync', src, allHousesList())
end)

-- restart de resursa pe client -> clientul cere lista din nou
RegisterNetEvent('rpg-housing:requestSync', function()
    TriggerClientEvent('rpg-housing:sync', source, allHousesList())
end)

-- ===========================================================================
--  /createhouse [interior_type] [price]  — staff >= Config.MinCreateRank
--  Creeaza intrarea EXACT unde se afla playerul care ruleaza comanda.
-- ===========================================================================
RegisterCommand('createhouse', function(src, args)
    if not canStaffCmd(src, Config.MinCreateRank) then
        return feedback(src, 'ERROR', 'Nu ai acces la această comandă.')
    end
    if src <= 0 then
        return print('[rpg-housing] /createhouse trebuie rulat de un player (are nevoie de poziția lui).')
    end

    local interiorType = tostring(args[1] or ''):lower()
    local price = tonumber(args[2])

    local def = Config.InteriorTypes[interiorType]
    if not def then
        local keys = {}
        for k in pairs(Config.InteriorTypes) do keys[#keys + 1] = k end
        table.sort(keys)
        return feedback(src, 'ERROR',
            ('Tip de interior necunoscut. Valabile: %s'):format(table.concat(keys, ', ')))
    end
    if not price or price < 0 then
        return feedback(src, 'ERROR', 'Folosire: /createhouse [interior_type] [price]')
    end
    price = math.floor(price)

    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local acc = accOf(src)

    local id = MySQL.insert.await([[
        INSERT INTO houses (owner, price, interior_type, x, y, z, heading, created_by)
        VALUES (0, ?, ?, ?, ?, ?, ?, ?)
    ]], { price, interiorType, coords.x, coords.y, coords.z, heading, acc and acc.id or nil })

    if not id then return feedback(src, 'ERROR', 'Eroare la salvare. Încearcă din nou.') end

    -- interior_vw = id-ul propriu al casei (nu se stia inainte de INSERT, e AUTO_INCREMENT)
    MySQL.update.await('UPDATE houses SET interior_vw = ? WHERE id = ?', { id, id })

    local row = MySQL.single.await('SELECT * FROM houses WHERE id = ? LIMIT 1', { id })
    local shaped = shapeHouse(row)
    cache[id] = shaped

    TriggerClientEvent('rpg-housing:houseAdded', -1, shaped)   -- toti clientii -> apare imediat marker + eticheta

    feedback(src, 'SUCCESS',
        ('Casă #%d creată: %s, %s$ (proprietar: ADMBOT).'):format(id, shaped.interiorLabel, fmtMoney(price)))

    local giverName, giverLabel = cmdIssuer(src)
    staffBroadcast(Config.MinBroadcastRank,
        ('Staff: %s %s has created house #%d (%s, %s$) at their location!')
            :format(giverLabel, giverName, id, shaped.interiorLabel, fmtMoney(price)))

    print(('[rpg-housing] /createhouse: %s(#%s) -> casă #%d (%s) @ %.1f,%.1f,%.1f, $%d')
        :format(giverName, src, id, interiorType, coords.x, coords.y, coords.z, price))
end, false)

-- ===========================================================================
--  /howner [sql id] [house id]  — staff >= Config.MinCreateRank
--  Seteaza [sql id] ca proprietar (houses.owner = users.id) al casei [house id].
--  "sql id" = SQL id de PERSONAJ (ca la /setstaff), rezolvat prin rpg-characters.
-- ===========================================================================
RegisterCommand('howner', function(src, args)
    if not canStaffCmd(src, Config.MinCreateRank) then
        return feedback(src, 'ERROR', 'Nu ai acces la această comandă.')
    end

    local charId  = tonumber(args[1])
    local houseId = tonumber(args[2])
    if not charId or not houseId then
        return feedback(src, 'ERROR', 'Folosire: /howner [sql id] [house id]')
    end

    local h = cache[houseId]
    if not h then return feedback(src, 'ERROR', ('Casa #%d nu există.'):format(houseId)) end

    local target = exports['rpg-characters']:resolveCharacter(charId)
    if not target then return feedback(src, 'ERROR', 'SQL id inexistent.') end

    MySQL.update.await('UPDATE houses SET owner = ? WHERE id = ?', { target.accountId, houseId })
    h.owner = target.accountId
    h.ownerName = target.username or ('#' .. target.accountId)
    TriggerClientEvent('rpg-housing:houseAdded', -1, h)   -- reface eticheta la toti clientii

    local giverName, giverLabel = cmdIssuer(src)
    feedback(src, 'SUCCESS', ('%s (#%s) e acum proprietarul casei #%d.'):format(h.ownerName, charId, houseId))
    if target.src then
        feedback(target.src, 'INFO', ('Ai devenit proprietarul casei #%d.'):format(houseId))
    end
    staffBroadcast(Config.MinBroadcastRank,
        ('Staff: %s %s set %s[%s] owner of house #%d.'):format(giverLabel, giverName, h.ownerName, charId, houseId))

    print(('[rpg-housing] /howner: %s(#%s) -> casa #%d owner = cont #%s')
        :format(giverName, src, houseId, target.accountId))
end, false)

-- ===========================================================================
--  INTRARE / IEȘIRE — serverul comuta routing bucket-ul (virtual world).
--  In casa -> VW = house.interior_vw (= id-ul casei) => casele care folosesc
--  acelasi interior MLO fizic NU se vad intre ele. Afara -> VW 0.
--  Teleportul efectiv (SetEntityCoords) il face clientul, dupa confirmare.
-- ===========================================================================
RegisterNetEvent('rpg-housing:enter', function(houseId)
    local src = source
    local h = cache[tonumber(houseId)]
    if not h then return end

    -- anti-abuz usor: trebuie sa fii aproape de usa exterioara
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end
    if #(GetEntityCoords(ped) - h.coords) > (Config.InteractRadius * 4.0) then return end

    SetPlayerRoutingBucket(src, h.interiorVw)
    TriggerClientEvent('rpg-housing:setInside', src, h.id, true)
end)

RegisterNetEvent('rpg-housing:exit', function(houseId)
    local src = source
    local h = cache[tonumber(houseId)]
    SetPlayerRoutingBucket(src, 0)
    TriggerClientEvent('rpg-housing:setInside', src, h and h.id or tonumber(houseId), false)
end)
