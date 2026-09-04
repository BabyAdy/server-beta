fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rpg-drivingschool'
author 'Custom RPG'
version '0.1.0'
description 'Driving School Center — test teoretic (NUI, 5 intrebari) + test practic (15 checkpoint-uri, virtual world dedicat)'

-- rpg-level: verifica/scade cei $100 (users.money)
-- rpg-licences: acorda driving_licence_hours + bypass in timpul examenului practic
dependencies {
    'rpg-auth',
    'rpg-characters',
    'rpg-hud',
    'rpg-level',
    'rpg-licences',
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
