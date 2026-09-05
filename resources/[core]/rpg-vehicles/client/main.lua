-- ===========================================================================
--  rpg-vehicles — client
--  /v  -> meniu NUI (Spawn/Despawn/Unstuck/Locate/Lock).
--  Trimite periodic tuning-ul vehiculelor personale spawnate catre server
--  (ca sa fie salvat la ORICE despawn). Aplica lock-ul prin statebag.
-- ===========================================================================

local menuOpen = false
local tracked  = {}   -- [pvId] = { netId, wasInside, lastJson, info = {odometer,days,locked}, odoAccum, lastPos }
local hudPvShown = false   -- daca panoul "vehicul personal" e afisat in speedometer

-- ---------------------------------------------------- /v -> meniu -----------
RegisterCommand('v', function()
    TriggerServerEvent('rpg-vehicles:menu')
end, false)

RegisterNetEvent('rpg-vehicles:openMenu', function(list)
    menuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', vehicles = list or {} })
end)

RegisterNetEvent('rpg-vehicles:refresh', function(list)
    if not menuOpen then return end
    SendNUIMessage({ action = 'refresh', vehicles = list or {} })
end)

RegisterNUICallback('action', function(data, cb)
    if data and data.act and data.id then
        TriggerServerEvent('rpg-vehicles:action', data.act, tonumber(data.id))
    end
    cb('ok')
end)

RegisterNUICallback('close', function(_, cb)
    menuOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

-- ESC inchide
CreateThread(function()
    while true do
        if menuOpen then
            if IsControlJustReleased(0, 322) then
                menuOpen = false
                SetNuiFocus(false, false)
                SendNUIMessage({ action = 'close' })
            end
            Wait(0)
        else
            Wait(250)
        end
    end
end)

-- ---------------------------------------------- locate (waypoint + ruta) ----
RegisterNetEvent('rpg-vehicles:locate', function(x, y)
    SetNewWaypoint(x + 0.0, y + 0.0)
end)

-- ---------------------------------------------- aplica tuning la spawn ------
RegisterNetEvent('rpg-vehicles:applyMods', function(netId, modsJson)
    local tries = 0
    local veh = NetworkGetEntityFromNetworkId(netId)
    while (not veh or veh == 0 or not DoesEntityExist(veh)) and tries < 50 do
        Wait(100)
        veh = NetworkGetEntityFromNetworkId(netId)
        tries = tries + 1
    end
    if not veh or veh == 0 or not DoesEntityExist(veh) then return end

    if type(modsJson) == 'string' and modsJson ~= '' then
        local ok, props = pcall(json.decode, modsJson)
        if ok and type(props) == 'table' then
            VehicleProps.set(veh, props)
        end
    end
end)

-- ---------------------------------------------- track / untrack tuning ------
RegisterNetEvent('rpg-vehicles:track', function(pvId, netId, info)
    tracked[pvId] = {
        netId = netId, wasInside = false, lastJson = '',
        info = type(info) == 'table' and info or {},
        odoAccum = 0.0, lastPos = nil,
    }
end)

RegisterNetEvent('rpg-vehicles:untrack', function(pvId)
    tracked[pvId] = nil
end)

local function hidePvHud()
    if not hudPvShown then return end
    hudPvShown = false
    pcall(function() exports['rpg-hud']:setPersonalVehicle(false) end)
end

local function syncOne(pvId, t, force)
    local veh = NetworkGetEntityFromNetworkId(t.netId)
    -- entitatea poate fi doar "unstreamed" (prea departe), nu neaparat stearsa ->
    -- doar sarim ciclul; untrack-ul autoritar vine de la server (rpg-vehicles:untrack).
    if not veh or veh == 0 or not DoesEntityExist(veh) then return end
    local props = VehicleProps.get(veh)
    if not props then return end
    local encoded = json.encode(props)
    local odo = t.odoAccum or 0.0
    if force or encoded ~= t.lastJson or odo >= 1.0 then
        t.lastJson  = encoded
        t.odoAccum  = 0.0
        TriggerServerEvent('rpg-vehicles:syncMods', pvId, encoded, odo)
    end
end

-- sync periodic al tuning-ului
CreateThread(function()
    while true do
        Wait(Config.ModSyncInterval or 10000)
        for pvId, t in pairs(tracked) do
            syncOne(pvId, t, false)
        end
    end
end)

-- 500ms: acumuleaza kilometrajul cat timp ownerul conduce vehiculul personal,
-- alimenteaza panoul din speedometer si face sync IMEDIAT la iesire (park -> exit -> /dv).
CreateThread(function()
    while true do
        Wait(500)
        if next(tracked) then
            local ped     = PlayerPedId()
            local curVeh   = GetVehiclePedIsIn(ped, false)
            local pedPos   = GetEntityCoords(ped)
            local anyInside = false

            for pvId, t in pairs(tracked) do
                local veh = NetworkGetEntityFromNetworkId(t.netId)
                local inside = (veh ~= 0 and veh == curVeh)

                if inside then
                    anyInside = true
                    -- distanta parcursa de la ultimul tick (ignoram salturile/teleporturile)
                    if t.lastPos then
                        local d = #(pedPos - t.lastPos)
                        if d > 0.05 and d < 120.0 then
                            t.odoAccum = (t.odoAccum or 0.0) + d
                        end
                    end
                    t.lastPos = pedPos

                    -- alimenteaza speedometer-ul (kilometraj live + stare lacat + vechime)
                    local liveKm = (t.info.odometer or 0) + (t.odoAccum or 0.0) / 1000.0
                    local locked = Entity(veh).state.pvLocked
                    if locked == nil then locked = t.info.locked end
                    pcall(function()
                        exports['rpg-hud']:setPersonalVehicle({
                            odometer = liveKm,
                            locked   = locked and true or false,
                            days     = t.info.days or 0,
                        })
                    end)
                    hudPvShown = true
                else
                    t.lastPos = nil
                end

                if t.wasInside and not inside then
                    syncOne(pvId, t, true)   -- a iesit -> salveaza acum (tuning + km)
                end
                t.wasInside = inside
            end

            if not anyInside then hidePvHud() end
        elseif hudPvShown then
            hidePvHud()
        end
    end
end)

-- ---------------------------------------------- lock (statebag global) -----
local function applyLockTo(netId, locked)
    local veh = NetworkGetEntityFromNetworkId(netId)
    if not veh or veh == 0 or not DoesEntityExist(veh) then return end
    SetVehicleDoorsLocked(veh, locked and 2 or 1)
    SetVehicleDoorsLockedForAllPlayers(veh, locked and true or false)
end

AddStateBagChangeHandler('pvLocked', '', function(bagName, _, value)
    local netId = tonumber(bagName:match('entity:(%d+)'))
    if not netId then return end
    applyLockTo(netId, value == true)
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and menuOpen then
        SetNuiFocus(false, false)
    end
end)
