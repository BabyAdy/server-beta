-- ===========================================================================
--  rpg-housing — client
--  Marker 3D ("checkpoint") la fiecare intrare de casă + etichetă NUI care
--  urmărește punctul pe ecran + prompt NUI jos-centru ("E for enter/exit home").
--  Intrare/ieșire: tasta E. Serverul comută virtual world-ul (routing bucket);
--  teleportul efectiv îl face clientul, după confirmare (rpg-housing:setInside).
-- ===========================================================================

local houses = {}          -- [id] = { id, owner, ownerName, price, interiorType, interiorLabel, coords, heading, interiorVw }
local insideHouseId = nil  -- id-ul casei in interiorul careia esti acum (nil = afara)
local nearHouseId = nil    -- id-ul celei mai apropiate case (usa exterioara), cat esti afara
local lastPrompt = nil     -- ultimul text de prompt trimis catre NUI (ca sa nu spamam)

RegisterNetEvent('rpg-housing:sync', function(list)
    houses = {}
    for _, h in ipairs(list or {}) do houses[h.id] = h end
end)

RegisterNetEvent('rpg-housing:houseAdded', function(h)
    if h and h.id then houses[h.id] = h end
end)

-- la (re)pornirea resursei clientul are lista goala -> cere sync de la server
CreateThread(function()
    Wait(400)
    TriggerServerEvent('rpg-housing:requestSync')
end)

local function setPrompt(text)
    if text == lastPrompt then return end
    lastPrompt = text
    SendNUIMessage({ action = 'prompt', text = text })
end

-- --------------------------------------------------- intrare / iesire (E) --
RegisterCommand('rpghousing_interact', function()
    if insideHouseId then
        TriggerServerEvent('rpg-housing:exit', insideHouseId)
    elseif nearHouseId then
        TriggerServerEvent('rpg-housing:enter', nearHouseId)
    end
end, false)
RegisterKeyMapping('rpghousing_interact', 'Intră / Ieși din casă', 'keyboard', 'E')

RegisterNetEvent('rpg-housing:setInside', function(houseId, entering)
    local ped = PlayerPedId()
    local h = houses[houseId]

    if entering then
        insideHouseId = houseId
        if not h then return end
        local def = Config.InteriorTypes[h.interiorType]
        if not def then return end
        local ic = def.coords
        SetEntityCoordsNoOffset(ped, ic.x, ic.y, ic.z, false, false, false)
        SetEntityHeading(ped, ic.w or 0.0)
    else
        insideHouseId = nil
        if not h then return end
        SetEntityCoordsNoOffset(ped, h.coords.x, h.coords.y, h.coords.z, false, false, false)
        SetEntityHeading(ped, h.heading or 0.0)
    end
    setPrompt(nil)   -- ascunde promptul in timpul tranzitiei
end)

-- ---------------------------------------------------------------------------
--  bucla principala: marker (nativ, in lume) + pozitii pt. etichetele NUI
--  + prompt NUI ("E for enter/exit home")
-- ---------------------------------------------------------------------------
CreateThread(function()
    while true do
        local anyNearby = false
        local pcoords = GetEntityCoords(PlayerPedId())
        local visible = {}
        local wantPrompt = nil
        nearHouseId = nil

        if insideHouseId then
            -- inauntru: doar proximitatea de usa interiorului casei curente (range 2.2)
            local h = houses[insideHouseId]
            local def = h and Config.InteriorTypes[h.interiorType]
            if def then
                local ic = def.coords
                if #(pcoords - vector3(ic.x, ic.y, ic.z)) < Config.InteractRadius then
                    anyNearby = true
                    wantPrompt = 'for exit home'
                end
            end
        else
            for id, h in pairs(houses) do
                local dist = #(pcoords - h.coords)
                if dist < Config.LabelRadius then
                    anyNearby = true

                    local m = Config.MarkerColor
                    DrawMarker(1, h.coords.x, h.coords.y, h.coords.z - 0.9, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                        1.6, 1.6, 1.1, m.r, m.g, m.b, m.a, false, false, 2, false, nil, nil, false)

                    local onScreen, sx, sy = GetScreenCoordFromWorldCoord(h.coords.x, h.coords.y, h.coords.z + 1.1)
                    if onScreen then
                        visible[#visible + 1] = {
                            id = id, x = sx, y = sy,
                            houseId = h.id, owner = h.ownerName, price = h.price, interior = h.interiorLabel,
                        }
                    end

                    if dist < Config.InteractRadius then
                        nearHouseId = id
                        wantPrompt = 'for enter home'
                    end
                end
            end
        end

        SendNUIMessage({ action = 'houses', list = visible })
        setPrompt(wantPrompt)
        Wait(anyNearby and 0 or 500)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    SendNUIMessage({ action = 'houses', list = {} })
    SendNUIMessage({ action = 'prompt', text = nil })
end)
