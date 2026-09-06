-- ===========================================================================
--  rpg-garages — server / vehicle
--  Creare, listare (per garage), spawn (grant + confirm + fail), park (save
--  fuel/tuning/odometer/status + despawn), lock, delete. TOATA validarea
--  importanta e server-side (spec §7, §8, §15, §16, §21).
-- ===========================================================================

local DBG = Config.Debug

-- ---------------------------------------------------------------------------
--  CREARE (folosita de dealership SI de /vcreate — o singura logica)
--  opts = { ownerId, ownerName?, model, displayName?, type?, faction?,
--           fuel?, status?, garageId? }
-- ---------------------------------------------------------------------------
function Garages.createVehicle(opts)
    opts = opts or {}
    local ownerId = tonumber(opts.ownerId)
    local model   = tostring(opts.model or ''):lower()
    if not ownerId then return nil, 'owner_id lipsa/invalid.' end
    if model == '' then return nil, 'model_name lipsa.' end

    local ownerName = opts.ownerName or Garages.usernameOf(ownerId)
    if not ownerName then return nil, 'users.id inexistent.' end

    local vtype = opts.type
    if not Utils.isValidGarageType(vtype) then vtype = Utils.vehicleTypeForModel(model) end

    local faction = tostring(opts.faction or '')
    local fuel    = Utils.clampNum(opts.fuel, 0.0, 100.0, Config.DefaultFuel)
    local status  = (tonumber(opts.status) == Utils.STATUS_UNLOCKED) and Utils.STATUS_UNLOCKED or Config.DefaultStatus
    local display = opts.displayName
    if not display or display == '' then
        for _, e in ipairs(Config.Catalog) do
            if e.model:lower() == model then display = e.name break end
        end
        display = display or (model:sub(1, 1):upper() .. model:sub(2))
    end

    -- placa unica
    local plate
    for _ = 1, 25 do
        local p = Utils.randomPlate()
        if not MySQL.scalar.await('SELECT 1 FROM personal_vehicle WHERE plate = ? LIMIT 1', { p }) then
            plate = p break
        end
    end
    plate = plate or (Utils.randomPlate():sub(1, 6) .. tostring(math.random(10, 99)))

    local pvId = MySQL.insert.await([[
        INSERT INTO personal_vehicle
            (model_name, display_name, vehicle_type, owner_id, owner_name, faction,
             garage_id, odometer, fuel, status, stored, plate)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?)
    ]], {
        model, display, vtype, ownerId, ownerName, faction,
        opts.garageId and tonumber(opts.garageId) or nil,
        Config.DefaultOdometer, fuel, status, plate
    })
    if not pvId then return nil, 'Eroare la INSERT personal_vehicle.' end

    Tuning.initRow(pvId, ownerId)   -- linia de tuning goala (stock)

    -- daca owner-ul e online, refac lista din orice UI de garage deschis
    local osrc = Garages.srcOfAccount(ownerId)
    if osrc then TriggerClientEvent('rpg-garages:vehiclesChanged', osrc) end

    if DBG then print(('[rpg-garages] createVehicle #%d %s (%s) -> owner %s(#%d)')
        :format(pvId, model, vtype, ownerName, ownerId)) end
    return pvId, { plate = plate, type = vtype, displayName = display }
end

-- ---------------------------------------------------------------------------
--  STERGERE (comanda /vdelete)
-- ---------------------------------------------------------------------------
function Garages.deleteVehicle(pvId)
    pvId = tonumber(pvId)
    if not pvId then return false, 'ID invalid.' end
    local row = MySQL.single.await(
        'SELECT id, model_name, owner_id, owner_name FROM personal_vehicle WHERE id = ? LIMIT 1', { pvId })
    if not row then return false, ('Vehiculul #%d nu exista.'):format(pvId) end

    local s = Garages.spawned[pvId]
    if s then
        if s.ownerSrc and GetPlayerName(s.ownerSrc) then
            TriggerClientEvent('rpg-garages:despawn', s.ownerSrc, pvId)
        end
        if s.netId then
            local ent = NetworkGetEntityFromNetworkId(s.netId)
            if ent and ent ~= 0 and DoesEntityExist(ent) then DeleteEntity(ent) end
            Garages.netIdToPv[s.netId] = nil
        end
        Garages.spawned[pvId] = nil
    end

    -- CASCADE sterge si linia din vehicle_tunning (FK ON DELETE CASCADE);
    -- stergem si explicit ca sa mearga si daca FK-ul lipseste pe un DB vechi.
    MySQL.update.await('DELETE FROM vehicle_tunning WHERE vehicle_id = ?', { pvId })
    MySQL.update.await('DELETE FROM personal_vehicle WHERE id = ?', { pvId })
    return true, row
