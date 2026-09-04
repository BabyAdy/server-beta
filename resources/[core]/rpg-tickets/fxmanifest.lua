fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rpg-tickets'
author 'Custom RPG'
version '0.1.0'
description 'Sistem de tichete/report — meniu player + meniu staff (NUI custom) + DB + Rewards'

-- Se integreaza cu framework-ul custom:
--   rpg-auth       -> cont (users.id), license, grade staff (hasStaffLevel)
--   rpg-characters -> username / SQL id personaj
--   rpg-hud        -> notificari in chat
--   rpg-level      -> virare bani in users.bank la revendicarea Rewards
dependencies {
    'oxmysql',
    'rpg-auth',
    'rpg-characters',
    'rpg-hud',
    'rpg-level',
}

shared_scripts {
    '@rpg-auth/shared/staff.lua',   -- tabelul Staff.RANKS + helperi (Staff.level/kind/label/color)
    'shared/config.lua',
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
    'html/js/player.js',
    'html/js/staff.js',
    'html/assets/logo.svg',
}
