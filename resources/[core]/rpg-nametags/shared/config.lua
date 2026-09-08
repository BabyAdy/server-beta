-- ===========================================================================
--  rpg-nametags — configuratie
-- ===========================================================================
Config = {}

Config.Enabled = true

-- Distante (metri)
Config.MaxDistance = 22.0    -- dincolo de asta nametag-ul nu se mai afiseaza
Config.RefDistance = 6.0     -- la aceasta distanta scale-ul e 1.0 (mai aproape -> mai mare, capat la MaxScale)
Config.FadeStart   = 14.0    -- de la aceasta distanta incepe sa se estompeze spre MaxDistance

-- Pozitionare — ancora e OSUL CAPULUI ped-ului (0x796E), deci ramane fix pe
-- caracter si NU sare cand jucatorul intra/iese din masina.
Config.HeadOffsetZ = 0.34    -- cat de sus fata de varful capului

-- Scalare cu distanta
Config.MinScale = 0.62
Config.MaxScale = 1.12

-- Comportament
Config.ShowSelf    = false   -- afiseaza si propriul nametag?
Config.Occlusion   = false   -- true = ascunde daca nu ai linie de vedere (poate palpai in trafic)
Config.HideWhenDead = true   -- ascunde nametag-ul jucatorilor morti/incapacitati

-- Bucla client: 0 ms cat timp cineva e in raza; altfel se relaxeaza.
Config.IdleWaitMs = 400

return true
