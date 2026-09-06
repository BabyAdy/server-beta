-- ===========================================================================
--  rpg-hud — SPEEDOMETER (100% client-side)
--  GTA Vehicle Natives -> Client -> NUI. Nimic catre server.
-- ===========================================================================

local sp   = { inVeh = false, veh = 0, belted = false, fuelReal = 0 }
local last = {}

local function send(action, value)
    HUD.send({ mod = 'speedo', action = action, value = value })
end

local function resetLast()
    last = { speed = -999, gear = '', rpm = -1, fuel = -1, engineOn = nil, engineHp = -1, belt = nil, lights = -1 }
end

local function gearString(veh)
    if not GetIsVehicleEngineRunning(veh) and GetEntitySpeed(veh) < 0.6 then return 'P' end
    if GetEntitySpeedVector(veh, true).y < -1.0 then return 'R' end
    local g = GetVehicleCurrentGear(veh)
    if g == 0 then return 'N' end
    return tostring(g)
end

local function lightsState(veh)
    local _, lightsOn, highBeams = GetVehicleLightsState(veh)
    if highBeams == 1 then return 2 end
    if lightsOn == 1 then return 1 end
    return 0
end

CreateThread(function()
    resetLast()
    while true do
        local wait = Config.Speedo.idleMs
        local ped = PlayerPedId()

        if IsPedInAnyVehicle(ped, false) then
            local veh = GetVehiclePedIsIn(ped, false)

            if not sp.inVeh or sp.veh ~= veh then
                sp.inVeh, sp.veh = true, veh
                resetLast()
                send('show', true)
            end
            wait = Config.Speedo.updateMs

            local speed = math.floor(GetEntitySpeed(veh) * 3.6 + 0.5)
            if math.abs(speed - last.speed) >= Config.Speedo.speedDelta then
                last.speed = speed
                send('speed', speed)
            end

            local gear = gearString(veh)
            if gear ~= last.gear then last.gear = gear; send('gear', gear) end

            local rpm = math.floor(GetVehicleCurrentRpm(veh) * 100)
            if math.abs(rpm - last.rpm) >= 5 then last.rpm = rpm; send('rpm', rpm) end

            local engineOn = GetIsVehicleEngineRunning(veh)
            local engineHp = math.max(0, math.min(100, math.floor(GetVehicleEngineHealth(veh) / 10)))
            if engineOn ~= last.engineOn or engineHp ~= last.engineHp then
                last.engineOn, last.engineHp = engineOn, engineHp
                send('engine', { on = engineOn, health = engineHp })
            end

            local fuel
            if Config.Speedo.mockFuel then
                fuel = math.max(0, math.min(100, math.floor(GetVehicleFuelLevel(veh) + 0.5)))
            else
                fuel = math.max(0, math.min(100, math.floor(sp.fuelReal + 0.5)))
            end
            if fuel ~= last.fuel then last.fuel = fuel; send('fuel', fuel) end

            if sp.belted ~= last.belt then last.belt = sp.belted; send('seatbelt', sp.belted) end

            local ls = lightsState(veh)
            if ls ~= last.lights then last.lights = ls; send('lights', ls) end
        else
            if sp.inVeh then
                sp.inVeh, sp.veh, sp.belted = false, 0, false
                send('seatbelt', false)
                send('hide', true)
            end
        end

        Wait(wait)
    end
end)

-- ----- seatbelt: DOAR toggle UI + event (fara sistem de gameplay) ----
RegisterCommand('rpgSeatbelt', function()
    if not sp.inVeh then return end
    sp.belted = not sp.belted
    last.belt = nil
    TriggerEvent('vehicle:seatbelt', sp.belted)
    -- pentru un efect real, un sistem separat poate folosi:
    -- SetPedConfigFlag(PlayerPedId(), 32, not sp.belted)  -- eject on crash
end, false)
RegisterKeyMapping('rpgSeatbelt', 'Vehicul: centură', 'keyboard', Config.Speedo.seatbeltKey)

-- ----- API pentru sisteme viitoare (fuel / seatbelt) --------------
RegisterNetEvent('vehicle:setFuel',     function(v) sp.fuelReal = tonumber(v) or 0; last.fuel = -1 end)
RegisterNetEvent('vehicle:setSeatbelt', function(v) sp.belted = v == true; last.belt = nil end)

exports('setFuel',      function(v) sp.fuelReal = tonumber(v) or 0; last.fuel = -1 end)
exports('setSeatbelt',  function(v) sp.belted = v == true; last.belt = nil end)
exports('isSeatbeltOn', function() return sp.belted end)
exports('isInVehicle',  function() return sp.inVeh end)
