-- ===========================================================================
--  rpg-drivingschool — configurație partajată
-- ===========================================================================
Config = {}

-- ---- LOCAȚIE (lângă spawn — vezi rpg-characters/config.lua: Config.SpawnAfterCreate
--      = vec4(-1035.7, -2732.0, 20.2, 300.0)). PLACEHOLDER, ajustăm după ce vezi harta. ----
Config.Location = {
    coords         = vector3(-1000.0, -2730.0, 20.0),
    heading        = 230.0,
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

-- 15 checkpoint-uri: traseu PLACEHOLDER (cerc în jurul locației), ultimul = în fața școlii.
-- Îl înlocuim cu coordonate reale de pe hartă când confirmi locația finală.
Config.PracticalRoute = (function()
    local c = Config.Location.coords
    local radius, n, pts = 120.0, 14, {}
    for i = 1, n do
        local ang = (i - 1) * (2 * math.pi / n)
        pts[i] = vector3(c.x + math.cos(ang) * radius, c.y + math.sin(ang) * radius, c.z)
    end
    pts[n + 1] = c   -- al 15-lea checkpoint = în fața Driving School Center
    return pts
end)()

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
