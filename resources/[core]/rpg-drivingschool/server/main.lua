-- ===========================================================================
--  rpg-drivingschool — server
--  Autoritate: plata testului, corectarea testului teoretic (client NU vede
--  niciodata raspunsul corect), ordinea checkpoint-urilor la testul practic,
--  acordarea licentei (prin exports din rpg-licences).
-- ===========================================================================

local exams    = {}   -- [src] = { stage = 'theory'|'practical', vehicle, cpIndex }
local starting = {}   -- [src] = true   (anti dublu-start pe /tryStart)
local lastCpAt = {}   -- [src] = GetGameTimer() la ultimul checkpoint validat

-- ---- helperi -----------------------------------------------------------
local function feedback(src, channel, text)
    local ok = pcall(function()
        exports['rpg-hud']:addChatMessage(src, { channel = channel, text = text })
    end)
    if not ok then
        TriggerClientEvent('chat:addMessage', src, { color = { 130, 180, 255 }, args = { 'DRIVING SCHOOL', text } })
    end
end

local function moneyOf(src)
    local ok, v = pcall(function() return exports['rpg-level']:getMoney(src) end)
    return (ok and tonumber(v)) or 0
end

-- ===========================================================================
--  FINALIZARE PRACTIC
-- ===========================================================================
local function finishPractical(src)
    local ex = exams[src]
    if not ex then return end
    exams[src] = nil
    lastCpAt[src] = nil

    pcall(function() exports['rpg-licences']:setExamBypass(src, false) end)
    pcall(function() exports['rpg-licences']:addLicenceHours(src, 'driving', Config.RewardHours) end)

    SetPlayerRoutingBucket(src, 0)   -- jucatorul revine in virtual world 0

    -- teleportat la Config.Location (scoala) -- vezi client (SetEntityCoordsNoOffset), scoate-l si din masina
    TriggerClientEvent('rpg-drivingschool:practicalResult', src, true, Config.Location.coords, Config.Location.heading)

    if ex.vehicle and DoesEntityExist(ex.vehicle) then
        local veh = ex.vehicle
        SetTimeout(2000, function()   -- lasa timp teleportului clientului sa se aplice inainte sa stearga masina
            if DoesEntityExist(veh) then DeleteEntity(veh) end
        end)
    end

    feedback(src, 'SUCCESS', 'Felicitări, ai promovat testul practic! Ai obținut Driving Licence.')
    print(('[rpg-drivingschool] src %d a promovat testul practic (+%d ore driving).'):format(src, Config.RewardHours))
end

-- ===========================================================================
--  PORNIRE PRACTIC (dupa promovarea teoriei)
-- ===========================================================================
local function startPractical(src)
    local ex = exams[src]
    if not ex then return end
    ex.stage = 'practical'
    ex.cpIndex = 1

    pcall(function() exports['rpg-licences']:setExamBypass(src, true) end)   -- poate conduce fara licenta CAT TIMP e in examen

    SetPlayerRoutingBucket(src, Config.PracticalVirtualWorld)

    local c = Config.PracticalSpawn.coords
    local veh = CreateVehicleServerSetter(Config.PracticalVehicle, 'automobile', c.x, c.y, c.z, Config.PracticalSpawn.heading)
    if not veh or veh == 0 then
        exams[src] = nil
        pcall(function() exports['rpg-licences']:setExamBypass(src, false) end)
        SetPlayerRoutingBucket(src, 0)
        return feedback(src, 'ERROR', 'Nu am putut genera mașina de test. Încearcă din nou.')
    end
    SetEntityRoutingBucket(veh, Config.PracticalVirtualWorld)
    SetVehicleFuelLevel(veh, 100.0)
    SetVehicleOnGroundProperly(veh)
    ex.vehicle = veh

    -- IMPORTANT: bucket-ul de rutare NU muta jucatorul in spatiu -- ramanea la coordonatele
    -- vechi (langa scoala), separat de masina, iar aceasta niciodata nu se "streamuia" la el
    -- (prea departe) => TaskWarpPedIntoVehicle esua in tacere si checkpoint-urile nu se activau
    -- niciodata (practical.active ramanea false). Trimitem si coordonatele de spawn -> clientul
    -- il teleporteaza pe player FIZIC langa masina, inainte de a incerca sa-l urce in ea.
    local netId = NetworkGetNetworkIdFromEntity(veh)
    TriggerClientEvent('rpg-drivingschool:openPractical', src, netId, Config.PracticalRoute,
        Config.PracticalSpawn.coords, Config.PracticalSpawn.heading)
