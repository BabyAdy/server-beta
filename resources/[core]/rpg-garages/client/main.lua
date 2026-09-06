-- ===========================================================================
--  rpg-garages — client / core
--  Stare partajata, sync garage-uri, focus NUI, punte NUI <-> server.
-- ===========================================================================

GG = GG or {}
GG.garages    = {}     -- [id] = { id, type, x, y, z, h }
GG.near       = nil    -- garage-ul curent in raza de prompt (id) sau nil
GG.nearType   = nil
GG.nearDealer = nil    -- index dealer curent in raza sau nil
GG.uiOpen     = false   -- lista de vehicule / catalog deschis
GG.promptState = 'hide' -- 'hide' | 'access' | 'park'

-- ---- NUI focus ----------------------------------------------------------
local function openUI(msg)
    GG.uiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage(msg)
end

function GG.closeUI()
    if not GG.uiOpen then return end
    GG.uiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

-- ---- sync garage-uri (boot / create / delete — fara restart) ----------
RegisterNetEvent('rpg-garages:syncGarages', function(list)
    GG.garages = {}
    for _, g in ipairs(list or {}) do GG.garages[g.id] = g end
    TriggerEvent('rpg-garages:_garagesUpdated')   -- garage.lua reface blip-urile
end)

-- ---- deschidere UI de la server -------------------------------------
RegisterNetEvent('rpg-garages:showList', function(data)
    openUI({ action = 'openGarage', data = data })
end)

RegisterNetEvent('rpg-garages:showCatalog', function(data)
    openUI({ action = 'openDealer', data = data })
end)

RegisterNetEvent('rpg-garages:vehiclesChanged', function()
    if GG.uiOpen and GG.near then
        TriggerServerEvent('rpg-garages:requestList', GG.near)   -- re-cere lista in UI
    end
end)

RegisterNetEvent('rpg-garages:bought', function(info)
    -- ramanem in catalog; UI-ul afiseaza un toast
    SendNUIMessage({ action = 'toast', kind = 'ok', text = ('Ai cumpărat %s.'):format(info and info.name or 'vehicul') })
end)

-- ---- NUI callbacks ------------------------------------------------
RegisterNUICallback('close', function(_, cb)
    GG.closeUI()
    cb('ok')
end)

RegisterNUICallback('spawn', function(data, cb)
    local pvId = tonumber(data and data.pvId)
    if pvId and GG.near then
        -- NUI ramane deschis in stare "SPAWNING..." pana raspunde server-ul / clientul.
        TriggerServerEvent('rpg-garages:spawnRequest', pvId, GG.near)
    else
        SendNUIMessage({ action = 'spawnResult', ok = false, text = 'Nu ești la un garage.' })
    end
    cb('ok')
end)

-- rezultat spawn (respingere server-side). Succesul e trimis din client/vehicle.lua
-- dupa ce entitatea a fost creata si confirmata.
RegisterNetEvent('rpg-garages:spawnResult', function(ok, text)
    SendNUIMessage({ action = 'spawnResult', ok = ok == true, text = text })
    if ok == true then GG.closeUI() end
end)

RegisterNUICallback('buy', function(data, cb)
    local model = data and tostring(data.model or '')
    if model ~= '' and GG.nearDealer then
        TriggerServerEvent('rpg-garages:buyRequest', GG.nearDealer, model)
    end
    cb('ok')
end)

-- ESC inchide UI-ul
CreateThread(function()
    while true do
        if GG.uiOpen then
            if IsControlJustReleased(0, 322) then GG.closeUI() end
            Wait(0)
        else
            Wait(250)
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and GG.uiOpen then SetNuiFocus(false, false) end
end)

-- ---- semnaleaza serverului ca suntem gata (restart de resursa) --------
CreateThread(function()
    Wait(500)
    TriggerServerEvent('rpg-garages:clientReady')
end)
