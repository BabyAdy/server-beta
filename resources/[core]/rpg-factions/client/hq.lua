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

-- culoarea facțiunii (#RRGGBB) -> r,g,b pentru marker
local function hexRGB(hex)
    hex = tostring(hex or ''):gsub('#', '')
    return tonumber(hex:sub(1, 2), 16) or 90,
           tonumber(hex:sub(3, 4), 16) or 120,
           tonumber(hex:sub(5, 6), 16) or 240
end

-- checkpoint vizibil (cilindru) la un punct HQ
local function drawCheckpoint(pt, r, g, b)
    DrawMarker(1, pt.x + 0.0, pt.y + 0.0, pt.z - 0.98, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        1.5, 1.5, 0.5, r, g, b, 130, false, false, 2, false, nil, nil, false)
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
            local r, g, b = hexRGB(FX.self.faction.color)

            local pt = (not inHQ) and hq.enter or (inHQ and hq.leave) or nil
            if pt then
                local dist = #(pc - vector3(pt.x, pt.y, pt.z))
                if dist < 18.0 then
                    wait = 0
                    drawCheckpoint(pt, r, g, b)               -- checkpoint vizibil
                    if dist < 2.2 then near = (not inHQ) and 'enter' or 'leave' end
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
