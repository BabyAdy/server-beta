-- ===========================================================================
--  rpg-garages — configuratie partajata (client + server)
--  Nimic hardcodat in cod: distante, blip, fuel/odometer default, catalog etc.
-- ===========================================================================
Config = {}

Config.Debug = true

-- ---- PERMISIUNI -----------------------------------------------------------
-- Slug minim (rpg-auth/shared/staff.lua) pentru /vcreate /vdelete /creategarage /deletegarage.
Config.StaffRank = 'manager'

-- ---- TIPURI DE GARAGE ---------------------------------------------------
Config.GarageTypes = {
    Vehicle = 'Vehicle',   -- cars, motorcycles, alte vehicule terestre
    Heli    = 'Heli',      -- helicopters + planes
    Boat    = 'Boat',      -- boats
}

-- ---- DISTANTE (metri) --------------------------------------------------
Config.Distance = {
    scan       = 60.0,   -- raza in care clientul "trezeste" bucla de garage (marker/prompt)
    marker     = 14.0,   -- deseneaza marker + checkpoint 3D
    prompt     = 8.0,    -- afiseaza prompt-ul "GARAGE ACCESS" / "GARAGE PARK"
    serverGate = 22.0,   -- anti-abuz: serverul respinge orice request daca esti mai departe de-atat
    spawnClear = 4.5,    -- offset in fata garage-ului unde apare vehiculul
    dealer     = 3.0,    -- raza de interactiune la dealership
    dealerMark = 25.0,   -- raza in care se deseneaza marker-ul de dealership
}

-- ---- BLIP GARAGE ------------------------------------------------------
Config.Blip = {
    Vehicle = { sprite = 357, color = 3,  scale = 0.85 },
    Heli    = { sprite = 360, color = 3,  scale = 0.85 },
    Boat    = { sprite = 356, color = 3,  scale = 0.85 },
    shortRange = true,
}

-- ---- MARKER GARAGE (checkpoint 3D custom, nu interfata default GTA) ----
Config.Marker = {
    type   = 36,                         -- glob mic, minimalist
    size   = { x = 1.6, y = 1.6, z = 1.0 },
    rgba   = { 138, 92, 246, 90 },       -- mov, translucid (temele proiectului)
    bob    = true,
    rotate = false,
}

-- ---- VALORI IMPLICITE VEHICUL ---------------------------------------
Config.DefaultFuel     = 100.0   -- fuel la cumparare / /vcreate
Config.DefaultOdometer = 0.0
Config.DefaultStatus   = 0       -- 0 = locked

-- ---- ODOMETER ------------------------------------------------------
Config.Odometer = {
    sampleMs      = 3000,     -- interval de esantionare a distantei (client)
    autosaveMs    = 150000,   -- salvare periodica a fuel/odometer/tuning (anti-pierdere la disconnect)
    maxDeltaKm    = 3000.0,   -- clamp server-side pt. un singur save (anti-spoof)
    maxJumpM      = 400.0,    -- ignora salturi (teleport) mai mari de-atat intr-un esantion
}

-- ---- PLATE ------------------------------------------------------
Config.Plate = { len = 8, chars = 'ABCDEFGHIJKLMNPQRSTUVWXYZ0123456789' }

-- ---- KEYBIND lock/unlock vehicul personal (rebindabil de player din Settings) ----
Config.LockKey = 'L'

-- ---- ECONOMIE ------------------------------------------------------
-- De unde se scot banii la cumparare din dealership: 'bank' sau 'cash'.
Config.PayFrom = 'bank'

-- ===========================================================================
--  MAPARE MODEL -> vehicle_type
--  Sursa principala de adevar e categoria din dealership (Config.Catalog).
--  Aceasta lista e un OVERRIDE folosit de /vcreate pt. modele din afara
--  catalogului. Orice model nementionat = 'Vehicle'.
-- ===========================================================================
Config.VehicleTypeByModel = {
    -- Heli / planes
    buzzard = 'Heli', buzzard2 = 'Heli', frogger = 'Heli', maverick = 'Heli',
    polmav = 'Heli', supervolito = 'Heli', volatus = 'Heli', savage = 'Heli',
    luxor = 'Heli', shamal = 'Heli', nimbus = 'Heli', vestra = 'Heli',
    velum = 'Heli', duster = 'Heli', cuban800 = 'Heli', dodo = 'Heli',
    titan = 'Heli', mammatus = 'Heli',
    -- Boats
    dinghy = 'Boat', jetmax = 'Boat', marquis = 'Boat', seashark = 'Boat',
    speeder = 'Boat', squalo = 'Boat', suntrap = 'Boat', toro = 'Boat',
    tropic = 'Boat', predator = 'Boat', tug = 'Boat',
}

