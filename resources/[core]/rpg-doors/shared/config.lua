-- ===========================================================================
--  rpg-doors — configuratie
-- ===========================================================================
Config = {}

-- Cine poate adauga / incuia / sterge usi (grad staff din rpg-auth/shared/staff.lua).
Config.ManageRank = 'trialadmin'

-- Comanda care deschide meniul. Mereu disponibila; optional o legi la o tasta.
Config.OpenCommand = 'doors'
Config.OpenKey     = ''          -- '' = doar comanda. Ex: 'F10'

-- Cat de departe (m) cauti o usa cu privirea la "Scaneaza usa din fata".
Config.RayDistance = 8.0

-- La cate secunde re-aplica starea usilor (protectie la streaming / alte scripturi).
Config.ReassertSec = 15

Config.Debug = true
