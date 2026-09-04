-- ===========================================================================
--  rpg-drivingschool — client
--  Blip + marker + interacțiune (E) -> NUI test teoretic -> test practic
--  (checkpoint-uri, virtual world dedicat). Notificările de rezultat sunt
--  text nativ pe mijlocul ecranului (fără NUI), ca în rpg-licences.
-- ===========================================================================

local nearSchool = false
local practical  = { active = false, route = {}, index = 1, vehicle = 0 }

-- ---------------------------------------------------------------- blip --
CreateThread(function()
    local b = Config.Location.blip
    local blip = AddBlipForCoord(Config.Location.coords.x, Config.Location.coords.y, Config.Location.coords.z)
    SetBlipSprite(blip, b.sprite)
    SetBlipColour(blip, b.color)
    SetBlipScale(blip, b.scale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(b.label)
    EndTextCommandSetBlipName(blip)
end)

-- --------------------------------------------------------------- text3D --
local function drawText3D(coords, text)
    local onScreen, sx, sy = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)
    if not onScreen then return end
    SetTextScale(0.34, 0.34)
    SetTextFont(4)
    SetTextColour(255, 255, 255, 215)
    SetTextOutline()
    SetTextCentre(true)
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(sx, sy)
end

-- --------------------------------------------------------- flash central --
local flash = { text = nil, untilMs = 0 }
local function showFlash(text, ms)
    flash.text = text
    flash.untilMs = GetGameTimer() + (ms or 5000)
end

CreateThread(function()
    while true do
        if flash.text and GetGameTimer() < flash.untilMs then
            SetTextFont(4)
            SetTextScale(0.55, 0.55)
            SetTextColour(255, 255, 255, 235)
            SetTextOutline()
            SetTextCentre(true)
            SetTextEntry('STRING')
            AddTextComponentString(flash.text)
            DrawText(0.5, 0.40)
            Wait(0)
        else
            flash.text = nil
            Wait(200)
        end
    end
end)

-- ---------------------------------------------------- interacțiune (E) --
RegisterCommand('rpgds_interact', function()
    if not nearSchool then return end
    TriggerServerEvent('rpg-drivingschool:tryStart')
end, false)
RegisterKeyMapping('rpgds_interact', 'Susține testul (Driving School)', 'keyboard', 'E')

CreateThread(function()
    while true do
        local sleep = 800
        local coords = GetEntityCoords(PlayerPedId())
        local dist = #(coords - Config.Location.coords)

        if dist < Config.Location.markerRadius then
            sleep = 0
            local m = Config.Location.marker
            DrawMarker(m.type,
                Config.Location.coords.x, Config.Location.coords.y, Config.Location.coords.z - 0.9,
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                m.size.x, m.size.y, m.size.z,
                m.color.r, m.color.g, m.color.b, m.color.a,
                false, false, 2, false, nil, nil, false)

            nearSchool = dist < Config.Location.interactRadius
            if nearSchool then
                drawText3D(Config.Location.coords + vector3(0.0, 0.0, 1.0),
                    ('[E] Susține testul de conducere ($%d)'):format(Config.TestCost))
            end
        else
            nearSchool = false
        end
        Wait(sleep)
    end
end)

-- ===========================================================================
--  PASUL 1 — TEST TEORETIC (NUI)
-- ===========================================================================
RegisterNetEvent('rpg-drivingschool:openTheory', function(questions)
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'openTheory', questions = questions, passScore = Config.PassScore })
end)

RegisterNUICallback('submitTheory', function(data, cb)
    SetNuiFocus(false, false)
    TriggerServerEvent('rpg-drivingschool:submitTheory', (data and data.answers) or {})
    cb('ok')
end)

RegisterNetEvent('rpg-drivingschool:theoryResult', function(passed, score)
    if passed then
        showFlash(('Felicitări ai promovat examentul teoretic!~n~Scor: %d%%'):format(score), 5000)
    else
        showFlash(('Din păcate ai picat examenul teoretic!~n~Mult noroc data viitoare~n~Scor: %d%%'):format(score), 5500)
    end
end)

