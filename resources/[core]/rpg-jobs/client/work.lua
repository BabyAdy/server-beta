-- ===========================================================================
--  rpg-jobs — WORK SESSION FLOW (client)
--  Primeste checkpoint-uri de la server, deseneaza blip/marker/traseu, detecteaza
--  sosirea si asteapta ca playerul sa apese E (PE JOS, nu in vehicul) ca sa ceara
--  minigame-ul. Serverul re-valideaza distanta, vehiculul si starea.
--  Nu decide nimic despre reward/skill/progres — doar afiseaza.
-- ===========================================================================

local task = nil        -- { index, x, y, z }
local taskBlip = nil
local nextSendAt = 0    -- GetGameTimer() minim pentru urmatorul rpg-jobs:reachedTask
local promptOn = nil    -- ultima stare trimisa la NUI pentru #wprompt

local MARKER = { type = 1, r = 246, g = 190, b = 0, a = 130 }

local function clearTaskBlip()
    if taskBlip and DoesBlipExist(taskBlip) then RemoveBlip(taskBlip) end
    taskBlip = nil
end

local function setWorkPrompt(show, label)
    local key = tostring(show) .. '|' .. tostring(label or '')
    if promptOn == key then return end
    promptOn = key
    SendNUIMessage({ action = 'wprompt', show = show, label = label or '' })
end

local function setTask(t)
    task = t
    nextSendAt = 0
    clearTaskBlip()
    setWorkPrompt(false)
    if not t then return end
    local c = vector3(t.x, t.y, t.z)
    taskBlip = AddBlipForCoord(c.x, c.y, c.z)
    SetBlipSprite(taskBlip, JB.job.workBlip and JB.job.workBlip.sprite or 500)
    SetBlipColour(taskBlip, JB.job.workBlip and JB.job.workBlip.color or 5)
    SetBlipScale(taskBlip, JB.job.workBlip and JB.job.workBlip.scale or 0.7)
    SetBlipRoute(taskBlip, true)
    SetBlipRouteColour(taskBlip, JB.job.workBlip and JB.job.workBlip.color or 5)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(('Electric Panel #%d'):format(t.index))
    EndTextCommandSetBlipName(taskBlip)
end

-- ---- server -> client (sesiune) -----------------------------
RegisterNetEvent('rpg-jobs:shiftStarted', function()
    JB.isWorking = true
    SendNUIMessage({ action = 'toast', text = 'Shift started. Head to the marked panel.', kind = 'info' })
    SendNUIMessage({ action = 'hud', show = true, done = 0, earned = 0 })
end)

RegisterNetEvent('rpg-jobs:task', function(t)
    setTask(t)
    SendNUIMessage({ action = 'toast', text = 'Go to the electric panel on foot.', kind = 'info' })
end)

RegisterNetEvent('rpg-jobs:taskDone', function(d)
    clearTaskBlip()
    task = nil
    setWorkPrompt(false)
    if JB.mgOpen then JB.mgOpen = false; JB.setFocus(false) end
    SendNUIMessage({ action = 'mgDone' })
    SendNUIMessage({ action = 'hud', show = true, done = d.done, earned = d.earned })
    SendNUIMessage({ action = 'toast', text = ('Panel repaired  ·  +$%s'):format(d.reward), kind = 'success' })
end)

RegisterNetEvent('rpg-jobs:minigameFailed', function(d)
    nextSendAt = GetGameTimer() + (d.retryMs or 2000)
    if JB.mgOpen then JB.mgOpen = false; JB.setFocus(false) end
    SendNUIMessage({ action = 'mgClose' })
    SendNUIMessage({ action = 'toast', text = 'Repair failed. Recalibrating…', kind = 'error' })
end)

RegisterNetEvent('rpg-jobs:shiftComplete', function(d)
    JB.isWorking = false
    clearTaskBlip(); task = nil
    setWorkPrompt(false)
    if JB.mgOpen then JB.mgOpen = false end
    if JB.menuOpen then JB.menuOpen = false; SendNUIMessage({ action = 'closeMenu' }) end
    SendNUIMessage({ action = 'hud', show = false })
    JB.doneOpen = true
    JB.setFocus(true)   -- cursor pentru butonul CONTINUE (eliberat de callback-ul 'doneClose')
    SendNUIMessage({ action = 'shiftComplete', data = d })
    SetTimeout(30000, function()
        if JB.doneOpen then
            JB.doneOpen = false
            JB.setFocus(false)
            SendNUIMessage({ action = 'forceCloseDone' })
        end
    end)
end)

RegisterNetEvent('rpg-jobs:shiftAborted', function(d)
    JB.isWorking = false
    clearTaskBlip(); task = nil
    setWorkPrompt(false)
    SendNUIMessage({ action = 'hud', show = false })
    if d and d.reason ~= 'player_cancel' then
        SendNUIMessage({ action = 'toast', text = 'Shift cancelled.', kind = 'error' })
    end
end)

-- ---- detectare sosire + marker + [E] pornire (PE JOS) ------
CreateThread(function()
    while true do
        local wait = 500
        if task and not JB.mgOpen and not JB.doneOpen then
            wait = 0
            local ped = PlayerPedId()
            local c = vector3(task.x, task.y, task.z)
            local pc = GetEntityCoords(ped)
            local dist = #(pc - c)

            if dist < 25.0 then
                DrawMarker(MARKER.type, c.x, c.y, c.z - 0.95, 0,0,0, 0,0,0,
                    1.4, 1.4, 1.0, MARKER.r, MARKER.g, MARKER.b, MARKER.a, false, false, 2, false, nil, nil, false)
            end

            if dist < (Config.Security.taskRadius - 0.5) then
                if IsPedInAnyVehicle(ped, false) then
                    setWorkPrompt(true, 'Exit the vehicle to start the repair')
                else
                    setWorkPrompt(true, 'Start the repair')
                    if IsControlJustReleased(0, Config.StartWorkKey) and GetGameTimer() >= nextSendAt then
                        nextSendAt = GetGameTimer() + 3000   -- re-trimite doar daca serverul nu raspunde
                        TriggerServerEvent('rpg-jobs:reachedTask', task.index)
                    end
                end
            else
                setWorkPrompt(false)
            end
        else
            setWorkPrompt(false)
        end
        Wait(wait)
    end
end)

-- ---- moartea in timpul lucrului -> opreste sesiunea -------
CreateThread(function()
    local flagged = false
    while true do
        Wait(600)
        if JB.isWorking and (IsEntityDead(PlayerPedId()) or IsPedDeadOrDying(PlayerPedId(), true)) then
            if not flagged then
                flagged = true
                TriggerServerEvent('rpg-jobs:playerDied')
            end
        else
            flagged = false
        end
    end
end)

-- /stopwork — opreste sesiunea (banii per-panou raman incasati). /canceljob = alias vechi.
local function stopWorkCmd()
    if JB.isWorking then TriggerServerEvent('rpg-jobs:stopWork') end
end
RegisterCommand('stopwork', stopWorkCmd, false)
RegisterCommand('canceljob', stopWorkCmd, false)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then clearTaskBlip(); setWorkPrompt(false) end
end)
