-- ===========================================================================
--  rpg-inventory — interactiuni in lume: taste slot rapid, "nearby" live,
--  detectie tras (durabilitate arma -1 / glont).
-- ===========================================================================

-- ----- taste slot rapid (1..5) - active doar cand inventarul e INCHIS ----
for i = 1, Config.FastSlotCount do
    local cmd = ('rpginv_fast%d'):format(i)
    RegisterCommand(cmd, function()
        if Inv.open or not Inv.charLoaded then return end
        Inv.request('useFast', { index = i })
    end, false)

    local key = Config.FastSlotKeys[i]
    if key and key ~= '' then
        RegisterKeyMapping(cmd, ('Slot rapid %d'):format(i), 'keyboard', key)
    end
end

-- ----- "nearby" cat timp inventarul e deschis (event-driven + safety poll) -
CreateThread(function()
    while true do
        if Inv.open then
            Inv.request('scanNearby', {})
            Wait(1500)
        else
            Wait(750)
        end
    end
end)

-- ----- durabilitate arma: -1 la fiecare glont tras -------------------
CreateThread(function()
    local wasShooting = false
    while true do
        local wait = 250
        if Inv.charLoaded and Inv.snapshot then
            local ped = PlayerPedId()
            if IsPedShooting(ped) then
                wait = 0
                if not wasShooting then
                    wasShooting = true
                    -- gaseste itemul arma echipat in grid
                    local slot = nil
                    for s, item in pairs(Inv.snapshot.grid or {}) do
                        if item and item.category == 'weapon' and item.equipped then
                            slot = tonumber(s); break
                        end
                    end
                    if slot then
                        TriggerServerEvent('rpg-inventory:weaponShot', slot, 1)
                    end
                end
            else
                wasShooting = false
            end
        end
        Wait(wait)
    end
end)