-- ===========================================================================
--  PASUL 2 — TEST PRACTIC (checkpoint-uri, virtual world dedicat)
-- ===========================================================================
RegisterNetEvent('rpg-drivingschool:openPractical', function(netId, route, spawnCoords, spawnHeading)
    practical.route = route
    practical.index = 1

    local ped = PlayerPedId()

    -- teleportam jucatorul FIZIC la locul de spawn -- altfel ramane la vechea locatie
    -- (langa scoala), separat de masina, care nu apuca sa se streamuiasca la el.
    if spawnCoords then
        SetEntityCoordsNoOffset(ped, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, false)
        SetEntityHeading(ped, spawnHeading or 0.0)
    end

    local tries = 0
    local veh = NetworkGetEntityFromNetworkId(netId)
    while (not veh or veh == 0 or not DoesEntityExist(veh)) and tries < 50 do
        Wait(100)
        veh = NetworkGetEntityFromNetworkId(netId)
        tries = tries + 1
    end
    if not veh or veh == 0 or not DoesEntityExist(veh) then
        showFlash('Eroare la generarea mașinii de test.', 4000)
        return
    end

    practical.vehicle = veh
    practical.active = true

    -- siguranta: chiar langa masina (in caz ca a "cazut" putin diferit fata de spawnCoords)
    local vc = GetEntityCoords(veh)
    SetEntityCoordsNoOffset(ped, vc.x, vc.y, vc.z, false, false, false)
    TaskWarpPedIntoVehicle(ped, veh, -1)
    SetVehicleEngineOn(veh, true, true, false)

    showFlash(('Test practic: urmează cele %d checkpoint-uri!'):format(#route), 4000)
end)

RegisterNetEvent('rpg-drivingschool:practicalResult', function(passed, schoolCoords, schoolHeading)
    practical.active = false
    if passed then
        if schoolCoords then
            local ped = PlayerPedId()
            -- reasezarea coordonatelor scoate ped-ul din masina daca mai era in ea (ca in rpg-licences)
            SetEntityCoordsNoOffset(ped, schoolCoords.x, schoolCoords.y, schoolCoords.z, false, false, false)
            SetEntityHeading(ped, schoolHeading or 0.0)
        end
        showFlash('Felicitări ai promovat examenul practic~n~Ai obținut Driving Licence pentru 100%', 6000)
    end
end)

-- checkpoint-ul curent: marker (pulsant, vizibil de departe) + text 3D "X/N" + blip cu rută pe minimap.
-- avans optimist local -- rezultatul FINAL vine mereu de la server (vezi practicalResult).
CreateThread(function()
    local cpBlip = nil
    while true do
        if practical.active then
            local i = practical.index
            local cp = practical.route[i]
            if cp then
                if not cpBlip then
                    cpBlip = AddBlipForCoord(cp.x, cp.y, cp.z)
                    SetBlipSprite(cpBlip, 1)
                    SetBlipColour(cpBlip, 5)
                    SetBlipRoute(cpBlip, true)
                    SetBlipRouteColour(cpBlip, 5)
                end

                -- marker mare, mov, care "pulseaza" -> usor de vazut de la distanta
                local pulse = 1.0 + math.sin(GetGameTimer() / 250.0) * 0.18
                DrawMarker(1, cp.x, cp.y, cp.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    3.2 * pulse, 3.2 * pulse, 2.0, 168, 85, 247, 210, false, false, 2, true, nil, nil, false)

                drawText3D(cp + vector3(0.0, 0.0, 1.2), ('Checkpoint %d/%d'):format(i, #practical.route))

                local dist = #(GetEntityCoords(PlayerPedId()) - cp)
                if dist < Config.CheckpointRadius then
                    TriggerServerEvent('rpg-drivingschool:reachedCheckpoint', i)
                    practical.index = i + 1
                    if cpBlip then RemoveBlip(cpBlip); cpBlip = nil end
                    if practical.index > #practical.route then practical.active = false end
                end
            end
            Wait(0)
        else
            if cpBlip then RemoveBlip(cpBlip); cpBlip = nil end
            Wait(300)
        end
    end
end)

-- anulare automată dacă jucătorul coboară din mașină și nu revine (~8s)
CreateThread(function()
    local outSince = 0
    while true do
        Wait(1000)
        if practical.active then
            if IsPedInAnyVehicle(PlayerPedId(), false) then
                outSince = 0
            else
                if outSince == 0 then outSince = GetGameTimer() end
                if GetGameTimer() - outSince > 8000 then
                    practical.active = false
                    outSince = 0
                    TriggerServerEvent('rpg-drivingschool:abortPractical')
                    showFlash('Testul practic a fost anulat (ai coborât din mașină).', 4000)
                end
            end
        else
            outSince = 0
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
end)
