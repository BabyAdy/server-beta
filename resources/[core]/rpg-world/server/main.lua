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

local function cmdIssuer(src)
    if src <= 0 then return 'Consolă', 'Consolă' end
    local name = GetPlayerName(src) or ('src' .. src)
    local ok, acc = pcall(function() return exports['rpg-auth']:getAccount(src) end)
    if ok and acc and acc.username then name = acc.username end
    local label = 'Staff'
    local okl, l = pcall(function() return exports['rpg-auth']:getStaffLabel(src) end)
    if okl and l and l ~= '' then label = l end
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
    print(('[rpg-world][staff] %s'):format(text))
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

-- ===========================================================================
--  /setvw [sql id] [virtual id]  — staff >= Config.SetVwRank
--  Muta jucatorul [sql id] in virtual world-ul (routing bucket) [virtual id].
--  "sql id" = SQL id de PERSONAJ (ca la /setstaff), rezolvat prin rpg-characters.
-- ===========================================================================
RegisterCommand('setvw', function(src, args)
    if not hasRank(src, Config.SetVwRank) then
        return feedback(src, 'ERROR', 'Nu ai acces la această comandă.')
    end

    local charId = tonumber(args[1])
    local vw     = tonumber(args[2])
    if not charId or not vw or vw < 0 then
        return feedback(src, 'ERROR', 'Folosire: /setvw [sql id] [virtual id]')
    end
    vw = math.floor(vw)
    if vw > 65535 then
        return feedback(src, 'ERROR', 'Virtual World invalid (0 - 65535).')
    end

    local target = exports['rpg-characters']:resolveCharacter(charId)
    if not target or not target.src then
        return feedback(src, 'ERROR', 'Jucătorul nu este online.')
    end

    SetPlayerRoutingBucket(target.src, vw)

    local giverName, giverLabel = cmdIssuer(src)
    feedback(src, 'SUCCESS', ('Ai mutat %s (#%s) în Virtual World %d.'):format(target.username or '?', charId, vw))
    if target.src ~= src then
        feedback(target.src, 'INFO', ('Ai fost mutat în Virtual World %d.'):format(vw))
    end

    staffBroadcast(Config.SetVwBroadcastRank,
        ('Staff: %s %s set %s [%s] Virtual World %d!')
            :format(giverLabel, giverName, target.username or '?', charId, vw))

    print(('[rpg-world] /setvw: %s(#%s) -> personaj #%s in VW %d'):format(giverName, src, charId, vw))
end, false)