end

-- vehiculul revine fortat in garage (disconnect / onResourceStop) — fara state client
function Garages.forceStore(pvId, s)
    MySQL.update.await('UPDATE personal_vehicle SET stored = 1 WHERE id = ?', { pvId })
    if s and s.netId then
        local ent = NetworkGetEntityFromNetworkId(s.netId)
        if ent and ent ~= 0 and DoesEntityExist(ent) then DeleteEntity(ent) end
        Garages.netIdToPv[s.netId] = nil
    end
    Garages.spawned[pvId] = nil
end

-- ---------------------------------------------------------------------------
--  LISTARE per garage (spec §2, §14, §16)
-- ---------------------------------------------------------------------------
local TITLES = { Vehicle = 'Vehicles', Heli = 'Helicopters & Planes', Boat = 'Boats' }

local function rowsToList(rows)
    local out = {}
    for _, r in ipairs(rows) do
        local model = r.model_name
        out[#out + 1] = {
            id           = tonumber(r.id),
            model_name   = model,
            display_name = r.display_name,
            odometer     = math.floor(tonumber(r.odometer) or 0),
            fuel         = math.floor(tonumber(r.fuel) or 0),
            status       = Utils.toBit(r.status),   -- oxmysql poate da boolean
            spawned      = Garages.spawned[tonumber(r.id)] ~= nil,
            -- path-ul imaginii se genereaza din model_name; NU e stocat in DB (spec §18)
            image        = tostring(model) .. '.png',
        }
    end
    table.sort(out, function(a, b) return a.id < b.id end)
    return out
end

function Garages.listForGarage(src, garageId)
    local near, g = Garages.nearGarage(src, garageId)
    if not g then return nil, 'Garage inexistent.' end
    if not near then return nil, 'Ești prea departe de garage.' end

    local rows
    if g.faction ~= '' then
        if not Utils.isFactionMember(src, g.faction) then
            return nil, 'Nu ai acces la acest garage de facțiune.'
        end
        rows = MySQL.query.await([[
            SELECT id, model_name, display_name, odometer, fuel, status
            FROM personal_vehicle
            WHERE faction = ? AND vehicle_type = ? AND stored = 1
        ]], { g.faction, g.type }) or {}
    else
        local uid = Garages.accId(src)
        if not uid then return nil, 'Cont neîncărcat.' end
        rows = MySQL.query.await([[
            SELECT id, model_name, display_name, odometer, fuel, status
            FROM personal_vehicle
            WHERE owner_id = ? AND faction = '' AND vehicle_type = ? AND stored = 1
        ]], { uid, g.type }) or {}
    end

    return {
        garageId   = g.id,
        garageType = g.type,
        title      = TITLES[g.type] or 'Vehicles',
        vehicles   = rowsToList(rows),
    }
end

RegisterNetEvent('rpg-garages:requestList', function(garageId)
    local src = source
    local data, err = Garages.listForGarage(src, garageId)
    if not data then return Garages.feedback(src, 'ERROR', err or 'Eroare.') end
    TriggerClientEvent('rpg-garages:showList', src, data)
end)

-- ---------------------------------------------------------------------------
--  SPAWN — grant server-side (spec §7, §15, §16)
-- ---------------------------------------------------------------------------
local function spawnPoint(g)
    local rad = math.rad(g.h or 0.0)
    local fx, fy = -math.sin(rad), math.cos(rad)
    local d = Config.Distance.spawnClear
    return g.x + fx * d, g.y + fy * d, g.z, g.h or 0.0
end

-- respingere spawn: notifica si NUI-ul (buton "SPAWNING..." -> revine) + chat
local function rejectSpawn(src, msg)
    Garages.feedback(src, 'ERROR', msg)
    TriggerClientEvent('rpg-garages:spawnResult', src, false, msg)
end

