-- ===========================================================================
--  rpg-inventory — client: open/close, focus, blocare controale, camera preview.
--  Lumea din spate ramane vizibila (overlay semi-transparent in NUI).
-- ===========================================================================

Inv = {
    open       = false,
    charLoaded = false,
    snapshot   = nil,
    nearby     = nil,
    cam        = nil,
}

-- ----- camera preview personaj -------------------------------------
local function openCam()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local rad = math.rad(heading)
    local fwdX, fwdY = -math.sin(rad), math.cos(rad)
    local rightX, rightY = math.cos(rad), math.sin(rad)
    local p = Config.Preview

    local px = coords.x + fwdX * p.forward + rightX * p.side
    local py = coords.y + fwdY * p.forward + rightY * p.side
    local pz = coords.z + p.height

    Inv.cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', px, py, pz, 0.0, 0.0, 0.0, p.fov, false, 0)
    PointCamAtCoord(Inv.cam, coords.x + rightX * (p.side * 1.2), coords.y + rightY * (p.side * 1.2), coords.z + p.height)
    SetCamActive(Inv.cam, true)
    RenderScriptCams(true, true, 350, true, false)
end

local function closeCam()
    if Inv.cam then
        RenderScriptCams(false, true, 350, true, false)
        DestroyCam(Inv.cam, false)
        Inv.cam = nil
    end
end

-- ----- deschidere / inchidere ------------------------------------
function Inv.openUI()
    if Inv.open or not Inv.charLoaded then return end
    Inv.open = true

    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)
    SetNuiFocus(true, true)
    openCam()

    SendNUIMessage({
        action = 'open',
        config = {
            grid       = Config.Grid,
            nearby     = Config.Nearby,
            fastCount  = Config.FastSlotCount,
            equipment  = Config.EquipmentSlots,
            dropConfirm = Config.DropConfirm,
        },
    })

    -- cere datele proaspete
    Inv.request('open', {})
    Inv.request('scanNearby', {})
end

function Inv.closeUI()
    if not Inv.open then return end
    Inv.open = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    closeCam()
    FreezeEntityPosition(PlayerPedId(), false)
    Inv.request('close', {})
end

function Inv.toggle()
    if Inv.open then Inv.closeUI() else Inv.openUI() end
end

-- ----- push-uri de la server -----------------------------------
RegisterNetEvent('rpg-inventory:sync', function(snapshot)
    Inv.snapshot = snapshot
    if Inv.open then SendNUIMessage({ action = 'sync', snapshot = snapshot }) end
end)

RegisterNetEvent('rpg-inventory:nearby', function(nearby)
    Inv.nearby = nearby
    if Inv.open then SendNUIMessage({ action = 'nearby', nearby = nearby }) end
end)

-- ----- stare personaj ----------------------------------------
AddEventHandler('core:characterSpawned', function()
    Inv.charLoaded = true
end)
AddEventHandler('core:characterLoaded', function()
    Inv.charLoaded = true
end)

-- ----- comanda + keybind (configurabil) --------------------
RegisterCommand(Config.OpenCommand, function()
    Inv.toggle()
end, false)

if Config.DefaultKey ~= '' then
    RegisterKeyMapping(Config.OpenCommand, 'Deschide inventarul', 'keyboard', Config.DefaultKey)
end

-- ----- blocare controale cat timp e deschis ----------------
CreateThread(function()
    while true do
        if Inv.open then
            DisableAllControlActions(0)
            EnableControlAction(0, 1, true)   -- look X
            EnableControlAction(0, 2, true)   -- look Y
            EnableControlAction(0, 245, true) -- chat
            HideHudComponentThisFrame(19)     -- weapon wheel
            Wait(0)
        else
            Wait(500)
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and Inv.open then
        SetNuiFocus(false, false)
        closeCam()
        FreezeEntityPosition(PlayerPedId(), false)
    end
end)
