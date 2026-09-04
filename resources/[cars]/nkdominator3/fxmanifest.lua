fx_version 'cerulean'
game 'gta5'

name 'nkdominator3'
author 'Custom RPG'
description 'Masina addon: nkdominator3'
version '0.1.0'

-- ===========================================================================
--  nkdominator3 — mașină addon, resursă de sine stătătoare (vezi fxmanifest.lua
--  din resources/[cars]/nkcypher/ pentru explicația completă / pașii de urmat
--  la adăugarea unei mașini noi).
-- ===========================================================================

data_file 'HANDLING_FILE'          'handling.meta'
data_file 'VEHICLE_METADATA_FILE'  'vehicles.meta'
data_file 'CARCOLS_FILE'           'carcols.meta'
data_file 'VEHICLE_VARIATION_FILE' 'carvariations.meta'

files {
    'handling.meta',
    'vehicles.meta',
    'carcols.meta',
    'carvariations.meta',
}

-- .yft / _hi.yft / .ytd ale mașinii merg în stream/ (nu trebuie listate aici,
-- se streamează automat).
