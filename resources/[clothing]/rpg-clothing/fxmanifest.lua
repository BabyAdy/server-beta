fx_version 'cerulean'
game 'gta5'

name 'rpg-clothing'
author 'Custom RPG'
description 'Inlocuieste hainele default din joc cu variante addon (streamed replacement)'
version '0.1.0'

-- ===========================================================================
--  CUM FUNCȚIONEAZĂ (ÎNLOCUIRE, nu adăugare):
--
--  FiveM permite ca un fișier .ydd (model) / .ytd (textură) dintr-o resursă să
--  "acopere" (înlocuiască) fișierul original din joc DACĂ are EXACT ACELAȘI
--  NUME ca originalul. Nu se creează un item nou de îmbrăcăminte -- se schimbă
--  cum arată unul care există deja (ex. un anumit drawable de pe
--  mp_m_freemode_01 / mp_f_freemode_01), pentru TOȚI jucătorii, automat.
--
--  PAȘI:
--  1. Ai nevoie de fișiere .ydd/.ytd cu numele EXACT al piesei vanilla pe care
--     vrei s-o înlocuiești. Aceste nume se găsesc fie:
--       a) deja corect denumite, dacă folosești un pachet "clothing replace"
--          descărcat/cumpărat (cel mai simplu și mai sigur mod), sau
--       b) extrase manual din fișierele jocului cu un tool ca OpenIV / CodeWalker,
--          dacă vrei să înlocuiești o piesă anume tu însuți.
--     NU ghici numele -- un nume greșit pur și simplu nu înlocuiește nimic
--     (fișierul e ignorat), deci nu poate "strica" jocul, dar nici nu are efect.
--
--  2. Pui fișierele (.ydd + .ytd, aceeași denumire, doar extensia diferă) în
--     stream/. Se streamează AUTOMAT -- nu trebuie listate în acest fxmanifest.
--
--  3. Restart la resursă (sau /refresh + ensure rpg-clothing din consola
--     serverului) ca să preia fișierele noi.
--
--  Acest resurs e DOAR pentru înlocuire. Pentru haine ADĂUGATE (addon, fără să
--  atingi hainele vanilla), e nevoie de un DLC pack separat (fxmanifest cu
--  `this_is_a_dlc_pack` + un dlclist propriu) -- spune dacă vrei și asta.
-- ===========================================================================
