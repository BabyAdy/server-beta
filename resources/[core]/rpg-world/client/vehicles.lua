-- ===========================================================================
--  rpg-world — client: /spawncar (te pune la volan dupa ce serverul il creeaza)
-- ===========================================================================

RegisterNetEvent('rpg-world:enterSpawnedVehicle', function(netId)
    local tries = 0
    local veh = NetworkGetEntityFromNetworkId(netId)
    while (not veh or veh == 0 or not DoesEntityExist(veh)) and tries < 50 do
        Wait(100)
        veh = NetworkGetEntityFromNetworkId(netId)
        tries = tries + 1
    end
    if veh and veh ~= 0 and DoesEntityExist(veh) then
        TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
    end
end)
