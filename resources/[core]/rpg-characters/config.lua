Config = {}

-- Locul (privat, in routing bucket separat) unde se editeaza personajul
Config.Creator = {
    coords     = vec4(-1043.4, -2745.0, 21.4, 331.0),
    bucketBase = 900,   -- routing bucket per player = bucketBase + serverId
}

-- Unde e spawnat personajul dupa creare / la revenirea in server
Config.SpawnAfterCreate = vec4(-1035.7, -2732.0, 20.2, 300.0)

-- Camere (offset fata de punctul din Config.Creator.coords)
Config.Cameras = {
    head = { z = 0.62,  dist = 1.05, fov = 22.0, aimZ = 0.62  },
    body = { z = 0.15,  dist = 2.25, fov = 40.0, aimZ = 0.15  },
    legs = { z = -0.65, dist = 1.75, fov = 32.0, aimZ = -0.55 },
}

-- Rotirea personajului per apasare (grade)
Config.RotateStep = 12.0

-- „Fara haine" - componente fortate la spawn (comp = { drawable, texture })
-- Componente: 1 masca, 3 brate/maini, 4 picioare, 5 rucsac, 6 incaltaminte,
--             7 accesoriu gat, 8 tricou interior, 9 vesta, 10 abtibild, 11 tors
Config.NudeComponents = {
    ['mp_m_freemode_01'] = {
        [1] = { 0, 0 }, [3] = { 15, 0 }, [4] = { 21, 0 }, [5] = { 0, 0 },
        [6] = { 34, 0 }, [7] = { 0, 0 }, [8] = { 15, 0 }, [9] = { 0, 0 },
        [10] = { 0, 0 }, [11] = { 15, 0 },
    },
    ['mp_f_freemode_01'] = {
        [1] = { 0, 0 }, [3] = { 15, 0 }, [4] = { 15, 0 }, [5] = { 0, 0 },
        [6] = { 35, 0 }, [7] = { 0, 0 }, [8] = { 14, 0 }, [9] = { 0, 0 },
        [10] = { 0, 0 }, [11] = { 15, 0 },
    },
}
