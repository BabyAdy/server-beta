fx_version 'cerulean'
game 'gta5'

name 'nksvolito'
author 'Custom RPG'
description 'Masina addon: nksvolito'
version '0.1.0'

-- ===========================================================================
--  nkcypher — mașină addon, resursă de sine stătătoare (TEMPLATE pt. restul).
--
--  Pt. o mașină nouă:
--  1. Copiază tot folderul (resources/[cars]/nkcypher/), redenumește-l după
--     noua mașină (ex. resources/[cars]/numemasina/).
--  2. Înlocuiește vehicles.meta / carcols.meta / carvariations.meta /
--     handling.meta cu cele din pachetul noii mașini (blocurile <Item> vin
--     gata făcute cu mașina -- copiază-le ca atare, nu le scrie de mână).
--  3. Pui fișierele .yft/.ytd ale mașinii în stream/ (se streamează automat,
--     nu trebuie listate în acest fișier).
--  4. Adaugi în server.cfg: ensure numemasina
--  5. În joc: /spawncar [modelName] (comanda din rpg-world) -- modelName =
--     exact <modelName> din vehicles.meta.
--
--  De ce fiecare mașină e propria ei resursă (nu un folder de date comun):
--  un __resource.lua/fxmanifest.lua dintr-un subfolder de date al altei
--  resurse NU se încarcă niciodată -- FiveM citește manifeste doar din
--  folderele listate direct sub resources/ (sau direct sub un folder
--  [categorie], ca [cars] aici).
-- ===========================================================================

data_file 'HANDLING_FILE'          'handling.meta'
data_file 'VEHICLE_METADATA_FILE'  'vehicles.meta'
data_file 'VEHICLE_VARIATION_FILE' 'carvariations.meta'

files {
    'handling.meta',
    'vehicles.meta',
    'carvariations.meta',
}

-- .yft / _hi.yft / .ytd ale mașinii merg în stream/ (nu trebuie listate aici,
-- se streamează automat).
