-- ===========================================================================
--  rpg-world — elimina NPC-urile ambientale si vehiculele lor (trafic)
--  Nativele sunt CLIENT-side -> ruleaza pe fiecare client conectat.
--
--  DE CE nu era suficient inainte: budget=0 + range-multiplier=0 opresc doar
--  SPAWN-URI NOI -> orice ped/vehicul aparut INAINTE (la loading, la teleport,
--  etc.) ramanea pe loc, complet vizibil/solid. Acum, pe langa asta, un thread
--  separat STERGE ACTIV orice ped/vehicul ambiental deja aparut prin GetGamePool.
--
--  Ambientalele din GTA sunt NELEGATE de retea (NetworkGetEntityIsNetworked = false)
--  -> le putem sterge local, pe fiecare client, fara sa afectam alti playeri,
--  vehiculele lor, sau entitati scriptate (ex. masina de test de la Driving School).
-- ===========================================================================

-- ---- 1) opreste SPAWN-URILE NOI (trebuie apelat FIECARE FRAME ca sa tina) ----
CreateThread(function()
    while true do
        Wait(0)

        if Config.Population.removePeds then
            SetPedPopulationBudget(0)
            SetPedDensityMultiplierThisFrame(0.0)
            SetAmbientPedRangeMultiplierThisFrame(0.0)
            SetScenarioPedDensityMultiplierThisFrame(0.0, 0.0)   -- peds din scenarii (stau pe banca, plimba cainele etc.)
        end

        if Config.Population.removeAmbientVehicles then
            SetVehiclePopulationBudget(0)
            SetVehicleDensityMultiplierThisFrame(0.0)
            SetRandomVehicleDensityMultiplierThisFrame(0.0)
            SetAmbientVehicleRangeMultiplierThisFrame(0.0)
            SetGarbageTrucks(false)
        end

        if Config.Population.removeParkedVehicles then
            SetParkedVehicleDensityMultiplierThisFrame(0.0)
        end

        if Config.Population.removeTrains then SetRandomTrains(false) end
        if Config.Population.removeBoats  then SetRandomBoats(false)  end
    end
end)

-- ---- 2) sterge ACTIV ce a apucat deja sa apara -------------------------
local function purge(entity)
    if not DoesEntityExist(entity) then return end
    SetEntityAsMissionEntity(entity, true, true)   -- preia ownership de la sistemul de populatie
    DeleteEntity(entity)
end

CreateThread(function()
    while true do
        Wait(500)

        -- VEHICULE intai (cat inca au sofer -> se clasifica corect "trafic" vs "parcata")
        if Config.Population.removeAmbientVehicles or Config.Population.removeParkedVehicles then
            for _, veh in ipairs(GetGamePool('CVehicle')) do
                if DoesEntityExist(veh) and not NetworkGetEntityIsNetworked(veh) then
                    local driver = GetPedInVehicleSeat(veh, -1)
                    local hasDriver = driver ~= 0 and DoesEntityExist(driver)
                    if hasDriver and Config.Population.removeAmbientVehicles then
                        purge(veh)
                    elseif not hasDriver and Config.Population.removeParkedVehicles then
                        purge(veh)
                    end
                end
            end
        end

        -- PEDS (pietoni ambientali; excludem playerii si orice e legat de retea)
        if Config.Population.removePeds then
            for _, ped in ipairs(GetGamePool('CPed')) do
                if DoesEntityExist(ped) and not IsPedAPlayer(ped) and not NetworkGetEntityIsNetworked(ped) then
                    purge(ped)
                end
            end
        end
    end
end)
