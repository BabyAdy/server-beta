-- ===========================================================================
--  rpg-duty — configuratie
-- ===========================================================================
Config = {}
Config.Debug = true

Config.DutyCommand   = 'duty'
Config.AnnounceColor = '#6E77FA'     -- "X is now on/off duty!"
Config.AnnounceRange = 10.0          -- m: cine vede anuntul
Config.HqRange       = 50.0          -- m: raza fata de punctul EXIT al HQ-ului in care poti da /duty
                                     --    (routing bucket-ul trebuie sa fie cel al HQ-ului)

-- Taste la punctul de outfit: E creeaza prima data, Y modifica ulterior.
Config.KeyCreate = 38               -- E
Config.KeyModify = 246             -- Y

-- ---------------------------------------------------------------------------
--  PUNCTE PER FACTIUNE  (cheia = id-ul din tabelul `factions`).
--  Prima factiune creata cu /createfaction va avea id-ul 1.
--  `outfit` = punctul unde apesi E/Y ca sa-ti faci/modifici outfit-ul.
--  `vw`     = routing bucket-ul (Virtual World) in care e valabil punctul.
-- ---------------------------------------------------------------------------
Config.FactionPoints = {
    [1] = {   -- Los Santos Police Department
        outfit   = vector4(452.44, -982.95, 30.69, 94.13),
        vw       = 1,
    },
}

-- ---------------------------------------------------------------------------
--  Sloturi editabile in editorul de outfit (component-uri / props GTA).
--  Editorul e generic: derulezi drawable + textura pentru fiecare slot si
--  cand ai facut uniforma de politie apesi Save.
-- ---------------------------------------------------------------------------
Config.OutfitComponents = {
    { id = 1,  label = 'Mască' },
    { id = 3,  label = 'Brațe / Torso' },
    { id = 4,  label = 'Pantaloni' },
    { id = 6,  label = 'Încălțăminte' },
    { id = 7,  label = 'Accesoriu (gât)' },
    { id = 8,  label = 'Tricou' },
    { id = 9,  label = 'Vestă' },
    { id = 10, label = 'Insignă / Decal' },
    { id = 11, label = 'Bluză / Geacă' },
}
Config.OutfitProps = {
    { id = 0, label = 'Șapcă / Cască' },
    { id = 1, label = 'Ochelari' },
}
