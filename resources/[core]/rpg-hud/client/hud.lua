-- ===========================================================================
--  rpg-hud — HUD (player, status, money, paycheck, voice, activity)
--  Event-driven. Un singur thread de polling pentru health, unul pentru voice.
--  Datele "de cont" (username, id, cash, bank, online) vin de la SERVER.
-- ===========================================================================

local hud = {
    started    = false,
    food       = Config.Hud.startNeeds.food,
    water      = Config.Hud.startNeeds.water,
    lastHealth = -1,
    lastVoice  = nil,
}

local function push(kind, value)
    HUD.send({ mod = 'hud', action = kind, value = value })
end

-- ----- feeders (pornesc dupa spawn-ul personajului) -----------------
AddEventHandler('rpg-hud:startFeeders', function()
    if hud.started then return end
    hud.started = true

    -- HEALTH: native client, trimis doar la schimbare
    CreateThread(function()
        while true do
            local ped = PlayerPedId()
            local pct = 0
            if not IsEntityDead(ped) then
                local hp, maxhp = GetEntityHealth(ped), GetEntityMaxHealth(ped)
                if hp > 100 then
                    pct = math.floor((hp - 100) / math.max(1, maxhp - 100) * 100 + 0.5)
                end
            end
            if pct ~= hud.lastHealth then
                hud.lastHealth = pct
                push('health', pct)
            end
            Wait(Config.Hud.healthPollMs)
        end
    end)

    -- NEEDS: mock in dev; altfel doar valorile primite prin evenimente
    push('food', math.floor(hud.food))
    push('water', math.floor(hud.water))
    if Config.Hud.mockNeeds then
        CreateThread(function()
            while true do
                Wait(10000)   -- tick la 10s
                hud.food  = math.max(0, hud.food  - Config.Hud.mockDrainPerMin.food  / 6.0)
                hud.water = math.max(0, hud.water - Config.Hud.mockDrainPerMin.water / 6.0)
                push('food', math.floor(hud.food))
                push('water', math.floor(hud.water))
            end
        end)
    end

    -- VOICE: stare "talking" reala (voice built-in FiveM); restul e API
    CreateThread(function()
        while true do
            local st = hud.lastVoice
            if hud.lastVoice ~= 'muted' then
                st = NetworkIsPlayerTalking(PlayerId()) and 'talking' or 'idle'
            end
            if st ~= hud.lastVoice then
                hud.lastVoice = st
                push('voice', st)
            end
            Wait(Config.Hud.voicePollMs)
        end
    end)

    -- PAYCHECK: seed pentru countdown-ul din NUI (serverul poate suprascrie)
    push('paycheck', { seconds = Config.Hud.paycheckInterval, running = true })
end)

-- ----- API events (framework) ---------------------------------
RegisterNetEvent('hud:updatePlayer',   function(d) push('player', d) end)
RegisterNetEvent('hud:updateOnline',   function(n) push('online', tonumber(n) or 0) end)
RegisterNetEvent('hud:updateMoney',    function(v) push('money', tonumber(v) or 0) end)
RegisterNetEvent('hud:updateBank',     function(v) push('bank', tonumber(v) or 0) end)
RegisterNetEvent('hud:updateHealth',   function(v) push('health', tonumber(v) or 0) end)
RegisterNetEvent('hud:updateFood',     function(v) hud.food  = tonumber(v) or hud.food;  push('food',  math.floor(hud.food)) end)
RegisterNetEvent('hud:updateWater',    function(v) hud.water = tonumber(v) or hud.water; push('water', math.floor(hud.water)) end)
RegisterNetEvent('hud:updatePaycheck', function(d) push('paycheck', d) end)
RegisterNetEvent('hud:updateActivity', function(d) push('activity', d) end)
RegisterNetEvent('hud:clearActivity',  function() push('activityClear', true) end)

-- ----- exports client ---------------------------------------
exports('setFood',      function(v) hud.food = tonumber(v) or hud.food; push('food', math.floor(hud.food)) end)
exports('setWater',     function(v) hud.water = tonumber(v) or hud.water; push('water', math.floor(hud.water)) end)
exports('setVoiceState',function(s) hud.lastVoice = s; push('voice', s) end)
exports('setActivity',  function(d) push('activity', d) end)
exports('clearActivity',function() push('activityClear', true) end)
