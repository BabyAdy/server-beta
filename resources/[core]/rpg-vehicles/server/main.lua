-- ===========================================================================
--  rpg-vehicles — server
--  Autoritate: tabela personal_vehicles, spawn/despawn, /park, /v, /vcreate,
--  /vdelete. Tuning-ul se salveaza la ORICE despawn (actiune, /dv, crash,
--  disconnect, restart) prin: sync periodic client -> cache -> DB la despawn.
-- ===========================================================================

local DBG = true

local pvCache = {}   -- [id] = { id, owner, model, plate, park = {x,y,z,h}|nil, mods = json|nil, locked = bool, created_by }
local spawned = {}   -- [id] = { entity, netId, ownerSrc, lastMods = json|nil }

-- ---- helperi ---------------------------------------------------------------
local function accOf(src)
    local ok, a = pcall(function() return exports['rpg-auth']:getAccount(src) end)
    return (ok and a) and a or nil
end
local function accId(src)
    local a = accOf(src)
    return a and a.id or nil
end

local function feedback(src, channel, text)
    local ok = pcall(function()
        exports['rpg-hud']:addChatMessage(src, { channel = channel, text = text })
    end)
    if not ok then
        TriggerClientEvent('chat:addMessage', src, { color = { 130, 200, 255 }, args = { 'VEHICLE', text } })
    end
end

local function canManage(src)
    if src <= 0 then return true end
    local ok, allowed = pcall(function() return exports['rpg-auth']:hasStaffLevel(src, Config.ManageRank) end)
    return ok and allowed == true
end

local function cmdIssuer(src)
    if src <= 0 then return 'Consolă', 'Consolă' end
    local name = GetPlayerName(src) or ('src' .. src)
    local a = accOf(src)
    if a and a.username then name = a.username end
    local label = 'Staff'
    local okl, l = pcall(function() return exports['rpg-auth']:getStaffLabel(src) end)
    if okl and l and l ~= '' then label = l end
    return name, label
end

local function staffBroadcast(text)
    for _, pid in ipairs(GetPlayers()) do
        local t = tonumber(pid)
        local ok, allowed = pcall(function() return exports['rpg-auth']:hasStaffLevel(t, Config.BroadcastRank) end)
        if ok and allowed == true then
            TriggerClientEvent('rpg-hud:chatMessage', t, { text = text, color = Staff.BROADCAST_COLOR, time = os.date('%H:%M') })
        end
    end
    print(('[rpg-vehicles][staff] %s'):format(text))
end

