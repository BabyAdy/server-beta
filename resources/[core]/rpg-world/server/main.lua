-- ===========================================================================
--  rpg-world — server
--  Re-validare server-side a toggle-ului de NoClip + statebag replicat 'noclip'
--  -> orice alt client, la schimbarea acestui statebag, ascunde/arata ped-ul
--  jucatorului respectiv (vezi client/noclip.lua). Jucatorul insusi ramane doar
--  translucid local (nu se ascunde de el insusi).
-- ===========================================================================

local function hasRank(src, rank)
    if src <= 0 then return true end
    local ok, allowed = pcall(function() return exports['rpg-auth']:hasStaffLevel(src, rank) end)
    return ok and allowed == true
end

RegisterNetEvent('rpg-world:noclipToggle', function(on)
    local src = source
    if not hasRank(src, Config.NoClip.minRank) then return end

    local ply = Player(src)
    if ply and ply.state then
        ply.state:set('noclip', on and true or false, true)   -- replicat -> vizibil pt. toti clientii
    end
end)

-- daca playerul pleaca in timp ce era in NoClip, statebag-ul dispare o data cu el
-- (nu mai e nimeni de ascuns), deci nu mai e nevoie de curatare explicita aici.
