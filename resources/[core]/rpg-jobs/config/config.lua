-- ===========================================================================
--  rpg-jobs — configuratie (shared client + server)
--  Sistem MODULAR de joburi. Momentan e configurat un singur job (Electrician),
--  dar codul e job-id-driven: adaugi un job = un bloc nou in Config.Jobs +
--  (optional) alte locatii/minigame-uri. NIMIC important nu e hardcodat in logica.
-- ===========================================================================
Config = {}

Config.Debug = true

-- Unde ajung banii de la panouri: 'money' (cash) sau 'bank'.
Config.PayTo = 'money'

-- Tasta de interactiune cu NPC-ul (fara comanda). 246 = Y (INPUT_MP_TEXT_CHAT_TEAM).
Config.Interaction = {
    key    = 246,
    radius = 2.2,    -- m: cat de aproape trebuie sa fii de NPC ca sa apesi Y (verificat si server-side)
}

-- Tasta de START a unui panou (cand ai ajuns la checkpoint, PE JOS). 38 = E.
Config.StartWorkKey = 38

-- ---- SECURITATE / ANTI-EXPLOIT (toate verificate server-side) -----------
Config.Security = {
    actionCooldownMs     = 600,     -- interval minim intre doua actiuni de tura (anti-spam)
    shiftCooldownMs      = 4000,    -- interval minim dupa oprirea unei sesiuni de lucru
    minigameGraceMs      = 1500,    -- toleranta peste time-limit-ul minigame-ului
    minigameMinMs        = 400,     -- sub asta = "instant", respins
    retryCooldownMs      = 2000,    -- dupa un minigame esuat, cat astepti pana la un altul
    taskRadius           = 3.5,     -- m: raza in care poti porni un panou (server-side)
    maxTaskTravelM       = 1200.0,  -- m: distanta max plauzibila NPC->task (anti coordonate false)
    codeGuessCooldownMs  = 280,     -- rate-limit pe fiecare incercare la minigame-ul "Search the code"
    codeMaxAttempts      = 60,      -- peste atat de incercari la "Search the code" -> esuat
}

-- ===========================================================================
--  SKILL-uri  (identice pentru toate joburile; se pot suprascrie per job)
--  requiredShifts = numarul CUMULAT de PANOURI reparate ca sa AI acel skill.
--  pay = { base, min, max }  -> plata / CHECKPOINT = base + random(min, max).
--  Restul = dificultatea minigame-urilor la acel skill.
-- ===========================================================================
Config.Skills = {
    [1] = { requiredShifts = 0,   pay = { base = 20,  min = 10,  max = 50  },
            wires = { timeMs = 24000 },
            flow  = { n = 5,  timeMs = 22000 },
            code  = { timeMs = 32000 } },
    [2] = { requiredShifts = 60,  pay = { base = 40,  min = 30,  max = 60  },
            wires = { timeMs = 21000 },
            flow  = { n = 6,  timeMs = 19000 },
            code  = { timeMs = 28000 } },
    [3] = { requiredShifts = 140, pay = { base = 60,  min = 50,  max = 100 },
            wires = { timeMs = 18000 },
            flow  = { n = 7,  timeMs = 17000 },
            code  = { timeMs = 24000 } },
    [4] = { requiredShifts = 260, pay = { base = 80,  min = 70,  max = 120 },
            wires = { timeMs = 15000 },
            flow  = { n = 8,  timeMs = 15000 },
            code  = { timeMs = 21000 } },
    [5] = { requiredShifts = 420, pay = { base = 100, min = 100, max = 150 },
            wires = { timeMs = 13000 },
            flow  = { n = 9,  timeMs = 13000 },
            code  = { timeMs = 18000 } },
    [6] = { requiredShifts = 620, pay = { base = 200, min = 150, max = 200 },
            wires = { timeMs = 11000 },
            flow  = { n = 10, timeMs = 12000 },
            code  = { timeMs = 16000 } },
}

-- plata (base/min/max) pentru un skill, cu fallback pe Skill 1
function Config.SkillPay(skill)
    local s = Config.Skills[skill] or Config.Skills[1]
    return s.pay or { base = 0, min = 0, max = 0 }
end

function Config.SkillCfg(job, skill)
    skill = math.max(1, math.min(skill, job.maxSkill))
    return Config.Skills[skill] or Config.Skills[job.maxSkill] or Config.Skills[1]
end

-- ===========================================================================
--  JOBURI
--  id       = ID FIX (se salveaza in users.job). NU se schimba dupa lansare.
--  Adauga alte joburi punand un bloc nou aici + inregistrandu-le locatiile.
-- ===========================================================================
Config.Jobs = {
    [1] = {
        id       = 1,
        name     = 'electrician',
        label    = 'Electrician',
        minLevel = 1,
        maxSkill = 6,

        -- Plata se face / CHECKPOINT, creditata IMEDIAT dupa fiecare panou (fara
        -- limita de panouri pe sesiune). Suma = Config.Skills[skill].pay.base +
        -- random(.pay.min, .pay.max) — vezi tabelul Config.Skills de mai sus.

        -- minigame-urile folosite de job (in ordine ciclica, cu offset random pe sesiune).
        -- Valide: 'wires' (Connect the wires), 'flow' (Connect to electricity), 'code' (Search the code).
        minigames = { 'wires', 'flow', 'code' },

        npc = {
            model  = 's_m_y_construct_01',
            coords = vector4(714.94, 137.53, 80.02, 51.0),   -- langa depozitul de la Mirror Park power
            scenario = 'WORLD_HUMAN_CLIPBOARD',
        },

        blip = { sprite = 402, color = 5, scale = 0.85, label = 'Electrician Job' },

        -- ===================================================================
        --  CHECKPOINT-URI (punctele de lucru / panourile electrice)
        --  AICI adaugi/stergi puncte. Fiecare linie = un vector3(x, y, z).
        --  Serverul alege aleator un checkpoint dupa fiecare panou (fara sa-l
        --  repete imediat pe cel precedent). Minim 3 checkpoint-uri.
        --
        --  Ca sa iei coordonate din joc: du-te la locul dorit (PE JOS) si scrie
        --  in chat  /jobcoord  — iti afiseaza in consola (F8) linia gata de copiat.
        -- ===================================================================
        workLocations = {
            vector3(704.13, 113.44, 79.72),
            vector3(548.02, 82.30, 96.66),
            vector3(475.28, -22.34, 89.63),
            vector3(215.51, -170.31, 55.44),
            vector3(120.85, -260.14, 51.93),
            vector3(-51.44, -137.34, 57.30),
            vector3(-208.52, -12.90, 51.20),
            vector3(-537.19, -74.10, 39.62),
            vector3(-700.31, 61.30, 43.09),
            vector3(-1033.44, -230.10, 39.02),
            vector3(-1310.20, -288.10, 39.20),
            vector3(-46.10, -1757.30, 30.02),
        },
        workBlip = { sprite = 500, color = 5, scale = 0.7 },
    },
}

-- job-ul "curent" al acestei resurse (o resursa = un set de NPC-uri/locatii).
-- Daca vrei mai multe joburi cu NPC in acelasi resource, transforma NPC-urile
-- intr-o bucla peste Config.Jobs.
Config.Job = Config.Jobs[1]

return Config
