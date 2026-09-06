-- ===========================================================================
--  rpg-garages — client / vehicle
--  Spawn (creare + tuning + fuel + lock + warp), despawn, colectare stare
--  (park + autosave), tracking odometer (esantionat, spec §18), lock/unlock.
-- ===========================================================================

GG.spawnedPv  = GG.spawnedPv or {}   -- [pvId]   = { entity, netId, lastPos, odoMeters }
GG.entityToPv = GG.entityToPv or {}  -- [entity] = pvId

local function toast(kind, text) UI.toast(kind, text) end

-- rezultat spawn -> NUI (revine din "SPAWNING..." sau se inchide la succes)
local function finishSpawn(ok, text)
    SendNUIMessage({ action = 'spawnResult', ok = ok == true, text = text })
    if ok == true and GG.closeUI then GG.closeUI() end
end

-- ---------------------------------------------------------------------------
--  SPAWN (spec §15) — serverul a validat deja tot; clientul creeaza entitatea
-- ---------------------------------------------------------------------------
RegisterNetEvent('rpg-garages:doSpawn', function(d)
    if type(d) ~= 'table' or not d.pvId then return end
    if GG.spawnedPv[d.pvId] then return end   -- deja avem entitatea

    local hash = GetHashKey(d.model)
    if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then
        TriggerServerEvent('rpg-garages:spawnFailed', d.pvId)
        finishSpawn(false, ('Model invalid: %s'):format(d.model))
        return toast('err', ('Model invalid: %s'):format(d.model))
    end

    RequestModel(hash)
    local t0 = GetGameTimer()
    while not HasModelLoaded(hash) and GetGameTimer() - t0 < 10000 do Wait(30) end
    if not HasModelLoaded(hash) then
        TriggerServerEvent('rpg-garages:spawnFailed', d.pvId)
        finishSpawn(false, 'Nu s-a putut încărca modelul.')
        return toast('err', 'Nu s-a putut încărca modelul.')
    end

    local veh = CreateVehicle(hash, d.x + 0.0, d.y + 0.0, d.z + 0.0, (d.h or 0.0) + 0.0, true, false)
    SetModelAsNoLongerNeeded(hash)

    local tries = 0
    while (not veh or veh == 0 or not DoesEntityExist(veh)) and tries < 60 do Wait(20); tries = tries + 1 end
    if not veh or veh == 0 or not DoesEntityExist(veh) then
        TriggerServerEvent('rpg-garages:spawnFailed', d.pvId)
        finishSpawn(false, 'Spawn eșuat.')
        return toast('err', 'Spawn eșuat.')
    end

    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleOnGroundProperly(veh)
    SetVehicleHasBeenOwnedByPlayer(veh, true)
    SetVehicleNeedsToBeHotwired(veh, false)
    SetVehRadioStation(veh, 'OFF')

    Tuning.apply(veh, d.tuning)                       -- spec §6 — tuning aplicat integral
    SetVehicleFuelLevel(veh, (tonumber(d.fuel) or 100.0) + 0.0)   -- spec §19 — fuel din DB

    local locked = (tonumber(d.status) or 0) == 0    -- 0 = Locked
    SetVehicleDoorsLocked(veh, locked and 2 or 1)

    if d.plate and d.plate ~= '' then SetVehicleNumberPlateText(veh, d.plate) end

    local netId = NetworkGetNetworkIdFromEntity(veh)
    Entity(veh).state:set('pvId', d.pvId, true)       -- pt. detectia PARK prompt (toti clientii)

    GG.spawnedPv[d.pvId] = { entity = veh, netId = netId, lastPos = GetEntityCoords(veh), odoMeters = 0.0 }
    GG.entityToPv[veh] = d.pvId

    TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
    TriggerServerEvent('rpg-garages:spawnConfirm', d.pvId, netId)
    finishSpawn(true)
    toast('ok', 'Vehicul scos din garage.')
end)

-- ---------------------------------------------------------------------------
--  DESPAWN
-- ---------------------------------------------------------------------------
RegisterNetEvent('rpg-garages:despawn', function(pvId)
    local s = GG.spawnedPv[pvId]
    if not s then return end
    if s.entity and DoesEntityExist(s.entity) then
        GG.entityToPv[s.entity] = nil
        SetEntityAsMissionEntity(s.entity, true, true)
        DeleteEntity(s.entity)
    end
    GG.spawnedPv[pvId] = nil
end)

