fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rpg-jobs'
author 'Custom RPG'
version '1.0.0'
description 'Sistem modular de joburi (job activ + skill-uri + minigame-uri NUI). Primul job: Electrician. Server-authoritative, anti-exploit.'

-- Se integreaza cu framework-ul custom prin server/framework.lua (SINGURUL loc
-- framework-dependent). Aici e legat la: rpg-auth / rpg-level / rpg-hud / rpg-characters.
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
    'client/npc.lua',
    'client/interaction.lua',
    'client/work.lua',
    'client/minigames.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/framework.lua',
    'server/database.lua',
    'server/jobs.lua',
    'server/security.lua',
    'server/main.lua',
}

ui_page 'nui/index.html'

files {
    'nui/index.html',
    'nui/style.css',
    'nui/script.js',
}
