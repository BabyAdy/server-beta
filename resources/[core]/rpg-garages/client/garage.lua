-- ===========================================================================
--  rpg-garages — client / garage
--  Blip-uri permanente (spec §10), marker/checkpoint 3D custom afisat DOAR
--  in raza (spec §11), prompt "GARAGE ACCESS" / "GARAGE PARK" (spec §12/§13),
--  interactiune E. Bucla optimizata (Wait dinamic, fara UI cand esti departe).
-- ===========================================================================

local blips = {}
local lastE = 0

-- ---- blip-uri (spec §10) --------------------------------------------
local function clearBlips()
    for _, h in pairs(blips) do if DoesBlipExist(h) then RemoveBlip(h) end end
    blips = {}
end

local function rebuildBlips()
    clearBlips()
    for id, g in pairs(GG.garages) do
        local cfg = Config.Blip[g.type] or Config.Blip.Vehicle
        local h = AddBlipForCoord(g.x, g.y, g.z)
        SetBlipSprite(h, cfg.sprite)
        SetBlipColour(h, cfg.color)
        SetBlipScale(h, cfg.scale)
        SetBlipAsShortRange(h, Config.Blip.shortRange ~= false)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(('Garage #%d'):format(id))
        EndTextCommandSetBlipName(h)
        blips[id] = h
    end
end

AddEventHandler('rpg-garages:_garagesUpdated', rebuildBlips)
AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then clearBlips() end
end)

-- ---- text 3D -------------------------------------------------------
local function drawText3D(x, y, z, text)
    SetDrawOrigin(x, y, z, 0)
    SetTextScale(0.0, 0.34)
    SetTextFont(4)
    SetTextColour(236, 233, 245, 220)
    SetTextCentre(true)
    SetTextOutline()
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

-- ---- prompt (NUI, jos-centru) ------------------------------------
local function setPrompt(kind)
    if GG.promptState == kind then return end
    GG.promptState = kind
    UI.prompt(kind)   -- 'access' | 'park' | 'hide'
end

-- vehiculul curent e unul personal urmarit de client?
local function inOwnPersonalVehicle()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then return false, 0 end
    if GG.entityToPv and GG.entityToPv[veh] then return true, veh end
    -- fallback pe statebag (setat la spawn)
    local st = Entity(veh).state
    if st and st.pvId then return true, veh end
    return false, veh
end

-- ---- bucla principala ------------------------------------------
CreateThread(function()
    while true do
        local wait = 900
        local hasGarages = next(GG.garages) ~= nil

        if hasGarages then
            local ped = PlayerPedId()
            local pc  = GetEntityCoords(ped)

            local nearestId, nearestDist, nearestG
            for id, g in pairs(GG.garages) do
                local d = #(pc - vector3(g.x, g.y, g.z))
                if not nearestDist or d < nearestDist then
                    nearestId, nearestDist, nearestG = id, d, g
                end
            end

            if nearestDist and nearestDist <= Config.Distance.scan then
                wait = 0

                -- marker + text 3D pt. TOATE garage-urile din raza de marker
                for id, g in pairs(GG.garages) do
                    if #(pc - vector3(g.x, g.y, g.z)) <= Config.Distance.marker then
                        local m = Config.Marker
                        DrawMarker(m.type, g.x, g.y, g.z - 0.9, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                            m.size.x, m.size.y, m.size.z,
                            m.rgba[1], m.rgba[2], m.rgba[3], m.rgba[4],
                            m.bob == true, false, 2, m.rotate == true, nil, nil, false)
                        drawText3D(g.x, g.y, g.z + 0.9, ('GARAGE #%d  ·  %s'):format(id, g.type))
                    end
                end

                -- prompt (doar pt. garage-ul cel mai apropiat, in raza de prompt)
                if nearestDist <= Config.Distance.prompt then
                    GG.near, GG.nearType = nearestId, nearestG.type

                    if GG.uiOpen then
                        setPrompt('hide')   -- nu suprapune prompt-ul peste UI, dar pastreaza GG.near
                    else
                        local isOwn, veh = inOwnPersonalVehicle()
                        local want = 'access'
                        if isOwn and veh ~= 0 then
                            local myType = Utils.garageTypeFromClass(GetVehicleClass(veh))
                            want = (myType == nearestG.type) and 'park' or 'hide'
                        end
                        setPrompt(want)

                        if IsControlJustReleased(0, 38) and (GetGameTimer() - lastE) > 500 then
                            lastE = GetGameTimer()
                            if want == 'park' then
                                TriggerServerEvent('rpg-garages:parkRequest', GG.near)
                            elseif want == 'access' then
                                TriggerServerEvent('rpg-garages:requestList', GG.near)
                            end
                        end
                    end
                else
                    GG.near, GG.nearType = nil, nil
                    setPrompt('hide')
                end
            else
                GG.near, GG.nearType = nil, nil
                setPrompt('hide')
                -- cat de des re-verificam depinde de cat de departe suntem
                wait = (nearestDist and nearestDist < 150.0) and 400 or 1200
            end
        end

        Wait(wait)
    end
end)
