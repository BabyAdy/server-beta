-- ===========================================================================
--  rpg-doors — CLIENT
--
--  Aplica starea de incuiere primita de la server prin GTA Door System.
--  NU deseneaza NIMIC in lume (fara text3D, fara markere, fara lacate).
--  Meniul NUI (/doors) e singurul loc unde se vede ce usa e incuiata.
-- ===========================================================================

local RES         = GetCurrentResourceName()
local doors       = {}      -- [id] = { id, label, model, x, y, z, heading, locked }
local menuOpen    = false
local pendingScan = nil     -- { model, x, y, z, heading }

-- id unic si stabil pentru Door System, derivat din id-ul din DB
local function dh(id) return GetHashKey(('rpgdoor_%d'):format(id)) end

local function isReg(h)
    local r = IsDoorRegisteredWithSystem(h)
    return r == true or r == 1
end

local function applyDoor(d)
    local h = dh(d.id)
    if not isReg(h) then
        AddDoorToSystem(h, d.model + 0, d.x + 0.0, d.y + 0.0, d.z + 0.0, false, false, false)
    end
    DoorSystemSetDoorState(h, d.locked and 1 or 0, false, false)
    if d.locked then
        DoorSystemSetOpenRatio(h, 0.0, false, false)
    end
    d.applied = true
end

local function unapplyDoor(id)
    local h = dh(id)
    if isReg(h) then
        DoorSystemSetDoorState(h, 0, false, false)
        RemoveDoorFromSystem(h)
    end
end

