fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rpg-doors'
author 'Custom RPG'
version '1.0.0'
description 'Incuietori de usi — server-authoritative, se aplica in TOATE lumile virtuale (routing buckets). Fara text / lacat pe usi; starea locked se vede DOAR in meniul /doors.'

dependencies {
    'oxmysql',
    'rpg-auth',
}

shared_scripts {
    '@rpg-auth/shared/staff.lua',
    'shared/config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
}
