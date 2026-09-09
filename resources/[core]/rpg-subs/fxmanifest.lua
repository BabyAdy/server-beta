fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rpg-subs'
author 'Custom RPG'
version '1.0.0'
description 'Sistem de subscriptii (Gold / Platinum / Legend): timp per tip in users, Premium Points, /shop, chat VIP (mov), iconuri pe nametag. Beneficiile efective se adauga ulterior.'

dependencies {
    'oxmysql',
    'rpg-auth',
    'rpg-characters',
    'rpg-hud',
}

shared_scripts {
    '@rpg-auth/shared/staff.lua',   -- Staff.iconSvg / Staff.color / Staff.level
    'shared/subs.lua',
    'shared/config.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}