end

-- ===========================================================================
--  START (tasta E in checkpoint) — verifica + scade $100
-- ===========================================================================
RegisterNetEvent('rpg-drivingschool:tryStart', function()
    local src = source
    if exams[src] or starting[src] then
        return feedback(src, 'ERROR', 'Ai deja un test în desfășurare.')
    end
    if moneyOf(src) < Config.TestCost then
        return feedback(src, 'ERROR', ('Ai nevoie de $%d cash pentru a susține testul.'):format(Config.TestCost))
    end

    starting[src] = true
    local ok = pcall(function() exports['rpg-level']:addMoney(src, -Config.TestCost) end)
    starting[src] = nil
    if not ok then
        return feedback(src, 'ERROR', 'Eroare la plată. Încearcă din nou.')
    end

    exams[src] = { stage = 'theory' }
    feedback(src, 'INFO', ('Ai plătit $%d. Succes la testul teoretic!'):format(Config.TestCost))

    -- IMPORTANT: campul `correct` NU se trimite niciodata catre client
    local publicQuestions = {}
    for i, q in ipairs(Config.Questions) do
        publicQuestions[i] = { text = q.text, answers = q.answers }
    end
    TriggerClientEvent('rpg-drivingschool:openTheory', src, publicQuestions)
end)

-- ===========================================================================
--  TEORIE — corectare pe server
-- ===========================================================================
RegisterNetEvent('rpg-drivingschool:submitTheory', function(answers)
    local src = source
    local ex = exams[src]
    if not ex or ex.stage ~= 'theory' then return end
    if type(answers) ~= 'table' or #answers ~= #Config.Questions then return end

    local correct = 0
    for i, q in ipairs(Config.Questions) do
        if tonumber(answers[i]) == q.correct then correct = correct + 1 end
    end
    local score = math.floor((correct / #Config.Questions) * 100 + 0.5)
    local passed = score >= Config.PassScore

    TriggerClientEvent('rpg-drivingschool:theoryResult', src, passed, score)

    if passed then
        startPractical(src)
    else
        exams[src] = nil
        feedback(src, 'ERROR', ('Ai picat testul teoretic (%d%%). Poți reîncerca de la ghișeu.'):format(score))
    end
end)

-- ===========================================================================
--  PRACTIC — checkpoint-uri validate STRICT in ordine, cu un mic rate-limit
-- ===========================================================================
RegisterNetEvent('rpg-drivingschool:reachedCheckpoint', function(index)
    local src = source
    local ex = exams[src]
    if not ex or ex.stage ~= 'practical' then return end

    index = tonumber(index)
    if index ~= ex.cpIndex then return end          -- ordine obligatorie

    local now = GetGameTimer()
    if lastCpAt[src] and (now - lastCpAt[src]) < 1000 then return end
    lastCpAt[src] = now

    if index >= #Config.PracticalRoute then
        finishPractical(src)
    else
        ex.cpIndex = index + 1
    end
end)

RegisterNetEvent('rpg-drivingschool:abortPractical', function()
    local src = source
    local ex = exams[src]
    if not ex or ex.stage ~= 'practical' then return end
    exams[src] = nil
    lastCpAt[src] = nil

    pcall(function() exports['rpg-licences']:setExamBypass(src, false) end)
    if ex.vehicle and DoesEntityExist(ex.vehicle) then
        SetEntityRoutingBucket(ex.vehicle, 0)
        local veh = ex.vehicle
        SetTimeout(3000, function() if DoesEntityExist(veh) then DeleteEntity(veh) end end)
    end
    SetPlayerRoutingBucket(src, 0)
    feedback(src, 'ERROR', 'Testul practic a fost anulat.')
end)

-- ===========================================================================
--  cleanup
-- ===========================================================================
AddEventHandler('playerDropped', function()
    local src = source
    local ex = exams[src]
    if ex then
        pcall(function() exports['rpg-licences']:setExamBypass(src, false) end)
        if ex.vehicle and DoesEntityExist(ex.vehicle) then DeleteEntity(ex.vehicle) end
    end
    exams[src] = nil
    lastCpAt[src] = nil
    starting[src] = nil
end)

-- ===========================================================================
--  UNELTE DE SETUP  (staff >= trialadmin)  —  /savecoord /listcoords /clearcoords
--  Scop: mergi in joc la locatia scolii + la fiecare din cele 15 checkpoint-uri,
--  ruleaza /savecoord [label] in fiecare punct, apoi /listcoords ca sa iei tot
--  continutul si sa mi-l dai -> il transform in Config.Location / Config.PracticalRoute.
--  100% server-side (GetEntityCoords/GetEntityHeading merg si pe server pt. ped-ul
--  unui player conectat) -- nu are nevoie de nimic pe client.
-- ===========================================================================
local COORDS_FILE = 'captured_coords.lua'

local function canSetup(src)
    if src <= 0 then return true end
    local ok, allowed = pcall(function() return exports['rpg-auth']:hasStaffLevel(src, 'trialadmin') end)
    return ok and allowed == true
end

local function readCoordsFile()
    return LoadResourceFile(GetCurrentResourceName(), COORDS_FILE) or ''
end

RegisterCommand('savecoord', function(src, args)
    if not canSetup(src) then return feedback(src, 'ERROR', 'Nu ai acces la această comandă.') end
    if src <= 0 then return print('[rpg-drivingschool] /savecoord rulează doar pentru un player (are nevoie de poziția lui).') end

    local label = tostring(args[1] or ''):gsub('%s+', '_')
    if label == '' then return feedback(src, 'ERROR', 'Folosire: /savecoord [label]  (ex: school, cp1, cp2...)') end

    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    local line = ('%s = vector3(%.2f, %.2f, %.2f)  -- heading %.1f\n')
        :format(label, coords.x, coords.y, coords.z, heading)
    SaveResourceFile(GetCurrentResourceName(), COORDS_FILE, readCoordsFile() .. line, -1)

    feedback(src, 'SUCCESS',
        ('Salvat "%s": %.2f, %.2f, %.2f (heading %.1f)'):format(label, coords.x, coords.y, coords.z, heading))
    print('[rpg-drivingschool] savecoord: ' .. line)
end, false)

RegisterCommand('listcoords', function(src)
    if not canSetup(src) then return feedback(src, 'ERROR', 'Nu ai acces la această comandă.') end
    local content = readCoordsFile()
    if content == '' then
        feedback(src, 'INFO', 'Nu ai salvat încă niciun punct (/savecoord [label]).')
        return
    end
    print('[rpg-drivingschool] ===== captured_coords.lua =====\n' .. content .. '================================')
    feedback(src, 'SUCCESS', 'Am printat toate punctele salvate în consola serverului (copiază de acolo).')
end, false)

RegisterCommand('clearcoords', function(src)
    if not canSetup(src) then return feedback(src, 'ERROR', 'Nu ai acces la această comandă.') end
    SaveResourceFile(GetCurrentResourceName(), COORDS_FILE, '', -1)
    feedback(src, 'SUCCESS', 'Lista de coordonate a fost golită.')
end, false)
