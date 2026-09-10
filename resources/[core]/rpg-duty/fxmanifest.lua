fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rpg-duty'
author 'Custom RPG'
version '1.0.0'
description 'Duty on/off pentru factiuni (in HQ) + editor de outfit salvat per personaj/factiune. Faza 1: /duty, anuntul de proximitate, editorul de haine si aplicarea outfit-ului. Faza 2 (separat): loadout de arme pe rank + restrictiile de pe duty.'

dependencies {
    'oxmysql',
    'rpg-auth',
    'rpg-characters',
    'rpg-factions',
    'rpg-hud',
    'rpg-inventory',
}

shared_scripts {
    '@rpg-auth/shared/staff.lua',
    'config/config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

ui_page 'nui/index.html'

files {
    'nui/index.html',
    'nui/style.css',
    'nui/script.js',
}
