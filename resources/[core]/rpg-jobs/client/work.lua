-- ===========================================================================
--  rpg-jobs — SHIFT FLOW (client)
--  Primeste task-uri de la server, deseneaza blip/marker/waypoint, detecteaza
--  sosirea (client) si CERE minigame-ul (serverul valideaza distanta + starea).
--  Nu decide nimic despre reward/skill/progres — doar afiseaza.
-- ===========================================================================

local task = nil        -- { index, total, coords }
local taskBlip = nil
local nextSendAt = 0    -- GetGameTimer() minim pentru urmatorul rpg-jobs:reachedTask

local MARKER = { type = 1, r = 246, g = 190, b = 0, a = 130 }

local function clearTaskBlip()
    if taskBlip and DoesBlipExist(taskBlip) then RemoveBlip(taskBlip) end
    taskBlip = nil
end

local function setTask(t)
    task = t
    nextSendAt = 0
    clearTaskBlip()
    if not t then return end
    local c = vector3(t.x, t.y, t.z)
    taskBlip = AddBlipForCoord(c.x, c.y, c.z)
    SetBlipSprite(taskBlip, JB.job.workBlip and JB.job.workBlip.sprite or 500)
    SetBlipColour(taskBlip, JB.job.workBlip and JB.job.workBlip.color or 5)
    SetBlipScale(taskBlip, JB.job.workBlip and JB.job.workBlip.scale or 0.7)
    SetBlipRoute(taskBlip, true)          -- traseu pe minimap catre urmatorul panou
    SetBlipRouteColour(taskBlip, JB.job.workBlip and JB.job.workBlip.color or 5)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(('Electric Panel %d/%d'):format(t.index, t.total))
    EndTextCommandSetBlipName(taskBlip)
end

-- ---- server -> client (shift) --------------------------------
RegisterNetEvent('rpg-jobs:shiftStarted', function(d)
    JB.isWorking = true
    SendNUIMessage({ action = 'toast', text = ('Shift started — %d panels to repair.'):format(d.total), kind = 'info' })
    SendNUIMessage({ action = 'hud', show = true, index = 0, total = d.total })
end)

RegisterNetEvent('rpg-jobs:task', function(t)
    setTask(t)
    SendNUIMessage({ action = 'hud', show = true, index = t.index - 1, total = t.total })
    SendNUIMessage({ action = 'toast', text = ('Go to electric panel %d/%d.'):format(t.index, t.total), kind = 'info' })
end)

RegisterNetEvent('rpg-jobs:taskDone', function(d)
    clearTaskBlip()
    task = nil
    SendNUIMessage({ action = 'hud', show = true, index = d.index, total = d.total })
    SendNUIMessage({ action = 'toast', text = ('Panel %d/%d repaired.'):format(d.index, d.total), kind = 'success' })
end)

RegisterNetEvent('rpg-jobs:minigameFailed', function(d)
    nextSendAt = GetGameTimer() + (d.retryMs or 2000)   -- respecta cooldown-ul serverului
    SendNUIMessage({ action = 'toast', text = 'Repair failed. Recalibrating…', kind = 'error' })
end)

RegisterNetEvent('rpg-jobs:shiftComplete', function(d)
    JB.isWorking = false
    clearTaskBlip(); task = nil
    SendNUIMessage({ action = 'hud', show = false })
    SendNUIMessage({ action = 'shiftComplete', data = d })
end)

RegisterNetEvent('rpg-jobs:shiftAborted', function(d)
    JB.isWorking = false
    clearTaskBlip(); task = nil
    SendNUIMessage({ action = 'hud', show = false })
    if d and d.reason ~= 'player_cancel' then
        SendNUIMessage({ action = 'toast', text = 'Shift cancelled.', kind = 'error' })
    end
end)

-- ---- detectare sosire + marker ------------------------------
CreateThread(function()
    while true do
        local wait = 500
        if task and not JB.mgOpen then
            wait = 0
            local c = vector3(task.x, task.y, task.z)
            local pc = GetEntityCoords(PlayerPedId())
            local d = #(pc - c)

            if d < 25.0 then
                DrawMarker(MARKER.type, c.x, c.y, c.z - 0.95, 0,0,0, 0,0,0,
                    1.4, 1.4, 1.0, MARKER.r, MARKER.g, MARKER.b, MARKER.a, false, false, 2, false, nil, nil, false)
            end

            if d < (Config.Security.taskRadius - 0.5) and GetGameTimer() >= nextSendAt then
                nextSendAt = GetGameTimer() + 3000   -- re-trimite daca serverul nu raspunde in 3s (packet pierdut)
                TriggerServerEvent('rpg-jobs:reachedTask', task.index)   -- serverul re-verifica distanta + starea
            end
        end
        Wait(wait)
    end
end)

-- /canceljob — abandon voluntar (fara reward). Comanda scurta, nu keybind.
RegisterCommand('canceljob', function()
    if JB.isWorking then TriggerServerEvent('rpg-jobs:cancelWork') end
end, false)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then clearTaskBlip() end
end)
