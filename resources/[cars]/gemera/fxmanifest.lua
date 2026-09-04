fx_version 'cerulean'
game 'gta5'

name 'gemera'
author 'Custom RPG'
description 'Masina addon: gemera'
version '0.1.0'

-- ===========================================================================
--  gemera — mașină addon (vezi resources/[cars]/nkcypher/fxmanifest.lua pt.
--  explicația completă / pașii de urmat la adăugarea unei mașini noi).
--  NOTĂ: acest folder NU are carcols.meta (mașina nu vine cu kit-uri de tuning
--  proprii) dar ARE dlctext.meta (nume/text custom afișat în joc) -- de-asta
--  data_file-urile de mai jos diferă puțin față de restul mașinilor.
-- ===========================================================================

data_file 'HANDLING_FILE'          'handling.meta'
data_file 'VEHICLE_METADATA_FILE'  'vehicles.meta'
data_file 'VEHICLE_VARIATION_FILE' 'carvariations.meta'
data_file 'ADDITIONAL_TEXT_FILE'   'dlctext.meta'

files {
    'handling.meta',
    'vehicles.meta',
    'carvariations.meta',
    'dlctext.meta',
}

-- .yft / _hi.yft / .ytd ale mașinii merg în stream/ (nu trebuie listate aici,
-- se streamează automat).
