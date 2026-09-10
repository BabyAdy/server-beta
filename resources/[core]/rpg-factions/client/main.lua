-- ===========================================================================
--  rpg-factions — CLIENT CORE
--  Stare (FX), focus NUI, comanda /faction, notificari, invite popup.
--  Nimic "de business" pe client — serverul re-valideaza tot.
-- ===========================================================================

FX = FX or {}
FX.self     = { inFaction = false }   -- ultimul payload rpg-factions:sync
FX.menuOpen = false
FX.pendingInvite = nil                -- { fid, name }

-- ---- focus ----------------------------------------------------
function FX.setFocus(on) SetNuiFocus(on, on) end

-- server id al celui mai apropiat player (in raza), pt. Invite fara a tasta id-ul
function FX.nearestPlayerServerId(radius)
    local me = PlayerId()
    local pc = GetEntityCoords(PlayerPedId())
    local best, bestD
    for _, pi in ipairs(GetActivePlayers()) do
        if pi ~= me then
            local d = #(pc - GetEntityCoords(GetPlayerPed(pi)))
            if d <= (radius or 3.0) and (not bestD or d < bestD) then best, bestD = pi, d end
        end
    end
    return best and GetPlayerServerId(best) or nil
end

function FX.openMenu()
    if FX.menuOpen then return end
    FX.menuOpen = true
    FX.setFocus(true)
    SendNUIMessage({ action = 'open', self = FX.self })
    TriggerServerEvent('rpg-factions:requestSelf')
end

function FX.closeMenu()
    if not FX.menuOpen then return end
    FX.menuOpen = false
    FX.setFocus(false)
    SendNUIMessage({ action = 'close' })
end

-- ---- Faction Creator (admin, /createfaction) --------------
function FX.openCreator(data)
    if FX.menuOpen then FX.closeMenu() end
    FX.menuOpen = 'creator'
    FX.setFocus(true)
    SendNUIMessage({ action = 'openCreator', data = data or {} })
end

function FX.closeCreator()
    if FX.menuOpen ~= 'creator' then return end
    FX.menuOpen = false
    FX.setFocus(false)
    SendNUIMessage({ action = 'creatorClose' })
end

RegisterNetEvent('rpg-factions:openCreator', function(data) FX.openCreator(data) end)

-- ---- server -> client --------------------------------------
RegisterNetEvent('rpg-factions:sync', function(payload)
    FX.self = payload or { inFaction = false }
    local st = LocalPlayer.state
    if FX.menuOpen then SendNUIMessage({ action = 'self', self = FX.self }) end
    TriggerEvent('rpg-factions:_selfChanged')
end)

RegisterNetEvent('rpg-factions:notify', function(text, kind)
    SendNUIMessage({ action = 'toast', text = text, kind = kind or 'info' })
end)

RegisterNetEvent('rpg-factions:invited', function(data)
    FX.pendingInvite = data
    SendNUIMessage({ action = 'invite', data = data })
    if not FX.menuOpen then FX.setFocus(true); FX.menuOpen = 'invite' end
end)

-- ---- comanda + keybind -----------------------------------
RegisterCommand(Config.Command, function() FX.openMenu() end, false)
if Config.Keybind ~= '' then
    RegisterKeyMapping(Config.Command, 'Open faction menu', 'keyboard', Config.Keybind)
end

-- ESC
CreateThread(function()
    while true do
        if FX.menuOpen then
            if IsControlJustReleased(0, 322) then
                if FX.menuOpen == 'invite' then
                    SendNUIMessage({ action = 'invite', data = nil }); FX.pendingInvite = nil; FX.setFocus(false); FX.menuOpen = false
                elseif FX.menuOpen == 'creator' then
                    FX.closeCreator()
                else
                    FX.closeMenu()
                end
            end
            Wait(0)
        else
            Wait(300)
        end
    end
end)

CreateThread(function() Wait(700); TriggerServerEvent('rpg-factions:clientReady') end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then FX.setFocus(false) end
end)
