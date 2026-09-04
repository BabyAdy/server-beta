-- ===========================================================================
--  rpg-level — client
--  /stats -> cere datele de la server -> deschide popup NUI.
--  Clientul nu calculează / nu validează nimic; doar afișează ce trimite serverul.
-- ===========================================================================

local isOpen = false

local function closeStats()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)          -- cursor OFF + controale GTA restaurate
    SendNUIMessage({ action = 'close' })
end

local function openStats(data)
    if isOpen then return end
    isOpen = true
    SetNuiFocus(true, true)            -- cursor activ, se poate interacționa; input GTA suspendat
    SendNUIMessage({ action = 'open', data = data })
end

-- server -> client
RegisterNetEvent('rpg-level:openStats', function(data)
    openStats(data)
end)

-- NUI -> client (butonul X sau tasta ESC din popup)
RegisterNUICallback('close', function(_, cb)
    closeStats()
    cb('ok')
end)

-- comanda
RegisterCommand('stats', function()
    if isOpen then closeStats() return end
    TriggerServerEvent('rpg-level:requestStats')
end, false)

-- ===========================================================================
--  NOTIFICARE PAYDAY  —  toast NUI (fără focus, se închide singur)
-- ===========================================================================
RegisterNetEvent('rpg-level:payday', function(data)
    SendNUIMessage({ action = 'payday', data = data })   -- NU SetNuiFocus: e pasivă
end)

-- ===========================================================================
--  ACTIVE PLAYTIME  —  detecție activitate 100% pe client, raportată la server.
--  Clientul trimite DOAR "activ/inactiv" + fereastra; serverul decide restul.
-- ===========================================================================
local charLoaded = false
local lastPos = nil

AddEventHandler('core:characterSpawned', function() charLoaded = true end)
AddEventHandler('core:characterLoaded',  function() charLoaded = true end)

local function isPlayerActive()
    local ped = PlayerPedId()
    if not ped or ped == 0 or IsEntityDead(ped) then
        lastPos = nil
        return false
    end

    -- ---- în vehicul ----
    if IsPedInAnyVehicle(ped, false) then
        lastPos = nil   -- resetăm trackerul de mers pe jos
        local veh    = GetVehiclePedIsIn(ped, false)
        local speed  = GetEntitySpeed(veh)                 -- m/s
        local driver = GetPedInVehicleSeat(veh, -1)        -- 0 dacă nu e nimeni pe locul șoferului
        local moving = speed >= Config.Activity.minVehicleSpeed

        -- pasager -> activ doar dacă vehiculul se mișcă ȘI are un șofer
        -- șofer   -> activ dacă vehiculul se mișcă
        return moving and (driver == ped or driver ~= 0)
    end

    -- ---- pe jos: distanță parcursă pe fereastra de verificare ----
    local coords = GetEntityCoords(ped)
    local moved  = 0.0
    if lastPos then
        moved = #(coords - vector3(lastPos.x, lastPos.y, lastPos.z))
    end
    lastPos = coords

    -- mersul normal e activitate validă; statul pe loc / animație fără deplasare = inactiv
    return moved >= Config.Activity.minMoveDistance
end

CreateThread(function()
    -- prima poziție de referință (ca primul tick să nu fie fals-inactiv)
    while not charLoaded do Wait(500) end
    lastPos = GetEntityCoords(PlayerPedId())

    while true do
        Wait(Config.Activity.tickSeconds * 1000)
        if charLoaded then
            TriggerServerEvent('rpg-level:activityTick', isPlayerActive(), Config.Activity.tickSeconds)
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and isOpen then
        SetNuiFocus(false, false)
    end
end)
