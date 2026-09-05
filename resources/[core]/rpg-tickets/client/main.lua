-- ===========================================================================
--  rpg-tickets — client
--  Punte NUI <-> server. Nu tine logica de business; doar focus + RPC + push.
-- ===========================================================================

local isOpen   = false
local pending  = {}     -- [reqId] = nui callback
local reqSeq   = 0

-- ---- helperi ---------------------------------------------------------
local function staffRank()
    return (LocalPlayer.state and LocalPlayer.state.staff) or ''
end

local function isStaff()
    return staffRank() ~= ''
end

local function openMenu(which)
    if isOpen then return end
    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', menu = which })
end

local function closeMenu()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

-- ---- RPC: NUI -> client -> server -> client -> NUI callback ----------
RegisterNUICallback('rpc', function(data, cb)
    reqSeq = reqSeq + 1
    local reqId = reqSeq
    pending[reqId] = cb

    TriggerServerEvent('rpg-tickets:request', reqId, tostring(data and data.name or ''), data and data.data or {})

    -- siguranta: nu lasa NUI-ul sa astepte la infinit
    SetTimeout(10000, function()
        local pcb = pending[reqId]
        if pcb then
            pending[reqId] = nil
            pcb({ ok = false, data = { error = 'timeout' } })
        end
    end)
end)

RegisterNetEvent('rpg-tickets:response', function(reqId, ok, payload)
    local cb = pending[reqId]
    if not cb then return end
    pending[reqId] = nil
    cb({ ok = ok == true, data = payload or {} })
end)

-- ---- push server -> NUI (realtime) ---------------------------------
RegisterNetEvent('rpg-tickets:push', function(kind, payload)
    SendNUIMessage({ action = 'push', kind = kind, data = payload or {} })
end)

-- ---- inchidere din NUI (ESC / buton) ------------------------------
RegisterNUICallback('close', function(_, cb)
    closeMenu()
    cb('ok')
end)

-- Haine staff: butoanele din Dashboard cheama RPC-ul 'giveWardrobe' (server),
-- care baga itemul potrivit gradului in inventar. Echiparea o face jucatorul
-- din inventar (rpg-inventory aplica modelul addon male/female).

-- ---- TP / BRING (declansate de server) ---------------------------
RegisterNetEvent('rpg-tickets:tpTo', function(targetServerId)
    local pid = GetPlayerFromServerId(targetServerId)
    if pid == -1 then return end
    local tped = GetPlayerPed(pid)
    if not tped or tped == 0 then return end
    local c = GetEntityCoords(tped)
    local ped = PlayerPedId()
    SetPedCoordsKeepVehicle(ped, c.x + 1.0, c.y + 1.0, c.z)
end)

RegisterNetEvent('rpg-tickets:bringTo', function(staffServerId)
    local pid = GetPlayerFromServerId(staffServerId)
    if pid == -1 then return end
    local sped = GetPlayerPed(pid)
    if not sped or sped == 0 then return end
    local c = GetEntityCoords(sped)
    local ped = PlayerPedId()
    SetPedCoordsKeepVehicle(ped, c.x + 1.0, c.y + 1.0, c.z)
end)

-- ---- COMENZI / KEYBINDS -----------------------------------------
-- /ticket -> meniul de player (si staff-ul il poate folosi pt. tichete proprii)
RegisterCommand(Config.Commands.playerMenu, function()
    openMenu('player')
end, false)

local function openStaff()
    if not isStaff() then
        TriggerEvent('chat:addMessage', { color = { 255, 90, 90 }, args = { 'TICHETE', 'Nu ai permisiune.' } })
        return
    end
    openMenu('staff')
end
RegisterCommand(Config.Commands.staffMenu, openStaff, false)
if Config.Commands.staffMenuAlt and Config.Commands.staffMenuAlt ~= '' then
    RegisterCommand(Config.Commands.staffMenuAlt, openStaff, false)
end

if Config.PlayerMenuKey and Config.PlayerMenuKey ~= '' then
    RegisterKeyMapping(Config.Commands.playerMenu, 'Deschide meniul de tichete', 'keyboard', Config.PlayerMenuKey)
end
if Config.StaffMenuKey and Config.StaffMenuKey ~= '' then
    RegisterKeyMapping(Config.Commands.staffMenu, 'Deschide panoul de tichete (staff)', 'keyboard', Config.StaffMenuKey)
end

-- ESC inchide (in plus fata de callback-ul NUI)
CreateThread(function()
    while true do
        if isOpen then
            if IsControlJustReleased(0, 322) then   -- ESC
                closeMenu()
            end
            Wait(0)
        else
            Wait(250)
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and isOpen then
        SetNuiFocus(false, false)
    end
end)
