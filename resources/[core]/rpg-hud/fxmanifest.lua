fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rpg-hud'
author 'Custom RPG'
version '0.1.0'
description 'Chat + HUD + Speedometer custom (NUI), modular. Inlocuieste resursa chat default.'

shared_scripts {
    'shared/config.lua',
    '@rpg-auth/shared/staff.lua',
}

dependencies {
    'rpg-auth',
    'rpg-characters',
}

client_scripts {
    'client/main.lua',
    'client/chat.lua',
    'client/hud.lua',
    'client/speedometer.lua',
}

server_script 'server/main.lua'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/style.css',
    'html/assets/logo.svg',
    'html/js/bus.js',
    'html/js/chat.js',
    'html/js/hud.js',
    'html/js/speedometer.js',
}