RegisterNetEvent('rpg-garages:spawnRequest', function(pvId, garageId)
    local src = source
    pvId = tonumber(pvId)
    local near, g = Garages.nearGarage(src, garageId)
    if not pvId or not g then return rejectSpawn(src, 'Cerere invalidă.') end
    if not near then return rejectSpawn(src, 'Ești prea departe de garage.') end

    if Garages.spawned[pvId] then
        return rejectSpawn(src, 'Vehiculul este deja scos.')
    end

    local row = MySQL.single.await('SELECT * FROM personal_vehicle WHERE id = ? LIMIT 1', { pvId })
    if not row then return rejectSpawn(src, 'Vehiculul nu există.') end
    if Utils.toBit(row.stored) ~= 1 then   -- oxmysql poate returna TINYINT(1) ca boolean
        return rejectSpawn(src, 'Vehiculul nu este disponibil.')
    end

    -- ownership + facțiune
    if g.faction ~= '' then
        if row.faction ~= g.faction or not Utils.isFactionMember(src, g.faction) then
            return rejectSpawn(src, 'Vehiculul nu aparține acestei facțiuni / nu ai acces.')
        end
    else
        if row.faction ~= '' or tonumber(row.owner_id) ~= Garages.accId(src) then
            return rejectSpawn(src, 'Nu este vehiculul tău.')
        end
    end

    -- compatibilitate tip garage (spec §16)
    if row.vehicle_type ~= g.type then
        return rejectSpawn(src, ('Acest garage (%s) nu scoate %s.'):format(g.type, row.vehicle_type))
    end

    -- rezerva slotul ACUM (anti double-spawn), marcheaza scos in DB
    Garages.spawned[pvId] = {
        ownerSrc = src, ownerId = tonumber(row.owner_id), model = row.model_name,
        since = os.time(), pending = true, parkGarage = g.id,
    }
    MySQL.update.await('UPDATE personal_vehicle SET stored = 0, garage_id = ? WHERE id = ?', { g.id, pvId })

    local sx, sy, sz, sh = spawnPoint(g)
    TriggerClientEvent('rpg-garages:doSpawn', src, {
        pvId    = pvId,
        model   = row.model_name,
        x = sx, y = sy, z = sz, h = sh,
        tuning  = Tuning.load(pvId),
        fuel    = Utils.clampNum(row.fuel, 0.0, 100.0, Config.DefaultFuel),
        status  = Utils.toBit(row.status),
        plate   = row.plate,
    })
end)

RegisterNetEvent('rpg-garages:spawnConfirm', function(pvId, netId)
    local src = source
    pvId = tonumber(pvId); netId = tonumber(netId)
    local s = Garages.spawned[pvId]
    if not s or s.ownerSrc ~= src or not netId then return end
    s.netId = netId
    s.pending = nil
    Garages.netIdToPv[netId] = pvId
    if Config.Debug then print(('[rpg-garages] spawn OK pv#%d net#%d (src %d)'):format(pvId, netId, src)) end
end)

RegisterNetEvent('rpg-garages:spawnFailed', function(pvId)
    local src = source
    pvId = tonumber(pvId)
    local s = Garages.spawned[pvId]
    if not s or s.ownerSrc ~= src then return end
    Garages.spawned[pvId] = nil
    MySQL.update.await('UPDATE personal_vehicle SET stored = 1 WHERE id = ?', { pvId })
    Garages.feedback(src, 'ERROR', 'Spawn eșuat. Vehiculul a rămas în garage.')
end)

