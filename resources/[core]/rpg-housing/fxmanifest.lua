fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rpg-housing'
author 'Custom RPG'
version '0.1.0'
description 'Case (interioare bob74_ipl) — /createhouse (staff) + eticheta moderna (NUI) la punctul de intrare'

-- interioarele fizice vin din bob74_ipl (nu e o dependenta hard -- doar trebuie sa fie pornita
-- inaintea acestei resurse ca sa aiba efect mai tarziu, cand adaugam intrarea in casa)
dependencies {
    'rpg-auth',
    'rpg-characters',
    'rpg-hud',
}

shared_scripts {
    '@rpg-auth/shared/staff.lua',   -- Staff.level() / Staff.BROADCAST_COLOR
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
    'html/js/app.js',
}
