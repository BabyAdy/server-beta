fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rpg-level'
author 'Custom RPG'
version '0.1.0'
description 'Level & Respect Points + economie (users.level/respectpoints/money/bank) + /stats NUI'

dependencies {
    'rpg-auth',
    'rpg-characters',
    'rpg-hud',           -- timer-ul de Salary din HUD + chat feedback
}

shared_script 'shared/config.lua'

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
