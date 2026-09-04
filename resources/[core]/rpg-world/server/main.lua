-- ===========================================================================
--  rpg-world — server
--  Re-validare server-side a toggle-ului de NoClip + statebag replicat 'noclip'
--  -> orice alt client, la schimbarea acestui statebag, ascunde/arata ped-ul
--  jucatorului respectiv (vezi client/noclip.lua). Jucatorul insusi ramane doar
--  translucid local (nu se ascunde de el insusi).
-- ===========================================================================

local function hasRank(src, rank)
    if src <= 0 then return true end
    local ok, allowed = pcall(function() return exports['rpg-auth']:hasStaffLevel(src, rank) end)
    return ok and allowed == true
end

local function feedback(src, channel, text)
    local ok = pcall(function()
        exports['rpg-hud']:addChatMessage(src, { channel = channel, text = text })
    end)
    if not ok then
        TriggerClientEvent('chat:addMessage', src, { color = { 190, 130, 255 }, args = { 'WORLD', text } })
    end
end

RegisterNetEvent('rpg-world:noclipToggle', function(on)
    local src = source
    if not hasRank(src, Config.NoClip.minRank) then return end

    local ply = Player(src)
    if ply and ply.state then
        ply.state:set('noclip', on and true or false, true)   -- replicat -> vizibil pt. toti clientii
    end
end)

-- daca playerul pleaca in timp ce era in NoClip, statebag-ul dispare o data cu el
-- (nu mai e nimeni de ascuns), deci nu mai e nevoie de curatare explicita aici.

-- ===========================================================================
--  /spawncar [model]  — staff >= Config.SpawnCarRank
--  Genereaza vehiculul server-side (networked) langa player si il pune la volan.
-- ===========================================================================
RegisterCommand('spawncar', function(src, args)
    if not hasRank(src, Config.SpawnCarRank) then
        return feedback(src, 'ERROR', 'Nu ai acces la această comandă.')
    end
    if src <= 0 then return print('[rpg-world] /spawncar trebuie rulat de un player.') end

    local model = tostring(args[1] or '')
    if model == '' then return feedback(src, 'ERROR', 'Folosire: /spawncar [model]') end

    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local rad = math.rad(heading)
    local fx, fy = -math.sin(rad), math.cos(rad)   -- 4m in fata playerului, sa nu aterizeze in el
    local sx, sy, sz = coords.x + fx * 4.0, coords.y + fy * 4.0, coords.z

    local veh = CreateVehicleServerSetter(GetHashKey(model), 'automobile', sx, sy, sz, heading)
    if not veh or veh == 0 then
        return feedback(src, 'ERROR', ('Model invalid sau eroare la creare: %s'):format(model))
    end
    SetVehicleFuelLevel(veh, 100.0)

    local netId = NetworkGetNetworkIdFromEntity(veh)
    TriggerClientEvent('rpg-world:enterSpawnedVehicle', src, netId)

    feedback(src, 'SUCCESS', ('Vehicul generat: %s'):format(model))
    print(('[rpg-world] /spawncar: src %d -> %s'):format(src, model))
end, false)

-- ===========================================================================
--  /maxperf  — staff >= Config.MaxPerfRank
--  Seteaza vehiculul CURENT (in care esti) la: motor/frana/suspensie MAX + turbo.
-- ===========================================================================
RegisterCommand('maxperf', function(src)
    if not hasRank(src, Config.MaxPerfRank) then
        return feedback(src, 'ERROR', 'Nu ai acces la această comandă.')
    end
    if src <= 0 then return print('[rpg-world] /maxperf trebuie rulat de un player.') end

    local ped = GetPlayerPed(src)
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        return feedback(src, 'ERROR', 'Nu ești într-un vehicul.')
    end

    SetVehicleModKit(veh, 0)
    SetVehicleMod(veh, 11, GetNumVehicleMods(veh, 11) - 1, false)   -- Engine (max)
    SetVehicleMod(veh, 12, GetNumVehicleMods(veh, 12) - 1, false)   -- Brakes (max)
    SetVehicleMod(veh, 15, GetNumVehicleMods(veh, 15) - 1, false)   -- Suspension (nivel maxim = "Race" in LS Customs)
    ToggleVehicleMod(veh, 18, true)                                  -- Turbo (on/off, nu are trepte)

    feedback(src, 'SUCCESS', 'Performanță maximă aplicată (motor, frâne, suspensie Race, turbo).')
    print(('[rpg-world] /maxperf: src %d -> vehicul #%d'):format(src, veh))
end, false)
