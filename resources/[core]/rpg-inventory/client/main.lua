-- ===========================================================================
--  rpg-inventory — client: open/close, focus, blocare controale.
--  Fara camera de preview / freeze pe personaj -- inventarul doar se deschide
--  (camera + freeze produceau bug-uri cand erai intr-un vehicul: te putea
--  scoate din el sau se putea buguii poziția). Lumea ramane vizibila normal
--  in spatele NUI-ului (panoul de sloturi e semi-transparent).
-- ===========================================================================

Inv = {
    open       = false,
    charLoaded = false,
    snapshot   = nil,
    nearby     = nil,
}

-- ----- deschidere / inchidere ------------------------------------
function Inv.openUI()
    if Inv.open or not Inv.charLoaded then return end
    Inv.open = true

    SetNuiFocus(true, true)

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

    -- carlig pentru rpg-hud (decide singur daca ascunde HUD-ul, dupa config)
    TriggerEvent('hud:inventory', true)
end

function Inv.closeUI()
    if not Inv.open then return end
    Inv.open = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    Inv.request('close', {})
    TriggerEvent('hud:inventory', false)
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
    end
end)
