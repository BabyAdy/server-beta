-- ===========================================================================
--  rpg-drivingschool — configurație partajată
-- ===========================================================================
Config = {}

-- ---- LOCAȚIE (coordonate reale, capturate cu /savecoord) ----------------
Config.Location = {
    coords         = vector3(-899.97, -2493.01, 14.55),
    heading        = 147.4,
    interactRadius = 2.2,     -- distanța la care apare promptul "[E] ..."
    markerRadius   = 15.0,    -- distanța la care se desenează marker-ul 3D pe sol

    blip = { sprite = 280, color = 3, scale = 0.85, label = 'Driving School Center' },   -- steag de cursă; schimbă sprite-ul cum vrei
    marker = {
        type = 1,
        size = vector3(2.2, 2.2, 0.9),
        color = { r = 90, g = 140, b = 255, a = 140 },
    },
}

-- ---- COST / PROMOVARE --------------------------------------------------
Config.TestCost  = 100   -- $ (cash / users.money), scăzut la ÎNCEPUTUL testului teoretic
Config.PassScore = 80    -- % minim ca să treacă testul teoretic (>= 80 -> promovat)

-- ore acordate la promovarea testului PRACTIC ("Driving Licence pentru 100%" -> credit mare, efectiv permanent)
Config.RewardHours = 999999

-- ---- TEST PRACTIC -------------------------------------------------------
Config.PracticalVirtualWorld = 7301             -- routing bucket dedicat (diferit de 0)
Config.PracticalVehicle      = `blista`         -- mașina de test
Config.CheckpointRadius      = 8.0              -- rază de validare per checkpoint

-- unde apar jucătorul + mașina de test (in virtual world-ul dedicat), diferit de locația școlii
Config.PracticalSpawn = { coords = vector3(-927.36, -2429.93, 13.85), heading = 195.6 }

-- traseul (16 puncte, coordonate reale capturate cu /savecoord): cp1..cp15 + cp-final.
-- la cp-final testul se ÎNCHEIE -> jucătorul e teleportat înapoi la Config.Location (virtual world 0).
Config.PracticalRoute = {
    vector3(-928.25, -2462.76, 13.83),   -- cp1
    vector3(-889.64, -2441.09, 13.81),   -- cp2
    vector3(-859.46, -2441.27, 13.74),   -- cp3
    vector3(-825.43, -2469.36, 13.69),   -- cp4
    vector3(-819.30, -2526.44, 13.74),   -- cp5
    vector3(-859.27, -2593.86, 13.68),   -- cp6
    vector3(-899.25, -2661.65, 13.64),   -- cp7
    vector3(-934.43, -2715.85, 13.71),   -- cp8
    vector3(-990.90, -2724.18, 13.71),   -- cp9
    vector3(-998.80, -2699.89, 13.81),   -- cp10
    vector3(-964.54, -2640.40, 13.83),   -- cp11
    vector3(-936.46, -2590.07, 13.81),   -- cp12
    vector3(-879.39, -2568.79, 13.83),   -- cp13
    vector3(-857.39, -2505.06, 13.83),   -- cp14
    vector3(-887.02, -2470.96, 13.81),   -- cp15
    vector3(-944.73, -2438.58, 13.81),   -- cp-final (16/16) -> se termina testul aici
}

-- ---- TEST TEORETIC — 5 întrebări (index 1 = primul răspuns) ------------
-- `correct` NU se trimite niciodată către client (vezi server/main.lua).
Config.Questions = {
    {
        text = 'Care este limita de viteză cu care poți circula pe autostradă?',
        answers = { '100 km/h', '120 km/h', '70 km/h', 'Nu există limită' },
        correct = 4,
    },
    {
        text = 'Ce faci dacă ești somat de un polițist pentru a trage pe dreapta?',
        answers = { 'Fug', 'Îl împușc și îi zic "Sit câine"', 'Îi fac reclamație pe UCP', 'Trag pe dreapta și mă conformez' },
        correct = 4,
    },
    {
        text = 'Care este limita maximă de viteză admisă în oraș?',
        answers = { '100 km/h', '50 km/h', '60 km/h', '70 km/h' },
        correct = 4,
    },
    {
        text = 'Ce sancțiune primești dacă ești surprins circulând pe contrasens?',
        answers = { 'Warn [Condus NON RP]', 'Jail', 'Kick', 'Suspend Licence' },
        correct = 4,
    },
    {
        text = 'Ce pățești dacă parchezi mașina pe bordură și pleci de lângă ea?',
        answers = {
            'Mi-o fură Caen că-i rupt de foame',
            'Vine Nectagon și mi-o zgârie cu cheia',
            'Un admin îi va da /dv',
            'O să fie tractată de un membru TTC și va trebui să plătesc o taxă la ei pentru a o putea scoate',
        },
        correct = 4,
    },
}