local function sortedDoors()
    local list = {}
    for _, d in pairs(doors) do list[#list + 1] = d end
    table.sort(list, function(a, b) return a.id < b.id end)
    return list
end

local function reconcile(list)
    local seen = {}
    for _, d in ipairs(list) do
        seen[d.id] = true
        doors[d.id] = d
        applyDoor(d)
    end
    for id in pairs(doors) do
        if not seen[id] then
            unapplyDoor(id)
            doors[id] = nil
        end
    end
    if menuOpen then SendNUIMessage({ action = 'list', doors = sortedDoors() }) end
end

-- ---- server -> client -------------------------------------------
RegisterNetEvent('rpg-doors:sync', function(list)
    reconcile(list or {})
end)

RegisterNetEvent('rpg-doors:removed', function(id)
    id = tonumber(id)
    if id and doors[id] then
        unapplyDoor(id)
        doors[id] = nil
        if menuOpen then SendNUIMessage({ action = 'list', doors = sortedDoors() }) end
    end
end)

RegisterNetEvent('rpg-doors:toast', function(text)
    SendNUIMessage({ action = 'toast', text = text })
end)

-- ---- re-aplica periodic (streaming / alte scripturi pot reseta usa) --
CreateThread(function()
    while true do
        Wait((Config.ReassertSec or 15) * 1000)
        for _, d in pairs(doors) do
            local h = dh(d.id)
            if isReg(h) then
                DoorSystemSetDoorState(h, d.locked and 1 or 0, false, false)
                if d.locked then DoorSystemSetOpenRatio(h, 0.0, false, false) end
            else
                applyDoor(d)
            end
        end
    end
end)

-- ---- meniu NUI -----------------------------------------------
local function canManage()
    local slug = LocalPlayer.state.staff
    return slug ~= nil and slug ~= '' and Staff.atLeast(slug, Config.ManageRank)
end

local function feed(msg)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandThefeedPostTicker(false, true)
end

-- ===========================================================================
--  SELECTARE MANUALA A USII CU CURSORUL
--  Fara detectie automata: intri in "mod selectare", apare cursorul, muti
--  cursorul pe o usa (se contureaza) si dai click ca s-o incui/descui.
-- ===========================================================================
local openMenu, closeMenu   -- definite mai jos (forward declaration pt. startPick)
local pickMode = false
local hoverEnt = 0
local stopPick

local function vnorm(v) local m = #v; if m == 0.0 then return v end return v / m end
local function vcross(a, b)
    return vector3(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x)
end

-- (nx, ny) = pozitia cursorului 0..1 -> ray din camera prin acel punct de ecran
local function screenToWorld(nx, ny, dist)
    local camPos = GetFinalRenderedCamCoord()
    local camRot = GetFinalRenderedCamRot(2)
    local fov    = GetFinalRenderedCamFov()
    local w, h   = GetActiveScreenResolution()
    local aspect = (h > 0) and (w / h) or (16.0 / 9.0)
    local t      = math.tan(math.rad(fov) * 0.5)

    local rz, rx = math.rad(camRot.z), math.rad(camRot.x)
    local cxr = math.abs(math.cos(rx))
    local fwd = vnorm(vector3(-math.sin(rz) * cxr, math.cos(rz) * cxr, math.sin(rx)))
    local right = vnorm(vcross(fwd, vector3(0.0, 0.0, 1.0)))
    local up    = vnorm(vcross(right, fwd))

    local sx = (nx * 2.0) - 1.0
    local sy = 1.0 - (ny * 2.0)
    local dir = vnorm(fwd + right * (sx * t * aspect) + up * (sy * t))
    return camPos, camPos + dir * (dist + 0.0)
end

local function clearHover()
    if hoverEnt ~= 0 and DoesEntityExist(hoverEnt) then SetEntityDrawOutline(hoverEnt, false) end
    hoverEnt = 0
end

-- gaseste usa INREGISTRATA care corespunde obiectului pe care s-a dat click
local function matchRegistered(model, coords)
    local best, bestD
    for _, d in pairs(doors) do
        if (d.model + 0) == (model + 0) then
            local dd = #(coords - vector3(d.x, d.y, d.z))
            if dd <= (Config.PickMatchRadius or 1.5) and (not bestD or dd < bestD) then
                best, bestD = d, dd
            end
        end
    end
    return best
end

local function drawPickHint()
    SetTextFont(4); SetTextScale(0.0, 0.42); SetTextColour(255, 255, 255, 220)
    SetTextCentre(true); SetTextOutline()
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName('Click stânga: comută încuietoarea   •   Click dreapta / ESC: gata')
    EndTextCommandDisplayText(0.5, 0.045)
end

local function startPick()
    if pickMode or not canManage() then return end
    pickMode = true
    CreateThread(function()
        local nextClickAt = 0
        while pickMode do
            Wait(0)
            SetMouseCursorActiveThisFrame()
            -- blocheaza look / atac / pauza cat timp selectezi
            for _, c in ipairs({ 1, 2, 24, 25, 106, 122, 140, 141, 142, 199, 200, 257, 322 }) do
                DisableControlAction(0, c, true)
            end
            drawPickHint()

            local nx, ny = GetControlNormal(0, 239), GetControlNormal(0, 240)
            local from, to = screenToWorld(nx, ny, Config.PickDistance or 14.0)
            local ray = StartExpensiveSynchronousShapeTestLosProbe(
                from.x, from.y, from.z, to.x, to.y, to.z, 16, PlayerPedId(), 7)
            local _, hit, _, _, ent = GetShapeTestResult(ray)

            local valid = hit == 1 and ent and ent ~= 0 and DoesEntityExist(ent) and GetEntityType(ent) == 3
            if valid then
                if ent ~= hoverEnt then
                    clearHover()
                    hoverEnt = ent
                    SetEntityDrawOutline(ent, true)
                    SetEntityDrawOutlineColor(60, 190, 255, 255)
                end
            else
                clearHover()
            end

            -- CLICK STANGA -> selecteaza usa de sub cursor
            if valid and IsDisabledControlJustPressed(0, 24) and GetGameTimer() >= nextClickAt then
                nextClickAt = GetGameTimer() + 350
                local c     = GetEntityCoords(ent)
                local model = GetEntityModel(ent) + 0
                local reg   = matchRegistered(model, c)
                if reg then
                    -- usa deja inregistrata -> comuta incuietoarea, ramai in mod selectare
                    TriggerServerEvent('rpg-doors:setLocked', reg.id, not reg.locked)
                    feed(('Ușa "%s" → %s'):format(reg.label, reg.locked and '~g~descuiată' or '~r~încuiată'))
                else
                    -- usa noua -> iesi din mod selectare si deschide meniul cu casuta de nume
                    local scan = {
                        model = model,
                        x = c.x + 0.0, y = c.y + 0.0, z = c.z + 0.0,
                        heading = GetEntityHeading(ent) + 0.0,
                    }
                    stopPick()
                    openMenu()                 -- openMenu reseteaza pendingScan -> il setam DUPA
                    pendingScan = scan
                    SendNUIMessage({
                        action = 'scanResult', ok = true, model = model,
                        x = math.floor(c.x * 100) / 100,
                        y = math.floor(c.y * 100) / 100,
                        z = math.floor(c.z * 100) / 100,
                    })
                end
            end

            -- ANULARE -> click dreapta / ESC / Backspace
            if IsDisabledControlJustPressed(0, 25) or IsDisabledControlJustPressed(0, 322)
               or IsControlJustPressed(0, 177) or IsControlJustPressed(0, 202) then
                stopPick()
                openMenu()
            end
        end
        clearHover()
    end)
end

stopPick = function() pickMode = false end

openMenu = function()
    if menuOpen then return end
    if not canManage() then
        feed('~r~Nu ai acces la meniul de usi.')
        return
    end
    menuOpen = true
    pendingScan = nil
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', doors = sortedDoors() })
end

closeMenu = function()
    if not menuOpen then return end
    menuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterCommand(Config.OpenCommand, function() openMenu() end, false)
if Config.OpenKey and Config.OpenKey ~= '' then
    RegisterKeyMapping(Config.OpenCommand, 'Deschide meniul de usi', 'keyboard', Config.OpenKey)
end

RegisterNUICallback('close', function(_, cb) closeMenu(); cb('ok') end)

-- NUI: "Selecteaza usa" -> inchide meniul si intra in modul de selectare cu cursorul
RegisterNUICallback('pick', function(_, cb)
    closeMenu()
    startPick()
    cb('ok')
end)

RegisterNUICallback('add', function(data, cb)
    if pendingScan then
        TriggerServerEvent('rpg-doors:add', {
            label   = (data and data.label) or 'Usa',
            model   = pendingScan.model,
            x = pendingScan.x, y = pendingScan.y, z = pendingScan.z,
            heading = pendingScan.heading,
        })
        pendingScan = nil
    end
    cb('ok')
end)

RegisterNUICallback('toggle', function(data, cb)
    local id = tonumber(data and data.id)
    local d  = id and doors[id]
    if d then TriggerServerEvent('rpg-doors:setLocked', id, not d.locked) end
    cb('ok')
end)

RegisterNUICallback('rename', function(data, cb)
    local id = tonumber(data and data.id)
    if id and data and data.label then
        TriggerServerEvent('rpg-doors:rename', id, data.label)
    end
    cb('ok')
end)

RegisterNUICallback('remove', function(data, cb)
    local id = tonumber(data and data.id)
    if id then TriggerServerEvent('rpg-doors:remove', id) end
    cb('ok')
end)

RegisterNUICallback('tp', function(data, cb)
    local id = tonumber(data and data.id)
    local d  = id and doors[id]
    if d then
        local ped = PlayerPedId()
        SetEntityCoords(ped, d.x + 0.0, d.y + 0.0, d.z + 1.0, false, false, false, false)
    end
    cb('ok')
end)

-- ---- lifecycle ---------------------------------------------
AddEventHandler('onResourceStop', function(res)
    if res ~= RES then return end
    pickMode = false
    clearHover()
    if menuOpen then SetNuiFocus(false, false) end
    for id in pairs(doors) do unapplyDoor(id) end
end)

-- (re)start de resursa client-side -> cere lista din nou
CreateThread(function()
    Wait(1500)
    TriggerServerEvent('rpg-doors:requestList')
end)
