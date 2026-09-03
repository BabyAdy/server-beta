fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rpg-characters'
author 'Custom RPG'
version '0.1.0'
description 'Character Creator (un singur personaj / cont, fara identity)'

shared_scripts {
    'config.lua',
    'shared/appearance.lua',
}

client_script 'client/main.lua'

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
