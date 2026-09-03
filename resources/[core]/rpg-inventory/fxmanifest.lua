fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rpg-inventory'
author 'Custom RPG'
version '0.1.0'
description 'Inventory RPG modular custom (fara ESX / QBCore / Qbox) - NUI custom, server-authoritative'

shared_scripts {
    'shared/config.lua',
    'shared/items.lua',
}

client_scripts {
    'client/main.lua',
    'client/nui.lua',
    'client/interactions.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/validation.lua',
    'server/containers.lua',
    'server/inventory.lua',
    'server/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/dnd.js',
    'html/js/tooltip.js',
    'html/js/contextmenu.js',
    'html/js/grid.js',
    'html/js/equipment.js',
    'html/js/nearby.js',
    'html/js/fastslots.js',
    'html/js/app.js',
    'html/assets/icons/placeholder.svg',
}
