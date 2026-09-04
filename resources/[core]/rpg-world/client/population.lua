-- ===========================================================================
--  rpg-world — elimina NPC-urile ambientale si vehiculele lor (trafic)
--  Nativele sunt CLIENT-side -> ruleaza pe fiecare client conectat, in bucla
--  (unele valori se reseteaza in fiecare frame de catre joc, de-asta "ThisFrame").
-- ===========================================================================

CreateThread(function()
    while true do
        Wait(0)

        if Config.Population.removePeds then
            SetPedPopulationBudget(0)                      -- 0 = niciun ped ambiental nou
            SetAmbientPedRangeMultiplierThisFrame(0.0)      -- opreste spawn-ul in jurul playerului
        end

        if Config.Population.removeAmbientVehicles then
            SetVehiclePopulationBudget(0)                   -- 0 = niciun vehicul de trafic nou
            SetAmbientVehicleRangeMultiplierThisFrame(0.0)
            SetGarbageTrucks(false)                         -- camioanele de gunoi sunt tot trafic ambiental
        end

        if Config.Population.removeParkedVehicles then
            SetParkedVehicleDensityMultiplierThisFrame(0.0)
        end

        if Config.Population.removeTrains then SetRandomTrains(false) end
        if Config.Population.removeBoats  then SetRandomBoats(false)  end
    end
end)
