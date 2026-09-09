-- ===========================================================================
--  rpg-subs — definitia subscriptiilor (partajata)
--  Se incarca si in alte resurse prin:  shared_script '@rpg-subs/shared/subs.lua'
--  (folosit de rpg-nametags pt. iconuri, si de rpg-subs server pt. chat/logica).
--
--  Model de stocare (users): sub_gold / sub_platinum / sub_legend = TIMESTAMP unix
--  (secunde) al EXPIRARII. 0 sau <= now  => subscriptie inactiva.
--  premiumpoints = moneda cu care se cumpara zile din /shop (gold / platinum).
-- ===========================================================================

Subs = {}

-- ORDINEA DE AFISARE (stanga -> dreapta), atat in nametag cat si in chat.
Subs.ORDER = { 'legend', 'platinum', 'gold' }

-- slug -> { key, label, color (#hex), icon (interior SVG, viewBox 0 0 24 24),
--          buyable = se poate cumpara din /shop cu Premium Points }
Subs.TYPES = {
    gold = {
        key = 'gold', label = 'Gold', color = '#ffd633', buyable = true,  -- GALBEN
        -- stea
        icon = '<path fill="currentColor" d="M12 2.6l2.75 5.57 6.15.9-4.45 4.34 1.05 6.13L12 16.65l-5.5 2.89 1.05-6.13L3.1 9.07l6.15-.9L12 2.6z"/>',
    },
    platinum = {
        key = 'platinum', label = 'Platinum', color = '#a855f7', buyable = true,  -- MOV
        -- diamant / gema
        icon = '<path fill="currentColor" d="M5 3h14l3 5.6L12 21 2 8.6 5 3z"/>',
    },
    legend = {
        key = 'legend', label = 'Legend', color = '#3d9bff', buyable = false,  -- ALBASTRU. EXCLUSIV prin plati / setat de owner
        -- fulger
        icon = '<path fill="currentColor" d="M13 2L3 14h6l-2 8 10-12h-6l2-8z"/>',
    },
}

function Subs.def(key) return Subs.TYPES[key] end
function Subs.isValid(key) return key ~= nil and Subs.TYPES[key] ~= nil end

-- din { gold=ts, platinum=ts, legend=ts } -> lista ORDONATA (legend, platinum, gold)
-- doar cu subscriptiile ACTIVE (expiry > now)
function Subs.activeList(map, now)
    now = now or os.time()
    local out = {}
    for _, key in ipairs(Subs.ORDER) do
        local ts = tonumber(map and map[key]) or 0
        if ts > now then out[#out + 1] = key end
    end
    return out
end

-- format uman "Xz Yh Zm" pentru un numar de secunde ramase
function Subs.fmtRemaining(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    local d = math.floor(seconds / 86400); seconds = seconds - d * 86400
    local h = math.floor(seconds / 3600);  seconds = seconds - h * 3600
    local m = math.floor(seconds / 60)
    if d > 0 then return ('%dz %dh %dm'):format(d, h, m) end
    if h > 0 then return ('%dh %dm'):format(h, m) end
    return ('%dm'):format(m)
end
