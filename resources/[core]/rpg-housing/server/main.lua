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
    if DBG then print('[rpg-housing] schema OK') end
end

local function loadAll()
    local rows = MySQL.query.await('SELECT * FROM houses') or {}
    cache = {}
    for _, r in ipairs(rows) do cache[r.id] = shapeHouse(r) end
    if DBG then print(('[rpg-housing] %d case încărcate.'):format(#rows)) end
end

CreateThread(function()
    while GetResourceState('oxmysql') ~= 'started' do Wait(200) end
    Wait(400)
    ensureSchema()
    loadAll()
end)

-- ===========================================================================
--  SYNC -> client (la login) + broadcast la creare
-- ===========================================================================
local function allHousesList()
    local out = {}
    for _, h in pairs(cache) do out[#out + 1] = h end
    return out
end

AddEventHandler('core:characterLoaded', function(src)
    TriggerClientEvent('rpg-housing:sync', src, allHousesList())
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
