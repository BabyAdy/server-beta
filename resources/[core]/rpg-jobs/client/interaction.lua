-- ===========================================================================
--  rpg-jobs — INTERACTIUNE NPC
--  Proximitate fata de NPC -> prompt NUI "[Y] Talk to <job>" -> tasta Y
--  (Config.Interaction.key) deschide meniul. FARA comanda.
--  Serverul re-verifica proximitatea la Get/Quit/Start.
-- ===========================================================================

local promptShown = false

local function setPrompt(on)
    if promptShown == on then return end
    promptShown = on
    SendNUIMessage({ action = 'prompt', show = on, label = ('Talk to %s'):format(JB.job.label) })
end

CreateThread(function()
    local npcVec = vector3(JB.job.npc.coords.x, JB.job.npc.coords.y, JB.job.npc.coords.z)
    local KEY = Config.Interaction.key
    local R   = Config.Interaction.radius

    while true do
        local wait = 800
        local dist = #(GetEntityCoords(PlayerPedId()) - npcVec)

        if dist < 18.0 then
            wait = 0
            local canTalk = dist < R and not JB.menuOpen and not JB.mgOpen and not JB.isWorking
            setPrompt(canTalk)
            JB.nearNpc = canTalk
            if canTalk and IsControlJustReleased(0, KEY) then
                JB.openMenu()
            end
        else
            JB.nearNpc = false
            setPrompt(false)
            wait = (dist < 120.0) and 300 or 1000
        end

        Wait(wait)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then setPrompt(false) end
end)
