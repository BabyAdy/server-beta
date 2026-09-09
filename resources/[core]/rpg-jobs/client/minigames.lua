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

-- "Search the code": fiecare incercare NUI -> aici -> server (serverul tine codul)
RegisterNUICallback('codeGuess', function(data, cb)
    if data and data.token and type(data.guess) == 'table' then
        TriggerServerEvent('rpg-jobs:codeGuess', tostring(data.token), data.guess)
    end
    cb('ok')
end)

-- server -> NUI: ce pozitii s-au blocat la "Search the code"
RegisterNetEvent('rpg-jobs:codeResult', function(d)
    if type(d) ~= 'table' then return end
    SendNUIMessage({
        action = 'codeResult',
        locked = d.locked or {},
        solved = d.solved == true,
        attempts = d.attempts or 0,
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

-- ecranul "SHIFT COMPLETE" a fost inchis (buton CONTINUE sau ESC) -> elibereaza cursorul
RegisterNUICallback('doneClose', function(_, cb)
    JB.doneOpen = false
    JB.setFocus(false)
    cb('ok')
end)
