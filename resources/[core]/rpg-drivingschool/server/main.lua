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

    if ex.vehicle and DoesEntityExist(ex.vehicle) then
        SetEntityRoutingBucket(ex.vehicle, 0)   -- altfel ramane "invizibil" dupa ce jucatorul revine in bucket 0
    end
    SetPlayerRoutingBucket(src, 0)

    if ex.vehicle and DoesEntityExist(ex.vehicle) then
        local veh = ex.vehicle
        SetTimeout(20000, function()   -- lasa timp jucatorului sa coboare/parcheze inainte de curatare
            if DoesEntityExist(veh) then DeleteEntity(veh) end
        end)
    end

    TriggerClientEvent('rpg-drivingschool:practicalResult', src, true)
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

    local c = Config.Location.coords
    local veh = CreateVehicleServerSetter(Config.PracticalVehicle, 'automobile', c.x, c.y, c.z, Config.Location.heading)
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

    local netId = NetworkGetNetworkIdFromEntity(veh)
    TriggerClientEvent('rpg-drivingschool:openPractical', src, netId, Config.PracticalRoute)
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
