Config = {}

-- ===========================================================================
--  VALORI DE START — acordate O SINGURĂ DATĂ, la CREAREA caracterului
--  (nu la fiecare reconnect). Vezi server/main.lua -> core:characterCreated.
-- ===========================================================================
Config.Initial = {
    level         = 1,
    respectpoints = 0,
    money         = 500,     -- cash
    bank          = 1000,
}

-- ===========================================================================
--  CERINȚE PENTRU URMĂTORUL LEVEL  —  SINGURUL loc unde sunt definite
--
--  NU există level maxim: pentru ORICE level țintă se calculează cerințele.
--
--  1) Formula — se aplică oricărui level care nu are o valoare explicită.
--     Pattern-ul actual:  L2 = 3 RP / 1.000$ ,  L3 = 6 RP / 1.500$ , ...
--  2) LevelRequirements — suprascrieri opționale pentru anumite level-uri
--     (au prioritate față de formulă). Adaugi doar dacă vrei un level "special".
-- ===========================================================================
function Config.LevelFormula(targetLevel)
    return {
        rp    = 3 * (targetLevel - 1),   -- L2=3, L3=6, L4=9, L5=12, L6=15, ...
        money = 500 * targetLevel,       -- L2=1000, L3=1500, L4=2000, L5=2500, ...
    }
end

Config.LevelRequirements = {
    -- [5] = { rp = 20, money = 5000 },   -- exemplu de suprascriere
}

-- ---- helper derivat (nu edita) ------------------------------------------
-- cerințele pentru a avansa DE LA `currentLevel` la următorul.
-- Întoarce MEREU o valoare (nu există max level).
function Config.nextRequirement(currentLevel)
    local target = (tonumber(currentLevel) or 1) + 1
    if target < 2 then target = 2 end
    return Config.LevelRequirements[target] or Config.LevelFormula(target)
end

-- ===========================================================================
--  PAYDAY  —  toate valorile într-un singur loc
-- ===========================================================================
Config.Payday = {
    interval         = 3600,   -- PAYDAY_INTERVAL: secunde per ciclu (HUD: 60:00 -> 00:00)
    minActiveSeconds = 1801,   -- MIN_ACTIVE_PLAYTIME_FOR_PAYDAY: activ acumulat în ciclu ca să iei payday
    salary           = 100,    -- SALARY  -> intră în BANK (nu în cash)
    respectReward    = 1,      -- RESPECT_REWARD: +1 RP (level-ul se cumpără separat prin /buylevel)
}

-- ===========================================================================
--  BANK INTEREST TIERS  —  SINGURUL loc unde sunt definite dobânzile
--
--  `rate` e fracție:  0.0003 = 0.03%   ,   0.0005 = 0.05%
--  Tier-ul se alege după soldul din bancă ÎNAINTE de payday:
--     bank >= tier.min  =>  se aplică tier.rate  (ultimul tier care se potrivește)
--
--  >>> PRAGUL 0.03% -> 0.05% : proiectul NU avea unul definit. Am ales
--  >>> 1.000.000$. Modifică `min` de mai jos pentru alt prag / adaugă tier-uri.
-- ===========================================================================
Config.BankInterestTiers = {
    { min = 0,       rate = 0.0003 },   -- 0.03%
    { min = 1000000, rate = 0.0005 },   -- >= 1.000.000$  ->  0.05%   (PRAG ALES)
}

-- ===========================================================================
--  AUTOSAVE  &  ACTIVITY / AFK
-- ===========================================================================
Config.Autosave = { interval = 30 }    -- AUTOSAVE_INTERVAL: secunde între scrieri periodice în DB

Config.Activity = {
    tickSeconds     = 5,      -- clientul raportează activitatea la fiecare N secunde
    minMoveDistance = 1.0,    -- ACTIVE_MOVEMENT_THRESHOLD: metri parcurși pe fereastră (pe jos)
    minVehicleSpeed = 1.5,    -- m/s: viteza minimă a vehiculului ca deplasarea să conteze
}

-- ===========================================================================
--  FORMATARE BANI — separator de mii cu punct.  1000000 -> "1.000.000"
--  (NU se salvează formatat în DB — doar pentru afișare / mesaje.)
-- ===========================================================================
function Config.formatMoney(n)
    local neg = ''
    n = math.floor(tonumber(n) or 0)
    if n < 0 then neg = '-'; n = -n end
    local s = tostring(n)
    local out = s:reverse():gsub('(%d%d%d)', '%1.'):reverse():gsub('^%.', '')
    return neg .. out
end

-- ===========================================================================
--  FORMATARE PLAYTIME — secunde -> "HH.MM"  (MM = 00-59, NU zecimală!)
--  3600 -> "1.00" ,  3660 -> "1.01" ,  7200 -> "2.00" ,  80943 -> "22.29"
-- ===========================================================================
function Config.formatPlaytime(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    return ('%d.%02d'):format(h, m)
end

-- dobânda (fracție) pentru un sold de bancă dat, după Config.BankInterestTiers
function Config.interestRate(bank)
    bank = tonumber(bank) or 0
    local rate = Config.BankInterestTiers[1].rate
    for _, tier in ipairs(Config.BankInterestTiers) do
        if bank >= tier.min then rate = tier.rate end
    end
    return rate
end
