-- ===========================================================================
--  rpg-world — NoClip  (F2 / comanda /noclip)
--  Acces: staff cu grad >= Config.NoClip.minRank (vezi rpg-auth/shared/staff.lua)
--  W/S = inainte/inapoi · A/D = stanga/dreapta · Q/E = jos/sus
--  L Shift = cicleaza treapta de viteza
--  UI: bara de taste (NUI, fara focus) jos pe ecran, mereu mov.
--  Vizibilitate: TU te vezi translucid (fantoma); CEILALTI PLAYERI nu te vad deloc.
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

local function pushSpeedToUI()
    SendNUIMessage({ action = 'speed', name = currentTier().name })
end

local function cycleTier()
    tierIdx = tierIdx + 1
    if tierIdx > #Config.NoClip.tiers then tierIdx = 1 end
    pushSpeedToUI()
end

local function setNoclipState(ped, on)
    SetEntityCollision(ped, not on, not on)   -- on=false -> readuce fizica/coliziunea normala
    FreezeEntityPosition(ped, on)
    SetEntityInvincible(ped, on)
    SetPlayerInvincible(PlayerId(), on)
    -- vizibilitatea proprie (translucid) se face din handler-ul de statebag mai jos,
    -- la fel ca la ceilalti clienti -> o singura sursa de adevar (statebag-ul 'noclip').
end

-- ---- toggle: /noclip + F2 -------------------------------------------
RegisterCommand('noclip', function()
    if not isAllowed() then
        TriggerEvent('chat:addMessage', { color = { 255, 90, 90 }, args = { 'NOCLIP', 'Nu ai permisiune.' } })
        return
    end
    active = not active
    setNoclipState(PlayerPedId(), active)
    TriggerServerEvent('rpg-world:noclipToggle', active)   -- sincronizeaza vizibilitatea la ceilalti

    SendNUIMessage({ action = active and 'show' or 'hide' })
    if active then pushSpeedToUI() end
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

            -- vector inainte / dreapta, relativ la camera (yaw + pitch pt. inainte; doar yaw pt. strafe)
            local camRot = GetGameplayCamRot(2)
            local rotZ = math.rad(camRot.z)
            local rotX = math.rad(camRot.x)
            local pitchFactor = math.abs(math.cos(rotX))
            local forward = vector3(-math.sin(rotZ) * pitchFactor, math.cos(rotZ) * pitchFactor, math.sin(rotX))
            local right   = vector3(math.cos(rotZ), math.sin(rotZ), 0.0)

            local move = vector3(0.0, 0.0, 0.0)
            if IsDisabledControlPressed(0, 32) then move = move + forward end   -- W
            if IsDisabledControlPressed(0, 33) then move = move - forward end   -- S
            if IsDisabledControlPressed(0, 35) then move = move + right end     -- D (dreapta)
            if IsDisabledControlPressed(0, 34) then move = move - right end     -- A (stanga)
            if upHeld   then move = move + vector3(0.0, 0.0, 1.0) end           -- E
            if downHeld then move = move - vector3(0.0, 0.0, 1.0) end           -- Q

            if move.x ~= 0.0 or move.y ~= 0.0 or move.z ~= 0.0 then
                local step = Config.NoClip.baseSpeed * currentTier().mult * GetFrameTime()
                local coords = GetEntityCoords(ped)
                local dest = coords + (move * step)
                -- (false,false,false) e conventia deja folosita/verificata in rpg-auth si rpg-characters pt. teleport de ped
                SetEntityCoordsNoOffset(ped, dest.x, dest.y, dest.z, false, false, false)
            end

            SetEntityHeading(ped, camRot.z)
        end
    end
end)

-- ===========================================================================
--  VIZIBILITATE — statebag replicat 'noclip' (setat de server, vezi server/main.lua)
--  Eu (jucatorul in NoClip): raman translucid local (fantoma), nu ma ascund singur.
--  Ceilalti playeri in NoClip: ii ascund complet (SetEntityVisible false) pe clientul MEU.
-- ===========================================================================
local hiddenPlayers = {}   -- [serverId] = true -> pe cine tin ascuns acum

local function applyGhost(on)
    local ped = PlayerPedId()
    if on then
        SetEntityAlpha(ped, 120, false)
    else
        ResetEntityAlpha(ped)
    end
end

local function applyHiddenFor(serverId, hide)
    local p = GetPlayerFromServerId(serverId)
    if p == -1 then return end
    local ped = GetPlayerPed(p)
    if not ped or ped == 0 then return end
    SetEntityVisible(ped, not hide, false)
end

AddStateBagChangeHandler('noclip', '', function(bagName, _, value)
    local id = tonumber(bagName:match('^player:(%d+)$'))
    if not id then return end

    if id == GetPlayerServerId(PlayerId()) then
        applyGhost(value == true)
    else
        if value == true then
            hiddenPlayers[id] = true
            applyHiddenFor(id, true)
        else
            hiddenPlayers[id] = nil
            applyHiddenFor(id, false)
        end
    end
end)

-- reasertare periodica (streaming-ul poate re-crea ped-ul altui player) --
CreateThread(function()
    while true do
        Wait(1000)
        for id in pairs(hiddenPlayers) do
            applyHiddenFor(id, true)
        end
    end
end)

-- ---- oprire resursa cu NoClip inca activ -> restaureaza playerul ------
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if active then
        active = false
        setNoclipState(PlayerPedId(), false)
        applyGhost(false)
        TriggerServerEvent('rpg-world:noclipToggle', false)
    end
end)
