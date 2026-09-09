fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rpg-nametags'
author 'Custom RPG'
version '1.0.0'
description 'Nametag 3D custom (NUI) deasupra capului: [sql id] Username + icon de grad staff. Fix pe caracter, NU sare la intrarea in masina (nu foloseste MP gamer tags).'

-- doar pt. ordinea de pornire (furnizorii de statebag-uri: staff / accountName / charId / subs)
dependencies {
    'rpg-auth',
    'rpg-characters',
    'rpg-subs',
}

shared_scripts {
    '@rpg-auth/shared/staff.lua',   -- Staff.iconSvg() / Staff.color()
    '@rpg-subs/shared/subs.lua',    -- Subs.ORDER / Subs.TYPES (iconuri + culori)
    'shared/config.lua',
}

client_script 'client/main.lua'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/app.js',
}
