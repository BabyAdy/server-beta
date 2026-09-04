-- ===========================================================================
--  rpg-housing — configurație partajată
-- ===========================================================================
Config = {}

Config.MinCreateRank    = 'manager'      -- /createhouse
Config.MinBroadcastRank = 'trialadmin'   -- cine vede mesajul "Staff: ... has created house #id" in chat

Config.LabelRadius   = 25.0   -- distanța pana la care se văd marker-ul + eticheta casei
Config.InteractRadius = 2.2   -- distanța la care apare promptul [E] Intră/Ieși
Config.MarkerColor   = { r = 168, g = 85, b = 247, a = 190 }   -- mov, ca restul temei

-- ===========================================================================
--  TIPURI DE INTERIOR VALIDE pt. /createhouse [interior_type] [price]
--  Coordonatele sunt REALE — luate direct din comentariile fisierelor bob74_ipl
--  (ex. resources/bob74_ipl/gta_online/house_hi_1.lua), NU inventate.
--
--  IMPORTANT: aceste coordonate NU sunt inca folosite pt. teleportare in interior
--  (acel pas -> exports['bob74_ipl']:EnableIpl(...) + teleport -> vine intr-un task
--  viitor, cand cerem "intra in casa"). Momentan servesc doar ca eticheta/validare
--  pt. `interior_type` la /createhouse.
-- ===========================================================================
Config.InteriorTypes = {
    house_hi_1     = { label = 'High End House 1 (3655 Wild Oats Drive)',          coords = vector4(-169.286, 486.494, 137.444, 0.0) },
    house_hi_2     = { label = 'High End House 2 (2044 North Conker Avenue)',      coords = vector4(340.941, 437.180, 149.393, 0.0) },
    house_hi_3     = { label = 'High End House 3 (2045 North Conker Avenue)',      coords = vector4(373.023, 416.105, 145.701, 0.0) },
    house_hi_4     = { label = 'High End House 4 (2862 Hillcrest Avenue)',         coords = vector4(-676.127, 588.612, 145.170, 0.0) },
    house_hi_5     = { label = 'High End House 5 (2868 Hillcrest Avenue)',         coords = vector4(-763.107, 615.906, 144.140, 0.0) },
    house_hi_6     = { label = 'High End House 6 (2874 Hillcrest Avenue)',         coords = vector4(-857.798, 682.563, 152.653, 0.0) },
    house_hi_7     = { label = 'High End House 7 (2677 Whispymound Drive)',        coords = vector4(120.500, 549.952, 184.097, 0.0) },
    house_hi_8     = { label = 'High End House 8 (2133 Mad Wayne Thunder)',        coords = vector4(-1288.000, 440.748, 97.695, 0.0) },
    house_mid_1    = { label = 'Middle End House 1',                               coords = vector4(347.269, -999.296, -99.196, 0.0) },
    house_low_1    = { label = 'Low End House 1',                                  coords = vector4(261.459, -998.820, -99.009, 0.0) },
    apartment_hi_1 = { label = 'High End Apartment 1 (4 Integrity Way, Apt 30)',   coords = vector4(-35.313, -580.420, 88.712, 0.0) },
    apartment_hi_2 = { label = 'High End Apartment 2 (Del Perro Heights, Apt 7)',  coords = vector4(-1477.140, -538.750, 55.526, 0.0) },
    mansion_1      = { label = 'The Vinewood Residence',                           coords = vector4(543.852, 712.754, 201.0, 0.0) },
    mansion_2      = { label = 'Richman Villa',                                    coords = vector4(-1630.434, 470.852, 128.0, 0.0) },
    mansion_3      = { label = 'The Tongva Estate',                                coords = vector4(-2601.712, 1874.826, 166.0, 0.0) },
}
