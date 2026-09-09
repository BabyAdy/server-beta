-- ===========================================================================
--  rpg-factions — HQ (client)  §24
--  Proximitate fata de punctele HQ ale PROPRIEI facțiuni (din payload-ul sync):
--    - hq.enter = usa EXTERIOARA -> "[E] Enter HQ"
--    - hq.leave = punctul INTERIOR -> "[E] Leave HQ"  (afisat cand esti in bucket)
--  Teleportul + routing bucket-ul le face SERVERUL (rpg-factions:hqEnter/Leave);
--  clientul doar deseneaza prompt-ul, apasa E, si aplica pozitia primita.
-- ===========================================================================

local inHQ = false
local promptState = nil   -- 'enter' | 'leave' | nil

local function setPrompt(kind)
    if promptState == kind then return end
    promptState = kind
    SendNUIMessage({ action = 'hqPrompt', kind = kind })   -- 'enter' | 'leave' | nil
end

RegisterNetEvent('rpg-factions:hqTeleport', function(pos, dir)
    if type(pos) ~= 'table' then return end
    inHQ = (dir == 'in')
    local ped = PlayerPedId()
    DoScreenFadeOut(250); Wait(260)
    SetEntityCoordsNoOffset(ped, pos.x + 0.0, pos.y + 0.0, pos.z + 0.0, false, false, false)
    SetEntityHeading(ped, (pos.h or 0.0) + 0.0)
    Wait(120); DoScreenFadeIn(350)
end)

AddEventHandler('rpg-factions:_selfChanged', function()
    if not (FX.self and FX.self.inFaction and FX.self.faction and FX.self.faction.hq
            and FX.self.faction.hq.vw and FX.self.faction.hq.vw ~= 0) then
        -- iesit din facțiune / fara HQ -> curata
        setPrompt(nil)
    end
end)

CreateThread(function()
    while true do
        local wait = 900
        local hq = FX.self and FX.self.inFaction and FX.self.faction and FX.self.faction.hq or nil
        if hq and hq.vw and hq.vw ~= 0 then
            local pc = GetEntityCoords(PlayerPedId())
            local near = nil

            if not inHQ and hq.enter then
                if #(pc - vector3(hq.enter.x, hq.enter.y, hq.enter.z)) < 12.0 then
                    wait = 0
                    if #(pc - vector3(hq.enter.x, hq.enter.y, hq.enter.z)) < 2.2 then near = 'enter' end
                end
            elseif inHQ and hq.leave then
                if #(pc - vector3(hq.leave.x, hq.leave.y, hq.leave.z)) < 12.0 then
                    wait = 0
                    if #(pc - vector3(hq.leave.x, hq.leave.y, hq.leave.z)) < 2.2 then near = 'leave' end
                end
            end

            setPrompt(near)
            if near and not FX.menuOpen and IsControlJustReleased(0, 38) then   -- E
                if near == 'enter' then TriggerServerEvent('rpg-factions:hqEnter')
                else TriggerServerEvent('rpg-factions:hqLeave') end
            end
        else
            setPrompt(nil)
        end
        Wait(wait)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then setPrompt(nil) end
end)
