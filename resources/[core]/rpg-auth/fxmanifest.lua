fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rpg-auth'
author 'Custom RPG'
version '0.1.0'
description 'Sistem Login / Register pe NUI — tematica purple/black, fundal transparent'

shared_scripts {
    'config.lua',
    'shared/staff.lua',
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
    'html/assets/logo.svg',
}
