-- ===========================================================================
--  rpg-garages — server / core
--  Schema, cache, helperi partajati, ciclu de viata, autosave, exports.
--  Vehicule personale (cars/moto/heli/plane/boat) + garage-uri + dealership.
--
--  Integrare cu framework-ul existent:
--    rpg-auth       -> cont (users.id/username), permisiuni staff (hasStaffLevel)
--    rpg-level      -> economie (getBank/getMoney/addBank/addMoney)
--    rpg-hud        -> notificari in chat (addChatMessage), broadcast staff
--    rpg-characters -> (nefolosit direct; owner e la nivel de CONT, users.id)
-- ===========================================================================

Garages = Garages or {}

Garages.ready     = false
Garages.garages   = {}   -- [garageId] = { id, type, x, y, z, h }
Garages.spawned   = {}   -- [pvId]     = { ownerSrc, ownerId, netId, model, since, pending }
Garages.netIdToPv = {}   -- [netId]    = pvId  (autoritate server-side, nu depinde de statebag)

local DBG = Config.Debug

math.randomseed(os.time() + GetGameTimer())   -- placi random distincte dupa restart

-- ---------------------------------------------------------------------------
--  HELPERI
-- ---------------------------------------------------------------------------
function Garages.accOf(src)
    local ok, a = pcall(function() return exports['rpg-auth']:getAccount(src) end)
    return (ok and a) and a or nil
end

function Garages.accId(src)
    local a = Garages.accOf(src)
    return a and tonumber(a.id) or nil
end

-- users.id online -> src (nil daca offline)
function Garages.srcOfAccount(uid)
    uid = tonumber(uid)
    if not uid then return nil end
    for _, pid in ipairs(GetPlayers()) do
        local t = tonumber(pid)
        local a = Garages.accOf(t)
        if a and tonumber(a.id) == uid then return t end
    end
    return nil
end

-- username din users (functioneaza si offline)
function Garages.usernameOf(uid)
    uid = tonumber(uid); if not uid then return nil end
    local src = Garages.srcOfAccount(uid)
    if src then
        local a = Garages.accOf(src)
        if a and a.username then return a.username end
    end
    return MySQL.scalar.await('SELECT username FROM users WHERE id = ? LIMIT 1', { uid })
end

function Garages.canStaff(src)
    if src <= 0 then return true end
    local ok, allowed = pcall(function() return exports['rpg-auth']:hasStaffLevel(src, Config.StaffRank) end)
    return ok and allowed == true
end

function Garages.cmdIssuer(src)
    if src <= 0 then return 'Consolă', 'Consolă' end
    local a = Garages.accOf(src)
    local name = (a and a.username) or GetPlayerName(src) or ('src' .. src)
    local label = 'Staff'
    local okl, l = pcall(function() return exports['rpg-auth']:getStaffLabel(src) end)
    if okl and l and l ~= '' then label = l end
    return name, label
end

-- notificare in chat-ul existent (rpg-hud). kind: SUCCESS | ERROR | INFO | STAFF
function Garages.feedback(src, kind, text)
    if not src or src <= 0 then
        if DBG then print(('[rpg-garages] %s: %s'):format(kind or 'INFO', text)) end
        return
    end
    local ok = pcall(function()
        exports['rpg-hud']:addChatMessage(src, { channel = kind, text = text })
    end)
    if not ok then
        TriggerClientEvent('chat:addMessage', src, { color = { 138, 92, 246 }, args = { 'GARAGE', text } })
    end
end

-- mesaj rosu doar pentru staff online >= Config.StaffRank (Staff.BROADCAST_COLOR)
function Garages.staffBroadcast(text)
    local color = (Staff and Staff.BROADCAST_COLOR) or '#ff5555'
    for _, pid in ipairs(GetPlayers()) do
        local t = tonumber(pid)
        local ok, allowed = pcall(function() return exports['rpg-auth']:hasStaffLevel(t, Config.StaffRank) end)
        if ok and allowed == true then
            TriggerClientEvent('rpg-hud:chatMessage', t, { text = text, color = color, time = os.date('%H:%M') })
        end
    end
    print(('[rpg-garages][staff] %s'):format(text))
end

