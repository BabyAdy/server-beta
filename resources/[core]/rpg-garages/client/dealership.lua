-- ===========================================================================
--  rpg-garages — client / dealership (spec §17)
--  Blip + ped + marker pentru fiecare locatie din Config.Dealers.
--  E -> cere catalogul (server-authoritative) -> UI custom.
-- ===========================================================================

local dealerPeds = {}
local lastE = 0

-- ---- blips + peds (o singura data) ------------------------------------
CreateThread(function()
    for i, d in ipairs(Config.Dealers) do
        if d.blip then
            local h = AddBlipForCoord(d.coords.x, d.coords.y, d.coords.z)
            SetBlipSprite(h, d.blip.sprite or 523)
            SetBlipColour(h, d.blip.color or 3)
            SetBlipScale(h, d.blip.scale or 0.9)
            SetBlipAsShortRange(h, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(d.label)
            EndTextCommandSetBlipName(h)
        end

        if d.ped then
            local hash = GetHashKey(d.ped)
            RequestModel(hash)
            local t0 = GetGameTimer()
            while not HasModelLoaded(hash) and GetGameTimer() - t0 < 8000 do Wait(50) end
            if HasModelLoaded(hash) then
                local ped = CreatePed(4, hash, d.coords.x, d.coords.y, d.coords.z - 1.0, d.heading or 0.0, false, true)
                SetEntityInvincible(ped, true)
                SetBlockingOfNonTemporaryEvents(ped, true)
                FreezeEntityPosition(ped, true)
                TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_CLIPBOARD', 0, true)
                SetModelAsNoLongerNeeded(hash)
                dealerPeds[i] = ped
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, ped in pairs(dealerPeds) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end
end)

-- ---- prompt "DEALERSHIP" + E -----------------------------------------
local dealerPromptOn = false
local function setDealerPrompt(on)
    if dealerPromptOn == on then return end
    dealerPromptOn = on
    if on then
        UI.prompt('dealer')
    elseif GG.promptState == 'hide' then
        -- ascunde doar daca garajul nu afiseaza deja un prompt (garajul are prioritate)
        UI.prompt('hide')
    end
end

CreateThread(function()
    while true do
        local wait = 900
        local pc = GetEntityCoords(PlayerPedId())

        local nIdx, nDist
        for i, d in ipairs(Config.Dealers) do
            local dist = #(pc - d.coords)
            if not nDist or dist < nDist then nIdx, nDist = i, dist end
        end

        if nDist and nDist <= Config.Distance.dealerMark then
            wait = 0
            local d = Config.Dealers[nIdx]
            if d.marker then
                DrawMarker(36, d.coords.x, d.coords.y, d.coords.z + 0.2, 0,0,0, 0,0,0,
                    1.2, 1.2, 1.0, 138, 92, 246, 90, false, false, 2, false, nil, nil, false)
            end

            -- prompt de dealership doar daca NU esti deja langa un garage (garajul are prioritate)
            if nDist <= Config.Distance.dealer and GG.promptState == 'hide' then
                GG.nearDealer = nIdx
                setDealerPrompt(true)
                if not GG.uiOpen and IsControlJustReleased(0, 38) and (GetGameTimer() - lastE) > 500 then
                    lastE = GetGameTimer()
                    TriggerServerEvent('rpg-garages:requestCatalog', nIdx)
                end
            else
                if GG.nearDealer == nIdx then GG.nearDealer = nil end
                setDealerPrompt(false)
            end
        else
            GG.nearDealer = nil
            setDealerPrompt(false)
            wait = (nDist and nDist < 200.0) and 400 or 1500
        end

        Wait(wait)
    end
end)
