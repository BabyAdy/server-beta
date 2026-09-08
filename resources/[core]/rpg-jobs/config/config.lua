-- ===========================================================================
--  rpg-jobs — configuratie (shared client + server)
--  Sistem MODULAR de joburi. Momentan e configurat un singur job (Electrician),
--  dar codul e job-id-driven: adaugi un job = un bloc nou in Config.Jobs +
--  (optional) alte locatii/minigame-uri. NIMIC important nu e hardcodat in logica.
-- ===========================================================================
Config = {}

Config.Debug = true

-- Unde ajung banii de la ture: 'money' (cash) sau 'bank'.
Config.PayTo = 'money'

-- Tasta de interactiune cu NPC-ul (fara comanda). 246 = Y (INPUT_MP_TEXT_CHAT_TEAM).
Config.Interaction = {
    key    = 246,
    radius = 2.2,    -- m: cat de aproape trebuie sa fii de NPC ca sa apesi Y (verificat si server-side)
}

-- ---- SECURITATE / ANTI-EXPLOIT (toate verificate server-side) -----------
Config.Security = {
    actionCooldownMs  = 600,     -- interval minim intre doua actiuni de shift (anti-spam)
    shiftCooldownMs   = 5000,    -- interval minim dupa terminarea/anularea unei ture
    minigameGraceMs   = 1500,    -- toleranta peste time-limit-ul minigame-ului
    minigameMinMs     = 400,     -- sub asta = "instant", respins
    retryCooldownMs   = 2000,    -- dupa un minigame esuat, cat astepti pana la un altul
    taskRadius        = 3.5,     -- m: raza in care poti interactiona cu un panou (server-side)
    maxTaskTravelM    = 1200.0,  -- m: distanta max plauzibila NPC->task (anti coordonate false)
    voltageEpsilon    = 0.06,    -- toleranta la potrivirea pozitiei indicatorului cu timpul scurs
    circuitGrace      = 0,       -- cate segmente gresite tolereaza validarea (0 = circuitul trebuie COMPLET corect)
}

-- ===========================================================================
--  SKILL-uri  (identice pentru toate joburile; se pot suprascrie per job)
--  requiredShifts = numarul CUMULAT de ture finalizate ca sa AI acel skill.
--  multiplier     = inmultitorul platii (Skill 1 = x1.00, +20% / skill).
--  Restul = dificultatea minigame-urilor la acel skill.
-- ===========================================================================
Config.Skills = {
    [1] = { requiredShifts = 0,  multiplier = 1.00,
            circuit = { segments = 4, timeMs = 22000 },
            voltage = { zone = 0.24, speed = 0.55, timeMs = 9500 } },
    [2] = { requiredShifts = 15, multiplier = 1.20,
            circuit = { segments = 5, timeMs = 19000 },
            voltage = { zone = 0.19, speed = 0.72, timeMs = 8500 } },
    [3] = { requiredShifts = 30, multiplier = 1.40,
            circuit = { segments = 6, timeMs = 16000 },
            voltage = { zone = 0.15, speed = 0.90, timeMs = 7500 } },
    [4] = { requiredShifts = 45, multiplier = 1.60,
            circuit = { segments = 7, timeMs = 14000 },
            voltage = { zone = 0.12, speed = 1.08, timeMs = 6800 } },
    [5] = { requiredShifts = 60, multiplier = 1.80,
            circuit = { segments = 8, timeMs = 12000 },
            voltage = { zone = 0.10, speed = 1.25, timeMs = 6000 } },
}

-- Formula fallback daca un skill nu are `multiplier` in tabel: 1 + (skill-1)*0.20
function Config.SkillMultiplier(skill)
    local s = Config.Skills[skill]
    if s and s.multiplier then return s.multiplier end
    return 1.0 + (math.max(1, skill) - 1) * 0.20
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
        maxSkill = 5,

        -- venitul de BAZA ($/tura). Plata finala = random(min,max) * SkillMultiplier(skill).
        pay = { min = 1000, max = 2000 },

        -- o tura = atatea panouri reparate
        shift = { requiredTasks = 5 },

        -- minigame-urile folosite de job (in ordine ciclica / random). Valide: 'circuit', 'voltage'.
        minigames = { 'circuit', 'voltage' },

        npc = {
            model  = 's_m_y_construct_01',
            coords = vector4(714.94, 137.53, 80.02, 51.0),   -- langa depozitul de la Mirror Park power
            scenario = 'WORLD_HUMAN_CLIPBOARD',
        },

        blip = { sprite = 402, color = 5, scale = 0.85, label = 'Electrician Job' },

        -- puncte de lucru (panouri electrice) — GTA V map, zone urbane
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
