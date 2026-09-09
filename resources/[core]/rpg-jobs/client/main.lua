-- ===========================================================================
--  rpg-jobs — CLIENT CORE
--  Stare partajata (JB), focus NUI, punte NUI<->server, toast-uri.
--  `isWorking` e DOAR cosmetic — serverul re-valideaza fiecare actiune.
-- ===========================================================================

JB = JB or {}
JB.job        = Config.Job          -- jobul acestei resurse
JB.hasJob     = false
JB.nearNpc    = false
JB.menuOpen   = false
JB.mgOpen     = false               -- minigame NUI deschis
JB.doneOpen   = false               -- ecranul SHIFT COMPLETE deschis
JB.isWorking  = false               -- cosmetic

-- ---- focus NUI --------------------------------------------------
function JB.setFocus(on)
    SetNuiFocus(on, on)
end

function JB.openMenu()
    if JB.menuOpen or JB.mgOpen then return end
    JB.menuOpen = true
    JB.setFocus(true)
    TriggerServerEvent('rpg-jobs:requestMenu')       -- serverul trimite datele -> NUI se randeaza
end

function JB.closeMenu()
    if not JB.menuOpen then return end
    JB.menuOpen = false
    JB.setFocus(false)
    SendNUIMessage({ action = 'closeMenu' })
end

-- ---- server -> client -----------------------------------------
RegisterNetEvent('rpg-jobs:bootstrap', function(data)
    if data then JB.hasJob = data.hasJob == true end
end)

RegisterNetEvent('rpg-jobs:menuData', function(data)
    JB.hasJob = data.hasJob == true
    JB.isWorking = data.isWorking == true
    if JB.menuOpen then
        SendNUIMessage({ action = 'menu', data = data })
    end
end)

RegisterNetEvent('rpg-jobs:notify', function(text, kind)
    SendNUIMessage({ action = 'toast', text = text, kind = kind or 'info' })
end)

-- ---- NUI callbacks ------------------------------------------
RegisterNUICallback('menuAction', function(data, cb)
    local a = data and data.action
    if a == 'getJob'    then TriggerServerEvent('rpg-jobs:getJob')
    elseif a == 'quitJob'  then TriggerServerEvent('rpg-jobs:quitJob')
    elseif a == 'startWork' then
        JB.closeMenu()
        TriggerServerEvent('rpg-jobs:startWork')
    elseif a == 'close' then
        JB.closeMenu()
    end
    cb('ok')
end)

RegisterNUICallback('closeMenu', function(_, cb)
    JB.closeMenu()
    cb('ok')
end)

-- ESC din meniu / din ecranul SHIFT COMPLETE
CreateThread(function()
    while true do
        if JB.menuOpen or JB.doneOpen then
            if IsControlJustReleased(0, 322) then
                if JB.menuOpen then JB.closeMenu() end
                if JB.doneOpen then
                    JB.doneOpen = false
                    JB.setFocus(false)
                    SendNUIMessage({ action = 'forceCloseDone' })
                end
            end
            Wait(0)
        else
            Wait(300)
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    JB.doneOpen = false
    JB.setFocus(false)
end)

-- /jobcoord — afiseaza in consola (F8) linia vector3(...) gata de copiat in
-- Config.Jobs[1].workLocations. Util cand adaugi checkpoint-uri noi.
RegisterCommand('jobcoord', function()
    local c = GetEntityCoords(PlayerPedId())
    local line = ('vector3(%.2f, %.2f, %.2f),'):format(c.x, c.y, c.z)
    print('[rpg-jobs] checkpoint: ' .. line)
    SendNUIMessage({ action = 'toast', text = 'Checkpoint printed to F8 console.', kind = 'info' })
end, false)
-- JB.hasJob se sincronizeaza prin rpg-jobs:bootstrap (la characterLoaded + la restart de resursa).