-- ===========================================================================
--  DEALERSHIP-uri (locatii fizice). Fiecare vinde doar categoriile listate.
--  ped = optional (model + coords); daca lipseste, se foloseste doar marker.
-- ===========================================================================
Config.Dealers = {
    {
        label      = 'Premium Deluxe Motorsport',
        categories = { 'Vehicle' },
        coords     = vector3(-56.72, -1096.6, 26.42),
        heading    = 25.0,
        ped        = 's_m_m_autoshop_01',
        marker     = true,
        blip       = { sprite = 523, color = 3, scale = 0.9 },
    },
    {
        label      = 'Higgins Helitours',
        categories = { 'Heli' },
        coords     = vector3(-746.8, -1473.8, 5.0),
        heading    = 145.0,
        ped        = 's_m_m_pilot_01',
        marker     = true,
        blip       = { sprite = 359, color = 3, scale = 0.9 },
    },
    {
        label      = 'Puerto Del Sol Marina',
        categories = { 'Boat' },
        coords     = vector3(-794.9, -1339.6, 5.0),
        heading    = 128.0,
        ped        = 's_m_m_dockwork_01',
        marker     = true,
        blip       = { sprite = 356, color = 3, scale = 0.9 },
    },
}

-- ===========================================================================
--  CATALOG dealership. Sursa de adevar server-side pentru model/nume/pret/tip.
--  Clientul trimite DOAR `model`; serverul cauta aici.
-- ===========================================================================
Config.Catalog = {
    -- ---- Vehicle ----
    { model = 'blista',    name = 'Dinka Blista',        type = 'Vehicle', price = 9000 },
    { model = 'sultan',    name = 'Karin Sultan',        type = 'Vehicle', price = 28000 },
    { model = 'elegy2',    name = 'Annis Elegy RH8',     type = 'Vehicle', price = 45000 },
    { model = 'sentinel3', name = 'Ubermacht Sentinel',  type = 'Vehicle', price = 65000 },
    { model = 'buffalo3',  name = 'Bravado Buffalo S',   type = 'Vehicle', price = 96000 },
    { model = 'kuruma',    name = 'Karin Kuruma',        type = 'Vehicle', price = 125000 },
    { model = 'akuma',     name = 'Dinka Akuma',         type = 'Vehicle', price = 32000 },
    { model = 'bati',      name = 'Pegassi Bati 801',    type = 'Vehicle', price = 41000 },
    -- ---- Heli / Planes ----
    { model = 'frogger',   name = 'Nagasaki Frogger',    type = 'Heli',    price = 1200000 },
    { model = 'buzzard2',  name = 'Buzzard (unarmed)',   type = 'Heli',    price = 950000 },
    { model = 'velum',     name = 'JoBuilt Velum',       type = 'Heli',    price = 450000 },
    { model = 'luxor',     name = 'Buckingham Luxor',    type = 'Heli',    price = 1750000 },
    -- ---- Boats ----
    { model = 'dinghy',    name = 'Nagasaki Dinghy',     type = 'Boat',    price = 30000 },
    { model = 'toro',      name = 'Pegassi Toro',        type = 'Boat',    price = 165000 },
    { model = 'jetmax',    name = 'Shitzu Jetmax',       type = 'Boat',    price = 300000 },
    { model = 'marquis',   name = 'Dinka Marquis',       type = 'Boat',    price = 220000 },
}

-- ===========================================================================
--  FACTION GARAGES (optional)
--  Nu exista un sistem de facțiuni in acest server. Scheletul e pregatit:
--  - mapezi id-ul unui garage la un slug de facțiune;
--  - garage-ul respectiv afiseaza DOAR vehiculele cu personal_vehicle.faction = slug
--    (vehiculele personale normale, faction = '', NU apar si NU pot fi scoase);
--  - accesul e permis doar daca Utils.isFactionMember(src, slug) e adevarat.
--  Cand adaugi un sistem real de facțiuni, implementeaza Utils.isFactionMember
--  in shared/utils.lua (server-side) sa interogheze acel sistem.
-- ===========================================================================
Config.FactionGarages = {
    -- [12] = 'police',
    -- [15] = 'ems',
}

-- Placeholder de test pana exista un sistem real: users.id -> lista de facțiuni.
-- Lasa gol in productie daca nu vrei acces la faction garages.
Config.FactionMembersByUserId = {
    -- [1] = { 'police' },
}

return true
