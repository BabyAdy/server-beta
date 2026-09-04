-- ===========================================================================
--  rpg-housing — client
--  Marker 3D la fiecare intrare de casă + etichetă NUI "modernă" (nu text
--  nativ default) care urmărește punctul pe ecran cât timp ești aproape.
-- ===========================================================================

local houses = {}   -- [id] = { id, owner, ownerName, price, interiorType, interiorLabel, coords, heading }

RegisterNetEvent('rpg-housing:sync', function(list)
    houses = {}
    for _, h in ipairs(list or {}) do houses[h.id] = h end
end)

RegisterNetEvent('rpg-housing:houseAdded', function(h)
    if h and h.id then houses[h.id] = h end
end)

-- ---------------------------------------------------------------------------
--  bucla principala: marker (nativ, in lume) + pozitii pt. etichetele NUI
-- ---------------------------------------------------------------------------
CreateThread(function()
    while true do
        local anyNearby = false
        local ped = PlayerPedId()
        local pcoords = GetEntityCoords(ped)
        local visible = {}

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
