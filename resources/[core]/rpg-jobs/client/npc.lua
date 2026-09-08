-- ===========================================================================
--  rpg-jobs — NPC + BLIP
--  Spawneaza NPC-ul jobului (din Config) + blip pe harta.
--  Interactiunea (proximitate + tasta Y + prompt) e in client/interaction.lua.
-- ===========================================================================

JB.npcPed  = nil
local npcBlip = nil

CreateThread(function()
    local j = JB.job
    local hash = GetHashKey(j.npc.model)
    RequestModel(hash)
    local t0 = GetGameTimer()
    while not HasModelLoaded(hash) and GetGameTimer() - t0 < 8000 do Wait(50) end
    if HasModelLoaded(hash) then
        JB.npcPed = CreatePed(4, hash, j.npc.coords.x, j.npc.coords.y, j.npc.coords.z - 1.0, j.npc.coords.w or 0.0, false, true)
        SetEntityInvincible(JB.npcPed, true)
        SetBlockingOfNonTemporaryEvents(JB.npcPed, true)
        FreezeEntityPosition(JB.npcPed, true)
        if j.npc.scenario then TaskStartScenarioInPlace(JB.npcPed, j.npc.scenario, 0, true) end
        SetModelAsNoLongerNeeded(hash)
    end

    if j.blip then
        npcBlip = AddBlipForCoord(j.npc.coords.x, j.npc.coords.y, j.npc.coords.z)
        SetBlipSprite(npcBlip, j.blip.sprite or 402)
        SetBlipColour(npcBlip, j.blip.color or 5)
        SetBlipScale(npcBlip, j.blip.scale or 0.85)
        SetBlipAsShortRange(npcBlip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(j.blip.label or (j.label .. ' Job'))
        EndTextCommandSetBlipName(npcBlip)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if JB.npcPed and DoesEntityExist(JB.npcPed) then DeleteEntity(JB.npcPed) end
    if npcBlip and DoesBlipExist(npcBlip) then RemoveBlip(npcBlip) end
end)
