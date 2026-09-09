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

-- ---- raycast: gaseste usa din fata ----------------------------
local function rotToDir(rot)
    local z = math.rad(rot.z)
    local x = math.rad(rot.x)
    local n = math.abs(math.cos(x))
    return vector3(-math.sin(z) * n, math.cos(z) * n, math.sin(x))
end

local function scanDoor()
    local cam  = GetGameplayCamCoord()
    local dir  = rotToDir(GetGameplayCamRot(2))
    local dest = cam + dir * ((Config.RayDistance or 8.0) + 0.0)
    local ray  = StartExpensiveSynchronousShapeTestLosProbe(
        cam.x, cam.y, cam.z, dest.x, dest.y, dest.z, 16, PlayerPedId(), 7)
    local _, hit, _, _, ent = GetShapeTestResult(ray)
    if hit ~= 1 or not ent or ent == 0 or not DoesEntityExist(ent) then return nil end
    if GetEntityType(ent) ~= 3 then return nil end   -- 3 = obiect (usile sunt obiecte)
    local c = GetEntityCoords(ent)
    return {
        model   = GetEntityModel(ent) + 0,
        x = c.x + 0.0, y = c.y + 0.0, z = c.z + 0.0,
        heading = GetEntityHeading(ent) + 0.0,
    }
end

-- ---- meniu NUI -----------------------------------------------
local function canManage()
    local slug = LocalPlayer.state.staff
    return slug ~= nil and slug ~= '' and Staff.atLeast(slug, Config.ManageRank)
end

local function openMenu()
    if menuOpen then return end
    if not canManage() then
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName('~r~Nu ai acces la meniul de usi.')
        EndTextCommandThefeedPostTicker(false, true)
        return
    end
    menuOpen = true
    pendingScan = nil
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', doors = sortedDoors() })
end

local function closeMenu()
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

RegisterNUICallback('scan', function(_, cb)
    local s = scanDoor()
    pendingScan = s
    if s then
        SendNUIMessage({
            action = 'scanResult', ok = true, model = s.model,
            x = math.floor(s.x * 100) / 100,
            y = math.floor(s.y * 100) / 100,
            z = math.floor(s.z * 100) / 100,
        })
    else
        SendNUIMessage({ action = 'scanResult', ok = false })
    end
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
    if menuOpen then SetNuiFocus(false, false) end
    for id in pairs(doors) do unapplyDoor(id) end
end)

-- (re)start de resursa client-side -> cere lista din nou
CreateThread(function()
    Wait(1500)
    TriggerServerEvent('rpg-doors:requestList')
end)
