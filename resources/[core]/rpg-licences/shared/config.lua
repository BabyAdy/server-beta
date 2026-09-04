-- ===========================================================================
--  rpg-licences — configuratie partajata
-- ===========================================================================
Config = {}

-- ---- COMANDA /agl -----------------------------------------------------
Config.MinAglRank       = 'manager'      -- cine poate rula /agl
Config.MinBroadcastRank = 'trialadmin'   -- cine vede mesajul "Staff: ... has given ..." in chat

-- ---- CLASA VEHICUL (GetVehicleClass) -> licenta necesara --------------
-- nil / lipsa din tabel = fara restrictie pentru clasa respectiva.
-- Se verifica DOAR pe locul de sofer/pilot (pasagerii nu au nevoie de licenta).
Config.VehicleClassLicence = {
    [0]  = 'driving',  -- Compacts
    [1]  = 'driving',  -- Sedans
    [2]  = 'driving',  -- SUVs
    [3]  = 'driving',  -- Coupes
    [4]  = 'driving',  -- Muscle
    [5]  = 'driving',  -- Sports Classics
    [6]  = 'driving',  -- Sports
    [7]  = 'driving',  -- Super
    [8]  = 'driving',  -- Motorcycles
    [9]  = 'driving',  -- Off-road
    [10] = 'driving',  -- Industrial
    [11] = 'driving',  -- Utility
    [12] = 'driving',  -- Vans
    -- [13] Cycles -> fara restrictie (bicicleta, fara motor)
    [14] = 'sailing',  -- Boats
    [15] = 'flying',   -- Helicopters
    [16] = 'flying',   -- Planes
    [17] = 'driving',  -- Service
    [18] = 'driving',  -- Emergency
    [19] = 'driving',  -- Military
    [20] = 'driving',  -- Commercial
    -- [21] Trains -> fara restrictie (nu se "conduc" ca un vehicul normal)
}

-- ---- TEXTE (afisate central, temporar, cand esti dat jos / dezarmat) ----
Config.Messages = {
    driving = "You don't have driving licence!",
    weapon  = "You don't have weapon licence!",
    flying  = "You don't have flying licence!",
    sailing = "You don't have sailing licence!",
}
Config.FlashDurationMs = 4000

-- ---- ARME -------------------------------------------------------------
Config.WeaponCheckIntervalMs = 300   -- cat de des verificam daca ai arma in mana fara licenta
Config.WeaponWarnCooldownMs  = 3000  -- cat de rar repetam textul (nu la fiecare verificare)