-- ---------------------------------------------------------------------------
--  PARK (spec §6, §13) — serverul deduce vehiculul din ped, nu din client
-- ---------------------------------------------------------------------------
RegisterNetEvent('rpg-garages:parkRequest', function(garageId)
    local src = source
    local near, g = Garages.nearGarage(src, garageId)
    if not g then return Garages.feedback(src, 'ERROR', 'Garage inexistent.') end
    if not near then return Garages.feedback(src, 'ERROR', 'Ești prea departe de garage.') end

    local ped = GetPlayerPed(src)
    local veh = ped ~= 0 and GetVehiclePedIsIn(ped, false) or 0
    if not veh or veh == 0 then return Garages.feedback(src, 'ERROR', 'Nu ești într-un vehicul.') end

    local netId = NetworkGetNetworkIdFromEntity(veh)
    local pvId  = Garages.netIdToPv[netId]
    local s     = pvId and Garages.spawned[pvId] or nil
    if not s or s.ownerSrc ~= src then
        return Garages.feedback(src, 'ERROR', 'Acesta nu este un vehicul personal de-al tău.')
    end

    local row = MySQL.single.await('SELECT vehicle_type, owner_id, faction FROM personal_vehicle WHERE id = ? LIMIT 1', { pvId })
    if not row then return Garages.feedback(src, 'ERROR', 'Vehiculul nu mai există.') end

    if row.vehicle_type ~= g.type then
        return Garages.feedback(src, 'ERROR', ('Acest garage (%s) nu primește %s.'):format(g.type, row.vehicle_type))
    end
    if g.faction ~= '' then
        if row.faction ~= g.faction or not Utils.isFactionMember(src, g.faction) then
            return Garages.feedback(src, 'ERROR', 'Nu poți parca aici.')
        end
    elseif row.faction ~= '' or tonumber(row.owner_id) ~= Garages.accId(src) then
        return Garages.feedback(src, 'ERROR', 'Nu este vehiculul tău.')
    end

    s.parkGarage = g.id
    s.pending    = true   -- blocheaza autosave-ul in fereastra de park
    TriggerClientEvent('rpg-garages:collectState', src, pvId, true)   -- true = despawn dupa colectare
end)

-- ---------------------------------------------------------------------------
--  SUBMIT STATE — de la client (park SAU autosave). TOT se sanitizeaza aici.
--  st = { props = {tuning}, fuel = 0..100, odoMeters = >=0, status = 0/1, park = bool }
-- ---------------------------------------------------------------------------
RegisterNetEvent('rpg-garages:submitState', function(pvId, st)
    local src = source
    pvId = tonumber(pvId)
    local s = pvId and Garages.spawned[pvId] or nil
    if not s or s.ownerSrc ~= src or type(st) ~= 'table' then return end

    local fuel   = Utils.clampNum(st.fuel, 0.0, 100.0, Config.DefaultFuel)
    local odoKm  = Utils.clampNum((tonumber(st.odoMeters) or 0) / 1000.0, 0.0, Config.Odometer.maxDeltaKm, 0.0)
    local status = (tonumber(st.status) == Utils.STATUS_UNLOCKED) and Utils.STATUS_UNLOCKED or Utils.STATUS_LOCKED
    local clean  = Tuning.sanitize(st.props)

    Tuning.save(pvId, s.ownerId, clean)

    if st.park then
        MySQL.update.await([[
            UPDATE personal_vehicle
            SET fuel = ?, odometer = odometer + ?, status = ?, stored = 1, garage_id = ?
            WHERE id = ? AND owner_id = ?
        ]], { fuel, odoKm, status, s.parkGarage or nil, pvId, s.ownerId })

        if s.netId then Garages.netIdToPv[s.netId] = nil end
        Garages.spawned[pvId] = nil
        TriggerClientEvent('rpg-garages:despawn', src, pvId)
        Garages.feedback(src, 'SUCCESS', ('Vehicul parcat (fuel %d%%, +%.1f km).'):format(math.floor(fuel), odoKm))
    else
        MySQL.update.await([[
            UPDATE personal_vehicle
            SET fuel = ?, odometer = odometer + ?, status = ?
            WHERE id = ? AND owner_id = ?
        ]], { fuel, odoKm, status, pvId, s.ownerId })
        s.pending = nil
    end
end)

-- ---------------------------------------------------------------------------
--  LOCK / UNLOCK (spec §20) — actiune explicita, rara -> un UPDATE mic e ok
-- ---------------------------------------------------------------------------
RegisterNetEvent('rpg-garages:setLock', function(locked)
    local src = source
    local ped = GetPlayerPed(src)
    local veh = ped ~= 0 and GetVehiclePedIsIn(ped, false) or 0
    if not veh or veh == 0 then return end
    local pvId = Garages.netIdToPv[NetworkGetNetworkIdFromEntity(veh)]
    local s = pvId and Garages.spawned[pvId] or nil
    if not s or s.ownerSrc ~= src then return end

    local status = (locked == true) and Utils.STATUS_LOCKED or Utils.STATUS_UNLOCKED
    MySQL.update.await('UPDATE personal_vehicle SET status = ? WHERE id = ? AND owner_id = ?',
        { status, pvId, s.ownerId })
    TriggerClientEvent('rpg-garages:applyLock', src, s.netId, status == Utils.STATUS_LOCKED)
end)
