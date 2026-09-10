-- ===========================================================================
--  rpg-doors — configuratie
-- ===========================================================================
Config = {}

-- Cine poate adauga / incuia / sterge usi (grad staff din rpg-auth/shared/staff.lua).
Config.ManageRank = 'trialadmin'

-- Comanda care deschide meniul. Mereu disponibila; optional o legi la o tasta.
Config.OpenCommand = 'doors'
Config.OpenKey     = ''          -- '' = doar comanda. Ex: 'F10'

-- SELECTARE MANUALA cu cursorul ("Selecteaza usa"):
Config.PickDistance    = 14.0   -- m: distanta max de la camera pana la usa pe care poti da click
Config.PickMatchRadius = 1.5    -- m: cat de aproape trebuie sa fie o usa INREGISTRATA de obiectul
                                --    pe care ai dat click, ca sa fie considerata aceeasi usa

-- La cate secunde re-aplica starea usilor (protectie la streaming / alte scripturi).
Config.ReassertSec = 15

Config.Debug = true
