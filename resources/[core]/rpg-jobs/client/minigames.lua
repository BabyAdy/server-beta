-- ===========================================================================
--  rpg-jobs — MINIGAMES BRIDGE (client)
--  Logica reala a minigame-urilor e in nui/script.js. Aici doar:
--    server -> deschide minigame-ul cu params + token
--    NUI    -> trimite rezultatul catre server (cu token)
--  Serverul valideaza TOTUL (token, timing, solutie, zona).
-- ===========================================================================

RegisterNetEvent('rpg-jobs:minigame', function(payload)
    if type(payload) ~= 'table' or not payload.token then return end
    JB.mgOpen = true
    JB.setFocus(true)
    SendNUIMessage({
        action = 'minigame',
        game   = payload.game,
        token  = payload.token,
        params = payload.params or {},
    })
end)

-- rezultatul minigame-ului: NUI -> aici -> server
RegisterNUICallback('minigameResult', function(data, cb)
    JB.mgOpen = false
    JB.setFocus(false)
    if data and data.token then
        -- `result` e opac pentru client; serverul stie ce sa faca cu el per joc
        TriggerServerEvent('rpg-jobs:submitMinigame', tostring(data.token), data.result)
    end
    cb('ok')
end)

-- NUI a inchis minigame-ul fara rezultat (timeout intern / eroare) -> tratat ca fail
RegisterNUICallback('minigameAbort', function(data, cb)
    JB.mgOpen = false
    JB.setFocus(false)
    if data and data.token then
        TriggerServerEvent('rpg-jobs:submitMinigame', tostring(data.token), { aborted = true })
    end
    cb('ok')
end)
