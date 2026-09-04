-- ===========================================================================
--  rpg-world — NoClip  (F2 / comanda /noclip)
--  Acces: staff cu grad >= Config.NoClip.minRank (vezi rpg-auth/shared/staff.lua)
--  Q/E = sus/jos (comenzi separate +/-, rebindabile) · W/S = inainte/inapoi
--  L Shift = cicleaza treapta de viteza · text de ajutor nativ (fara NUI)
-- ===========================================================================

local active  = false
local tierIdx = Config.NoClip.defaultTier or 3

local function staffRank()
    return (LocalPlayer.state and LocalPlayer.state.staff) or ''
end

local function isAllowed()
    return Staff.level(staffRank()) >= Staff.level(Config.NoClip.minRank)
end

local function currentTier()
    return Config.NoClip.tiers[tierIdx] or Config.NoClip.tiers[1]
end

local function cycleTier()
    tierIdx = tierIdx + 1
    if tierIdx > #Config.NoClip.tiers then tierIdx = 1 end
end

local function drawHint()
    local text = ('F2 - Toggle NoClip | Q/E - Up/Down | W/S - Front / Back | L Shift - Speed %s')
        :format(currentTier().name)
    SetTextFont(4)
    SetTextScale(0.34, 0.34)
    SetTextColour(230, 210, 255, 235)
    SetTextOutline()
    SetTextCentre(true)
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(0.5, 0.04)
end

local function setNoclipState(ped, on)
    SetEntityCollision(ped, not on, not on)   -- on=false -> readuce fizica/coliziunea normala
    FreezeEntityPosition(ped, on)
    SetEntityInvincible(ped, on)
    SetEntityVisible(ped, true, false)
    SetPlayerInvincible(PlayerId(), on)
end

-- ---- toggle: /noclip + F2 -------------------------------------------
RegisterCommand('noclip', function()
    if not isAllowed() then
        TriggerEvent('chat:addMessage', { color = { 255, 90, 90 }, args = { 'NOCLIP', 'Nu ai permisiune.' } })
        return
    end
    active = not active
    setNoclipState(PlayerPedId(), active)
end, false)
RegisterKeyMapping('noclip', 'Toggle NoClip (staff)', 'keyboard', Config.NoClip.toggleKey)

-- ---- Q / E: sus / jos (comenzi +/- separate de sistemul de controale) ----
local upHeld, downHeld = false, false
RegisterCommand('+rpgw_ncup',   function() upHeld = true end,   false)
RegisterCommand('-rpgw_ncup',   function() upHeld = false end,  false)
RegisterCommand('+rpgw_ncdown', function() downHeld = true end, false)
RegisterCommand('-rpgw_ncdown', function() downHeld = false end, false)
RegisterKeyMapping('+rpgw_ncup',   'NoClip: Sus',  'keyboard', Config.NoClip.upKey)
RegisterKeyMapping('+rpgw_ncdown', 'NoClip: Jos',  'keyboard', Config.NoClip.downKey)

-- ---- bucla principala -------------------------------------------------
CreateThread(function()
    while true do
        if not active then
            Wait(250)
        else
            Wait(0)
            local ped = PlayerPedId()

            -- dezactiveaza controalele normale de miscare/actiune cat timp e activ NoClip
            DisableControlAction(0, 30, true)  -- move LR (analog)
            DisableControlAction(0, 31, true)  -- move UD (analog)
            DisableControlAction(0, 32, true)  -- W
            DisableControlAction(0, 33, true)  -- S
            DisableControlAction(0, 34, true)  -- A
            DisableControlAction(0, 35, true)  -- D
            DisableControlAction(0, 21, true)  -- sprint (L Shift - o folosim pt. schimbarea treptei)
            DisableControlAction(0, 22, true)  -- jump
            DisableControlAction(0, 23, true)  -- enter
            DisableControlAction(0, 24, true)  -- attack
            DisableControlAction(0, 25, true)  -- aim
            DisableControlAction(0, 36, true)  -- duck
            DisableControlAction(0, 44, true)  -- cover

            -- L SHIFT (apasare) -> urmatoarea treapta de viteza
            if IsDisabledControlJustPressed(0, 21) then
                cycleTier()
            end

            drawHint()

            -- vector inainte, relativ la camera (yaw + pitch)
            local camRot = GetGameplayCamRot(2)
            local rotZ = math.rad(camRot.z)
            local rotX = math.rad(camRot.x)
            local pitchFactor = math.abs(math.cos(rotX))
            local forward = vector3(-math.sin(rotZ) * pitchFactor, math.cos(rotZ) * pitchFactor, math.sin(rotX))

            local move = vector3(0.0, 0.0, 0.0)
            if IsDisabledControlPressed(0, 32) then move = move + forward end                 -- W
            if IsDisabledControlPressed(0, 33) then move = move - forward end                 -- S
            if upHeld   then move = move + vector3(0.0, 0.0, 1.0) end                         -- E
            if downHeld then move = move - vector3(0.0, 0.0, 1.0) end                         -- Q

            if move.x ~= 0.0 or move.y ~= 0.0 or move.z ~= 0.0 then
                local step = Config.NoClip.baseSpeed * currentTier().mult * GetFrameTime()
                local coords = GetEntityCoords(ped)
                local dest = coords + (move * step)
                SetEntityCoordsNoOffset(ped, dest.x, dest.y, dest.z, true, true, true)
            end

            SetEntityHeading(ped, camRot.z)
        end
    end
end)

-- ---- oprire resursa cu NoClip inca activ -> restaureaza playerul ------
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if active then
        active = false
        setNoclipState(PlayerPedId(), false)
    end
end)
