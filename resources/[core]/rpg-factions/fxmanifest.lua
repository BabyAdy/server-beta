fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rpg-factions'
author 'Custom RPG'
version '1.0.0'
description 'Sistem complet de facțiuni: ranks, permissions, applications, warnings, supervisors/testers, leader/manager, HQ (routing bucket), audit logs. Server-authoritative.'

dependencies {
    'oxmysql',
    'rpg-auth',
    'rpg-level',
    'rpg-hud',
    'rpg-characters',
}

shared_scripts {
    'config/config.lua',
}

client_scripts {
    'client/main.lua',
    'client/nui.lua',
    'client/hq.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/framework.lua',
    'server/database.lua',
    'server/logs.lua',
    'server/permissions.lua',
    'server/factions.lua',
    'server/security.lua',
    'server/members.lua',
    'server/applications.lua',
    'server/main.lua',
}

ui_page 'nui/index.html'

files {
    'nui/index.html',
    'nui/css/style.css',
    'nui/js/app.js',
}
