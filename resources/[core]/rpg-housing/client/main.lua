-- ===========================================================================
--  rpg-housing — client
--  Marker 3D la fiecare intrare de casă + etichetă NUI "modernă" (nu text
--  nativ default) care urmărește punctul pe ecran cât timp ești aproape.
--  Intrare/ieșire: tasta E — la ușa exterioară intri în interior (bob74_ipl
--  încarcă deja toate interioarele la boot, deci nu mai trebuie activat nimic);
--  la ușa efectivă a interiorului (același punct din Config.InteriorTypes),
--  E te scoate înapoi exact la intrarea casei (unde a fost creată cu /createhouse).
-- ===========================================================================

local houses = {}          -- [id] = { id, owner, ownerName, price, interiorType, interiorLabel, coords, heading }
local insideHouseId = nil  -- id-ul casei in interiorul careia esti acum (nil = afara)
local nearHouseId = nil    -- id-ul celei mai apropiate case (usa exterioara), cat esti afara

RegisterNetEvent('rpg-housing:sync', function(list)
    houses = {}
    for _, h in ipairs(list or {}) do houses[h.id] = h end
end)

RegisterNetEvent('rpg-housing:houseAdded', function(h)
    if h and h.id then houses[h.id] = h end
end)

-- --------------------------------------------------------------- text3D --
local function drawText3D(coords, text)
    local onScreen, sx, sy = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)
    if not onScreen then return end
    SetTextScale(0.34, 0.34)
    SetTextFont(4)
    SetTextColour(255, 255, 255, 215)
    SetTextOutline()
    SetTextCentre(true)
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(sx, sy)
end

-- --------------------------------------------------- intrare / iesire (E) --
RegisterCommand('rpghousing_interact', function()
    local ped = PlayerPedId()

    if insideHouseId then
        local h = houses[insideHouseId]
        insideHouseId = nil
        if not h then return end
        SetEntityCoordsNoOffset(ped, h.coords.x, h.coords.y, h.coords.z, false, false, false)
        SetEntityHeading(ped, h.heading or 0.0)
        return
    end

    if nearHouseId then
        local h = houses[nearHouseId]
        local def = h and Config.InteriorTypes[h.interiorType]
        if not def then return end
        local ic = def.coords
        SetEntityCoordsNoOffset(ped, ic.x, ic.y, ic.z, false, false, false)
        SetEntityHeading(ped, ic.w or 0.0)
        insideHouseId = nearHouseId
    end
end, false)
RegisterKeyMapping('rpghousing_interact', 'Intră / Ieși din casă', 'keyboard', 'E')

-- ---------------------------------------------------------------------------
--  bucla principala: marker (nativ, in lume) + pozitii pt. etichetele NUI
--  + prompt-urile [E] de intrare/iesire
-- ---------------------------------------------------------------------------
CreateThread(function()
    while true do
        local anyNearby = false
        local ped = PlayerPedId()
        local pcoords = GetEntityCoords(ped)
        local visible = {}
        nearHouseId = nil

        if insideHouseId then
            -- inauntru: verificam DOAR proximitatea de usa interiorului casei curente
            local h = houses[insideHouseId]
            local def = h and Config.InteriorTypes[h.interiorType]
            if def then
                local ic = def.coords
                local dist = #(pcoords - vector3(ic.x, ic.y, ic.z))
                if dist < Config.InteractRadius then
                    anyNearby = true
                    drawText3D(vector3(ic.x, ic.y, ic.z + 1.0), '[E] Ieși din casă')
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
                        drawText3D(h.coords + vector3(0.0, 0.0, 1.9), '[E] Intră în casă')
                    end
                end
            end
        end

        SendNUIMessage({ action = 'houses', list = visible })
        Wait(anyNearby and 0 or 500)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    SendNUIMessage({ action = 'houses', list = {} })
end)
