-- ===========================================================================
--  rpg-world — configuratie partajata
-- ===========================================================================
Config = {}

-- ---- POPULATIE AMBIENTALA (NPC + trafic) --------------------------------
Config.Population = {
    removePeds            = true,    -- elimina pietonii ambientali (NPC)
    removeAmbientVehicles = true,    -- elimina masinile conduse de NPC (trafic ambiental) + camioane de gunoi
    removeParkedVehicles  = false,   -- masinile parcate (fara sofer) — optional, dezactivat implicit
    removeTrains          = false,   -- optional
    removeBoats           = false,   -- optional
}

-- ---- NOCLIP ---------------------------------------------------------
Config.NoClip = {
    minRank   = 'trialadmin',   -- grad minim (slug din rpg-auth/shared/staff.lua)
    toggleKey = 'F2',           -- RegisterKeyMapping -> /noclip
    upKey     = 'E',            -- sus
    downKey   = 'Q',            -- jos

    baseSpeed = 1.6,             -- m/s la tier-ul "Normal" (inainte de multiplicator)
    defaultTier = 3,             -- index in tiers[] la activare -> "Normal"

    -- L Shift -> cicleaza intre aceste trepte (in ordine, cu revenire la inceput)
    tiers = {
        { name = 'Very Slow', mult = 0.35 },
        { name = 'Slow',      mult = 0.7  },
        { name = 'Normal',    mult = 1.0  },   -- viteza default
        { name = 'Fast',      mult = 2.5  },
        { name = 'Very Fast', mult = 6.0  },
        { name = 'Sasuke',    mult = 14.0 },   -- cel mai rapid
    },
}

-- ---- COMENZI VEHICULE (staff) ----------------------------------------
Config.SpawnCarRank = 'trialadmin'   -- /spawncar [model]
Config.MaxPerfRank  = 'manager'      -- /maxperf

-- ---- /setvw [sql id] [virtual id] ----------------------------------
Config.SetVwRank          = 'trialadmin'   -- cine poate rula /setvw
Config.SetVwBroadcastRank = 'trialadmin'   -- cine vede mesajul in chat
