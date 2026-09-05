fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rpg-vehicles'
author 'Custom RPG'
version '0.1.0'
description 'Vehicule personale: /park, /v (meniu NUI), /vcreate /vdelete (staff), salvare tuning la despawn'

dependencies {
    'rpg-auth',
    'rpg-characters',
    'rpg-hud',
}

shared_scripts {
    '@rpg-auth/shared/staff.lua',   -- Staff.level() / Staff.BROADCAST_COLOR
    'shared/config.lua',
}

client_scripts {
    'client/vehicle_properties.lua',
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/app.js',
}