local function genPlate()
    local chars, out = Config.PlateChars, {}
    for i = 1, (Config.PlateLen or 8) do
        local n = math.random(1, #chars)
        out[i] = chars:sub(n, n)
    end
    return table.concat(out)
end

local function uniquePlate()
    for _ = 1, 20 do
        local p = genPlate()
        if not MySQL.scalar.await('SELECT 1 FROM personal_vehicles WHERE plate = ? LIMIT 1', { p }) then
            return p
        end
    end
    return genPlate() .. tostring(math.random(10, 99))
end

-- ---- schema --------------------------------------------------------------
local function ensureSchema()
    local sql = LoadResourceFile(GetCurrentResourceName(), 'sql/schema.sql')
    if sql then
        for stmt in (sql .. '\n'):gmatch('(.-);%s*\n') do
            local s = stmt:gsub('%-%-[^\n]*', ''):gsub('^%s+', ''):gsub('%s+$', '')
            if s ~= '' then MySQL.query.await(s) end
        end
    end

    -- migratie: coloana odometer pe tabele deja existente (fara pierdere de date)
    local hasOdo = MySQL.scalar.await([[
        SELECT COUNT(*) FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'personal_vehicles' AND COLUMN_NAME = 'odometer'
    ]])
    if (tonumber(hasOdo) or 0) == 0 then
        MySQL.query.await("ALTER TABLE `personal_vehicles` ADD COLUMN `odometer` FLOAT NOT NULL DEFAULT 0 AFTER `mods`")
        print('[rpg-vehicles] Coloana personal_vehicles.odometer adaugata.')
    end

    if DBG then print('[rpg-vehicles] schema OK') end
end

-- numarul de zile intregi de la un TIMESTAMP MySQL.
-- oxmysql poate returna coloana ca string ('YYYY-MM-DD HH:MM:SS') sau ca numar (ms/secunde).
local function daysSince(ts)
    if type(ts) == 'number' then
        local sec = ts > 1e12 and ts / 1000 or ts   -- ms -> s
        local diff = os.difftime(os.time(), sec)
        return diff > 0 and math.floor(diff / 86400) or 0
    end
    if type(ts) ~= 'string' then return 0 end
    local y, mo, d, h, mi, s = ts:match('(%d+)-(%d+)-(%d+)[ T](%d+):(%d+):(%d+)')
    if not y then
        y, mo, d = ts:match('(%d+)-(%d+)-(%d+)')
        h, mi, s = 0, 0, 0
    end
    if not y then return 0 end
    local t = os.time({
        year = tonumber(y), month = tonumber(mo), day = tonumber(d),
        hour = tonumber(h) or 0, min = tonumber(mi) or 0, sec = tonumber(s) or 0,
    })
    if not t then return 0 end
    local diff = os.difftime(os.time(), t)
    if diff < 0 then diff = 0 end
    return math.floor(diff / 86400)
end

CreateThread(function()
    while GetResourceState('oxmysql') ~= 'started' do Wait(200) end
    Wait(400)
    ensureSchema()
end)

-- ---- cache per proprietar --------------------------------------------------
local function rowToPv(r)
    local park
    if r.park_x ~= nil then
        park = { x = r.park_x + 0.0, y = r.park_y + 0.0, z = r.park_z + 0.0, h = (r.park_h or 0.0) + 0.0 }
    end
    return {
        id = r.id, owner = tonumber(r.owner), model = r.model, plate = r.plate,
        park = park, mods = r.mods, locked = (tonumber(r.locked) or 1) == 1, created_by = r.created_by,
        odometer = tonumber(r.odometer) or 0.0, created_at = r.created_at,
    }
end

local function loadOwner(accountId)
    if not accountId then return end
    local rows = MySQL.query.await('SELECT * FROM personal_vehicles WHERE owner = ?', { accountId }) or {}
    for _, r in ipairs(rows) do pvCache[r.id] = rowToPv(r) end
end

local function ownedList(accountId)
    local out = {}
    for _, pv in pairs(pvCache) do
        if pv.owner == accountId then
            out[#out + 1] = {
                id = pv.id, model = pv.model, plate = pv.plate,
                spawned = spawned[pv.id] ~= nil,
                locked = pv.locked and true or false,
                hasPark = pv.park ~= nil,
                odometer = math.floor(pv.odometer or 0),
                days = daysSince(pv.created_at),
            }
        end
    end
    table.sort(out, function(a, b) return a.id < b.id end)
    return out
end

local function pushMenu(src)
    TriggerClientEvent('rpg-vehicles:openMenu', src, ownedList(accId(src)))
end
local function pushRefresh(src)
    TriggerClientEvent('rpg-vehicles:refresh', src, ownedList(accId(src)))
end

-- ---- salvarea tuning-ului -----------------------------------------------
local function flushMods(id)
    local sp = spawned[id]
    local pv = pvCache[id]
    if not pv then return end

    local newMods = sp and sp.lastMods or nil
    local modsChanged = newMods ~= nil and newMods ~= pv.mods
    local odoChanged  = pv._odoDirty == true
    if not modsChanged and not odoChanged then return end   -- nimic nou

    if modsChanged then pv.mods = newMods end
    pv._odoDirty = nil

    MySQL.update.await('UPDATE personal_vehicles SET mods = ?, odometer = ? WHERE id = ?',
        { pv.mods, pv.odometer or 0, id })
    if DBG then print(('[rpg-vehicles] salvat (tuning/km=%.2f) pt. vehicul #%d'):format(pv.odometer or 0, id)) end
end

local function despawnVehicle(id, saveMods)
    local sp = spawned[id]
    if not sp then return end
    if saveMods ~= false then flushMods(id) end
    if sp.ownerSrc and GetPlayerName(sp.ownerSrc) then
        TriggerClientEvent('rpg-vehicles:untrack', sp.ownerSrc, id)
    end
    if sp.entity and DoesEntityExist(sp.entity) then DeleteEntity(sp.entity) end
    spawned[id] = nil
end

-- ---- spawn -------------------------------------------------------------
local function spawnVehicle(src, id, atCoords, atHeading)
    local pv = pvCache[id]
    if not pv then return false, 'Vehicul inexistent.' end
    if spawned[id] then return false, 'Vehiculul e deja spawnat.' end

    if (Config.MaxSpawnPerPlayer or 0) > 0 then
        local n = 0
        for sid, sp in pairs(spawned) do
            if pvCache[sid] and pvCache[sid].owner == pv.owner then n = n + 1 end
        end
        if n >= Config.MaxSpawnPerPlayer then
            return false, ('Ai deja %d vehicule personale spawnate.'):format(Config.MaxSpawnPerPlayer)
        end
    end

    local cx, cy, cz, ch
    if atCoords then
        cx, cy, cz, ch = atCoords.x, atCoords.y, atCoords.z, atHeading or 0.0
    elseif pv.park then
        cx, cy, cz, ch = pv.park.x, pv.park.y, pv.park.z, pv.park.h or 0.0
    else
        return false, 'Vehiculul nu are o locație de parcare setată (folosește /park o dată).'
    end

    local veh = CreateVehicleServerSetter(GetHashKey(pv.model), 'automobile', cx, cy, cz, ch)
    if not veh or veh == 0 then return false, ('Model invalid: %s'):format(pv.model) end

    SetVehicleNumberPlateText(veh, pv.plate)
    SetVehicleOnGroundProperly(veh)
    SetVehicleDoorsLocked(veh, pv.locked and 2 or 1)

    local st = Entity(veh).state
    st:set('pvId', id, true)
    st:set('pvOwner', pv.owner, true)
    st:set('pvLocked', pv.locked and true or false, true)

    local netId = NetworkGetNetworkIdFromEntity(veh)
    spawned[id] = { entity = veh, netId = netId, ownerSrc = src, lastMods = pv.mods }

    -- clientul aplica tuning-ul salvat + porneste sync-ul periodic de tuning
    TriggerClientEvent('rpg-vehicles:applyMods', src, netId, pv.mods)
    TriggerClientEvent('rpg-vehicles:track', src, id, netId, {
        odometer = pv.odometer or 0,
        days     = daysSince(pv.created_at),
        locked   = pv.locked and true or false,
    })
    return true
end

-- ===========================================================================
--  /v  -> meniu NUI
-- ===========================================================================
RegisterNetEvent('rpg-vehicles:menu', function()
    local src = source
    if not accId(src) then return end
    pushMenu(src)
end)

RegisterNetEvent('rpg-vehicles:action', function(act, id)
    local src = source
    id = tonumber(id)
    local pv = pvCache[id]
    if not pv or pv.owner ~= accId(src) then
        return feedback(src, 'ERROR', 'Nu e vehiculul tău.')
    end

    if act == 'spawn' then
        local ok, why = spawnVehicle(src, id)
        if not ok then feedback(src, 'ERROR', why) end

    elseif act == 'despawn' then
        if not spawned[id] then return feedback(src, 'ERROR', 'Vehiculul nu e spawnat.') end
        despawnVehicle(id, true)
        feedback(src, 'SUCCESS', 'Vehicul despawnat (tuning salvat).')

    elseif act == 'unstuck' then
        despawnVehicle(id, true)   -- salveaza + sterge instanta veche daca exista
        local ped = GetPlayerPed(src)
        local c = GetEntityCoords(ped)
        local h = GetEntityHeading(ped)
        local rad = math.rad(h)
        local fx, fy = -math.sin(rad), math.cos(rad)
        local dest = vector3(c.x + fx * (Config.SpawnOffset or 4.0), c.y + fy * (Config.SpawnOffset or 4.0), c.z)
        local ok, why = spawnVehicle(src, id, dest, h)
        if not ok then feedback(src, 'ERROR', why) else feedback(src, 'SUCCESS', 'Vehiculul a fost adus lângă tine.') end

    elseif act == 'locate' then
        local sp = spawned[id]
        if not sp or not sp.entity or not DoesEntityExist(sp.entity) then
            return feedback(src, 'ERROR', 'Vehiculul nu e spawnat.')
        end
        local c = GetEntityCoords(sp.entity)
        TriggerClientEvent('rpg-vehicles:locate', src, c.x, c.y)
        feedback(src, 'INFO', 'Waypoint setat spre vehicul.')

    elseif act == 'lock' then
        pv.locked = not pv.locked
        MySQL.update.await('UPDATE personal_vehicles SET locked = ? WHERE id = ?', { pv.locked and 1 or 0, id })
        local sp = spawned[id]
        if sp and sp.entity and DoesEntityExist(sp.entity) then
            Entity(sp.entity).state:set('pvLocked', pv.locked and true or false, true)
        end
        feedback(src, 'SUCCESS', pv.locked and 'Vehicul încuiat.' or 'Vehicul descuiat.')
    end

    pushRefresh(src)
end)

-- clientul trimite periodic tuning-ul + delta de kilometraj (si la iesirea din masina)
RegisterNetEvent('rpg-vehicles:syncMods', function(id, modsJson, odoMeters)
    local src = source
    id = tonumber(id)
    local sp = spawned[id]
    if not sp or sp.ownerSrc ~= src then return end
    if type(modsJson) == 'string' and modsJson ~= '' then
        sp.lastMods = modsJson
    end
    local pv = pvCache[id]
    if pv and type(odoMeters) == 'number' and odoMeters > 0 and odoMeters < 100000 then
        pv.odometer = (pv.odometer or 0) + odoMeters / 1000.0
        pv._odoDirty = true
    end
    flushMods(id)   -- persista tuning + km la fiecare tick de sync
end)

-- ===========================================================================
--  /park  -> salveaza locatia curenta a masinii personale ca punct de spawn
-- ===========================================================================
RegisterCommand('park', function(src)
    if src <= 0 then return end
    local acc = accId(src)
    if not acc then return end

    if GetPlayerRoutingBucket(src) ~= 0 then
        return feedback(src, 'ERROR', 'Nu poți parca într-un virtual world diferit de 0.')
    end

    local ped = GetPlayerPed(src)
    local veh = GetVehiclePedIsIn(ped, false)
    if not veh or veh == 0 then
        return feedback(src, 'ERROR', 'Trebuie să fii în mașina ta personală.')
    end

    local id = Entity(veh).state.pvId
    local pv = id and pvCache[id]
    if not pv or pv.owner ~= acc then
        return feedback(src, 'ERROR', 'Aceasta nu e o mașină personală de-a ta.')
    end

    local c = GetEntityCoords(veh)
    local h = GetEntityHeading(veh)
    pv.park = { x = c.x, y = c.y, z = c.z, h = h }
    MySQL.update.await(
        'UPDATE personal_vehicles SET park_x = ?, park_y = ?, park_z = ?, park_h = ? WHERE id = ?',
        { c.x, c.y, c.z, h, id })

    feedback(src, 'SUCCESS', ('Mașina #%d a fost parcată aici. [Spawn] o va aduce în acest loc.'):format(id))
end, false)

-- ===========================================================================
--  /vcreate [sql id] [model]   — staff >= Config.ManageRank
-- ===========================================================================
RegisterCommand('vcreate', function(src, args)
    if not canManage(src) then return feedback(src, 'ERROR', 'Nu ai acces la această comandă.') end

    local charId = tonumber(args[1])
    local model  = tostring(args[2] or ''):lower()
    if not charId or model == '' then
        return feedback(src, 'ERROR', 'Folosire: /vcreate [sql id] [model name]')
    end

    local target = exports['rpg-characters']:resolveCharacter(charId)
    if not target then return feedback(src, 'ERROR', 'SQL id inexistent.') end

    local plate = uniquePlate()
    -- locatie initiala de parcare = pozitia staff-ului (owner-ul o poate re-seta cu /park)
    local px, py, pz, ph = 0.0, 0.0, 0.0, 0.0
    if src > 0 then
        local c = GetEntityCoords(GetPlayerPed(src))
        px, py, pz, ph = c.x, c.y, c.z, GetEntityHeading(GetPlayerPed(src))
    end

    local id = MySQL.insert.await([[
        INSERT INTO personal_vehicles (owner, model, plate, park_x, park_y, park_z, park_h, created_by)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], { target.accountId, model, plate, px, py, pz, ph, accId(src) })
    if not id then return feedback(src, 'ERROR', 'Eroare la salvare.') end

    -- daca proprietarul e online, baga-l in cache-ul lui
    local row = MySQL.single.await('SELECT * FROM personal_vehicles WHERE id = ? LIMIT 1', { id })
    if row then pvCache[id] = rowToPv(row) end
    if target.src then pushRefresh(target.src) end

    local giverName, giverLabel = cmdIssuer(src)
    feedback(src, 'SUCCESS', ('Vehicul %s creat pentru %s (#%s), plăcuța %s, id #%d.')
        :format(model, target.username or '?', charId, plate, id))
    if target.src then
        feedback(target.src, 'INFO', ('Ai primit un vehicul personal: %s (plăcuța %s). Deschide /v.'):format(model, plate))
    end
    staffBroadcast(('Staff: %s %s created vehicle %s for %s[%s].')
        :format(giverLabel, giverName, model, target.username or '?', charId))
end, false)

-- ===========================================================================
--  /vdelete [sql id] [personal_vehicles.id]   — staff >= Config.ManageRank
-- ===========================================================================
RegisterCommand('vdelete', function(src, args)
    if not canManage(src) then return feedback(src, 'ERROR', 'Nu ai acces la această comandă.') end

    local charId = tonumber(args[1])
    local pvId   = tonumber(args[2])
    if not charId or not pvId then
        return feedback(src, 'ERROR', 'Folosire: /vdelete [sql id] [id vehicul]')
    end

    local target = exports['rpg-characters']:resolveCharacter(charId)
    if not target then return feedback(src, 'ERROR', 'SQL id inexistent.') end

    local row = MySQL.single.await('SELECT * FROM personal_vehicles WHERE id = ? LIMIT 1', { pvId })
    if not row then return feedback(src, 'ERROR', ('Vehiculul #%d nu există.'):format(pvId)) end
    if tonumber(row.owner) ~= target.accountId then
        return feedback(src, 'ERROR', 'Vehiculul nu aparține acelui SQL id.')
    end

    despawnVehicle(pvId, false)   -- se sterge oricum, nu mai salvam tuning
    MySQL.update.await('DELETE FROM personal_vehicles WHERE id = ?', { pvId })
    pvCache[pvId] = nil
    if target.src then pushRefresh(target.src) end

    local giverName, giverLabel = cmdIssuer(src)
    feedback(src, 'SUCCESS', ('Vehicul %s #%d șters pentru %s (#%s).'):format(row.model, pvId, target.username or '?', charId))
    staffBroadcast(('Staff: %s %s deleted vehicle %s #%d for %s[%s].')
        :format(giverLabel, giverName, row.model, pvId, target.username or '?', charId))
end, false)

-- ===========================================================================
--  ciclu de viata
-- ===========================================================================
AddEventHandler('core:characterLoaded', function(src)
    local acc = accId(src)
    if acc then loadOwner(acc) end
end)

AddEventHandler('playerDropped', function()
    local src = source
    local acc = accId(src)
    for id, sp in pairs(spawned) do
        if sp.ownerSrc == src then despawnVehicle(id, true) end
    end
    if acc then
        for id, pv in pairs(pvCache) do
            if pv.owner == acc and not spawned[id] then pvCache[id] = nil end
        end
    end
end)

-- watchdog: prinde despawn-urile externe (/dv din vMenu, crash) -> salveaza tuning
CreateThread(function()
    while true do
        Wait(Config.WatchdogInterval or 5000)
        for id, sp in pairs(spawned) do
            if not sp.entity or not DoesEntityExist(sp.entity) then
                if DBG then print(('[rpg-vehicles] vehicul #%d disparut extern -> salvez tuning'):format(id)) end
                flushMods(id)
                if sp.ownerSrc and GetPlayerName(sp.ownerSrc) then
                    TriggerClientEvent('rpg-vehicles:untrack', sp.ownerSrc, id)
                    pushRefresh(sp.ownerSrc)
                end
                spawned[id] = nil
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for id in pairs(spawned) do despawnVehicle(id, true) end
end)
