fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rpg-garages'
author 'Custom RPG'
version '1.0.0'
description 'Personal Vehicles + Garages + Dealership — server-authoritative, integrat cu rpg-auth/rpg-level/rpg-hud'

-- Ordinea de pornire e asigurata prin server.cfg (dupa rpg-auth/rpg-characters/rpg-level/rpg-hud).
dependencies {
    'oxmysql',
    'rpg-auth',        -- users.id / username, permisiuni staff (hasStaffLevel)
    'rpg-characters',  -- ciclu de viata personaj (core:characterLoaded)
    'rpg-level',       -- economie: getBank/getMoney/addBank/addMoney
    'rpg-hud',         -- notificari in chat (addChatMessage) + broadcast staff
}

shared_scripts {
    '@rpg-auth/shared/staff.lua',   -- Staff.RANKS / Staff.level / Staff.BROADCAST_COLOR
    'shared/config.lua',
    'shared/utils.lua',
}

client_scripts {
    'client/tuning.lua',
    'client/main.lua',
    'client/ui.lua',
    'client/vehicle.lua',
    'client/garage.lua',
    'client/dealership.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/tuning.lua',
    'server/garage.lua',
    'server/vehicle.lua',
    'server/dealership.lua',
    'server/commands.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/app.js',
    -- imaginile vehiculelor: html/images/vehicles/<model_name>.png
    -- (path-ul se genereaza din model_name; lipsa -> placeholder "NO IMAGE" in NUI)
    'html/images/vehicles/*.png',
    'html/images/vehicles/*.jpg',
    'html/images/vehicles/*.webp',
}
