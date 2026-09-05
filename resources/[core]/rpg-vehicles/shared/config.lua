-- ===========================================================================
--  rpg-vehicles — configuratie partajata
-- ===========================================================================
Config = {}

Config.ManageRank      = 'manager'      -- /vcreate, /vdelete
Config.BroadcastRank   = 'trialadmin'   -- cine vede mesajele "Staff: ..." in chat

Config.ModSyncInterval  = 10000   -- ms: cat de des ownerul trimite tuning-ul spre server (pt. salvare la ORICE despawn)
Config.WatchdogInterval = 5000    -- ms: serverul verifica daca un vehicul spawnat a disparut (/dv, crash)

Config.MaxSpawnPerPlayer = 0      -- 0 = fara limita; altfel cate vehicule personale pot fi spawnate simultan
Config.SpawnOffset       = 4.0    -- m in fata playerului la [Unstuck]

Config.PlateChars = 'ABCDEFGHIJKLMNPQRSTUVWXYZ0123456789'
Config.PlateLen   = 8
