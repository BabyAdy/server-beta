-- ===========================================================================
--  rpg-licences — client
--  1) Detecteaza cand devii SOFER/PILOT al unui vehicul restrictionat si cere
--     validare serverului (autoritate). Daca nu ai licenta -> ejectat + text.
--  2) Cat timp weapon_licence_hours == 0, forteaza "unarmed" (nu poti folosi arme).
--  Text central, temporar, NATIV (fara NUI) — nu fura focus/input.
-- ===========================================================================

local myLicences = { driving = 0, weapon = 0, flying = 0, sailing = 0 }

RegisterNetEvent('rpg-licences:sync', function(d)
    d = d or {}
    myLicences = {
        driving = tonumber(d.driving) or 0,
        weapon  = tonumber(d.weapon) or 0,
        flying  = tonumber(d.flying) or 0,
        sailing = tonumber(d.sailing) or 0,
    }
end)

-- ---------------------------------------------------------------- flash --
local flash = { text = nil, untilMs = 0 }
local function showFlash(text)
    flash.text = text
    flash.untilMs = GetGameTimer() + Config.FlashDurationMs
end

CreateThread(function()
    while true do
        if flash.text and GetGameTimer() < flash.untilMs then
            SetTextFont(4)
            SetTextScale(0.5, 0.5)
            SetTextColour(255, 90, 90, 235)
            SetTextOutline()
            SetTextCentre(true)
            SetTextEntry('STRING')
            AddTextComponentString(flash.text)
            DrawText(0.5, 0.42)
            Wait(0)
        else
            flash.text = nil
            Wait(200)
        end
    end
end)

-- ------------------------------------------------------ ejectare instant --
local function ejectFromVehicle(ped)
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then return end
    local coords = GetEntityCoords(ped)
    ClearPedTasksImmediately(ped)
    -- reasezarea coordonatelor unui ped aflat pe scaun il detaseaza instant din vehicul
    SetEntityCoords(ped, coords.x + 1.0, coords.y + 1.0, coords.z, false, false, false, true)
end

RegisterNetEvent('rpg-licences:deny', function(kind)
    ejectFromVehicle(PlayerPedId())
    showFlash(Config.Messages[kind] or "You don't have that licence!")
end)

-- ------------------------------------------- detectare sofer/pilot (poll) --
CreateThread(function()
    local lastVeh = 0
    while true do
        Wait(300)
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local veh = GetVehiclePedIsIn(ped, false)
            if veh ~= lastVeh then
                lastVeh = veh
                if GetPedInVehicleSeat(veh, -1) == ped then   -- doar soferul/pilotul, nu pasagerii
                    TriggerServerEvent('rpg-licences:checkVehicle', GetVehicleClass(veh))
                end
            end
        else
            lastVeh = 0
        end
    end
end)

-- --------------------------------------------------- arme fara licenta --
CreateThread(function()
    local lastWarnAt = 0
    while true do
        Wait(Config.WeaponCheckIntervalMs)
        if myLicences.weapon <= 0 then
            local ped = PlayerPedId()
            local w = GetSelectedPedWeapon(ped)
            if w ~= `WEAPON_UNARMED` then
                SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
                local now = GetGameTimer()
                if now - lastWarnAt > Config.WeaponWarnCooldownMs then
                    lastWarnAt = now
                    showFlash(Config.Messages.weapon)
                end
            end
        end
    end
end)