-- ---------------------------------------------------------------------------
--  COLECTARE STARE — park (doDespawn = true) sau autosave (false)
--  Clientul e singurul care poate citi fuel/tuning/pozitie => trimite, serverul
--  SANITIZEAZA tot (clamp fuel/odo, whitelist tuning) inainte sa persiste.
-- ---------------------------------------------------------------------------
RegisterNetEvent('rpg-garages:collectState', function(pvId, doDespawn)
    local s = GG.spawnedPv[pvId]
    if not s or not s.entity or not DoesEntityExist(s.entity) then
        if doDespawn then
            TriggerServerEvent('rpg-garages:submitState', pvId,
                { park = true, fuel = Config.DefaultFuel, odoMeters = 0, status = 0, props = {} })
        end
        return
    end

    local veh = s.entity
    local cur = GetEntityCoords(veh)
    if s.lastPos then
        local dm = #(cur - s.lastPos)
        if dm > 0.5 and dm < Config.Odometer.maxJumpM then s.odoMeters = (s.odoMeters or 0.0) + dm end
    end
    s.lastPos = cur

    local locked = GetVehicleDoorLockStatus(veh) == 2
    TriggerServerEvent('rpg-garages:submitState', pvId, {
        props     = Tuning.get(veh),
        fuel      = GetVehicleFuelLevel(veh),
        odoMeters = s.odoMeters or 0.0,
        status    = locked and 0 or 1,
        park      = doDespawn == true,
    })
    s.odoMeters = 0.0   -- deltele au fost trimise; server-ul le-a adunat la odometer
end)

-- ---------------------------------------------------------------------------
--  ODOMETER — esantionare la interval (spec §18/§22), NU per frame
-- ---------------------------------------------------------------------------
CreateThread(function()
    while true do
        Wait(Config.Odometer.sampleMs)
        for _, s in pairs(GG.spawnedPv) do
            if s.entity and DoesEntityExist(s.entity) then
                local cur = GetEntityCoords(s.entity)
                if s.lastPos then
                    local dm = #(cur - s.lastPos)
                    if dm > 0.5 and dm < Config.Odometer.maxJumpM then
                        s.odoMeters = (s.odoMeters or 0.0) + dm
                    end
                end
                s.lastPos = cur
            end
        end
    end
end)

-- ---------------------------------------------------------------------------
--  LOCK / UNLOCK (spec §20)
-- ---------------------------------------------------------------------------
RegisterNetEvent('rpg-garages:applyLock', function(netId, locked)
    local veh = NetworkGetEntityFromNetworkId(tonumber(netId or 0))
    if veh and veh ~= 0 and DoesEntityExist(veh) then
        SetVehicleDoorsLocked(veh, locked and 2 or 1)
    end
end)

local function toggleLock()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        local pc = GetEntityCoords(ped)
        for _, s in pairs(GG.spawnedPv) do
            if s.entity and DoesEntityExist(s.entity) and #(pc - GetEntityCoords(s.entity)) < 5.0 then
                veh = s.entity ; break
            end
        end
    end
    if veh == 0 or not GG.entityToPv[veh] then return end

    local lock = GetVehicleDoorLockStatus(veh) ~= 2   -- momentan descuiat -> incuiem
    SetVehicleDoorsLocked(veh, lock and 2 or 1)
    TriggerServerEvent('rpg-garages:setLock', lock)
    SendNUIMessage({ action = 'toast', kind = 'info', text = lock and 'Vehicul încuiat' or 'Vehicul descuiat' })
end

RegisterCommand('+rpggarages_lock', toggleLock, false)
RegisterCommand('-rpggarages_lock', function() end, false)
RegisterKeyMapping('+rpggarages_lock', 'Garaje: încuie/descuie vehiculul personal', 'keyboard', Config.LockKey or 'L')

-- ---------------------------------------------------------------------------
--  curatare la oprirea resursei
-- ---------------------------------------------------------------------------
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, s in pairs(GG.spawnedPv) do
        if s.entity and DoesEntityExist(s.entity) then
            SetEntityAsMissionEntity(s.entity, true, true)
            DeleteEntity(s.entity)
        end
    end
end)