-- anti-abuz: playerul trebuie sa fie langa garage-ul cerut
function Garages.nearGarage(src, garageId)
    local g = Garages.garages[tonumber(garageId or 0)]
    if not g then return false end
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    local c = GetEntityCoords(ped)
    return #(vector3(c.x, c.y, c.z) - vector3(g.x, g.y, g.z)) <= Config.Distance.serverGate, g
end

-- ---------------------------------------------------------------------------
--  SCHEMA
-- ---------------------------------------------------------------------------
local function ensureSchema()
    local sql = LoadResourceFile(GetCurrentResourceName(), 'sql/install.sql')
    if not sql then return print('[rpg-garages] install.sql lipseste!') end
    for stmt in (sql .. '\n'):gmatch('(.-);%s*\n') do
        local s = stmt:gsub('%-%-[^\n]*', ''):gsub('^%s+', ''):gsub('%s+$', '')
        if s ~= '' then MySQL.query.await(s) end
    end
    if DBG then print('[rpg-garages] schema OK') end
end

-- ---------------------------------------------------------------------------
--  RECONCILIERE LA BOOT (spec §8 — niciun vehicul "pierdut" la restart)
--  Orice vehicul marcat scos (stored = 0) cand a picat serverul revine in garage.
-- ---------------------------------------------------------------------------
local function reconcileOnBoot()
    local affected = MySQL.update.await(
        "UPDATE personal_vehicle SET stored = 1 WHERE stored = 0") or 0
    if DBG and affected > 0 then
        print(('[rpg-garages] reconciliere boot: %d vehicule readuse in garage'):format(affected))
    end
end

CreateThread(function()
    while GetResourceState('oxmysql') ~= 'started' do Wait(200) end
    Wait(400)
    ensureSchema()
    reconcileOnBoot()
    Garages.loadGarages()          -- server/garage.lua
    Garages.ready = true
    -- clienti deja conectati (restart de resursa) -> retrimite garage-urile
    for _, pid in ipairs(GetPlayers()) do
        Garages.syncAll(tonumber(pid))
    end
    if DBG then print(('[rpg-garages] gata. %d garage-uri incarcate.'):format(Garages.countGarages())) end
end)

AddEventHandler('core:characterLoaded', function(src)
    if Garages.ready then Garages.syncAll(src) end
end)

RegisterNetEvent('rpg-garages:clientReady', function()
    local src = source
    if Garages.ready then Garages.syncAll(src) end
end)

-- ---------------------------------------------------------------------------
--  CLEANUP la deconectare (spec §8) — vehiculele acestui player revin in garage
-- ---------------------------------------------------------------------------
AddEventHandler('playerDropped', function()
    local src = source
    for pvId, s in pairs(Garages.spawned) do
        if s.ownerSrc == src then
            Garages.forceStore(pvId, s)   -- server/vehicle.lua
        end
    end
end)

-- ---------------------------------------------------------------------------
--  onResourceStop — best effort: readu toate vehiculele spawnate in garage
-- ---------------------------------------------------------------------------
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for pvId, s in pairs(Garages.spawned) do
        MySQL.update.await(
            'UPDATE personal_vehicle SET stored = 1 WHERE id = ?', { pvId })
        if s.netId then
            local ent = NetworkGetEntityFromNetworkId(s.netId)
            if ent and ent ~= 0 and DoesEntityExist(ent) then DeleteEntity(ent) end
        end
    end
end)

-- ---------------------------------------------------------------------------
--  AUTOSAVE PERIODIC (spec §8/§18/§19) — pierdere maxima ~= Config.Odometer.autosaveMs
-- ---------------------------------------------------------------------------
CreateThread(function()
    while true do
        Wait(Config.Odometer.autosaveMs)
        for pvId, s in pairs(Garages.spawned) do
            if not s.pending and s.ownerSrc and GetPlayerName(s.ownerSrc) then
                TriggerClientEvent('rpg-garages:collectState', s.ownerSrc, pvId, false)  -- false = nu despawna
            end
        end
    end
end)

-- ---------------------------------------------------------------------------
--  EXPORTS (pt. viitor: dealership extern, faction system, quests, etc.)
-- ---------------------------------------------------------------------------
exports('createVehicle', function(opts) return Garages.createVehicle(opts) end)
exports('deleteVehicle', function(pvId) return Garages.deleteVehicle(pvId) end)
exports('isVehicleSpawned', function(pvId) return Garages.spawned[tonumber(pvId or 0)] ~= nil end)
exports('getGarages', function() return Garages.garages end)
