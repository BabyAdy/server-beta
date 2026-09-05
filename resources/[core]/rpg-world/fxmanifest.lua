fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rpg-world'
author 'Custom RPG'
version '0.2.0'
description 'Setari de lume (fara NPC/trafic ambiental) + NoClip pentru staff (F2, invizibil pt. ceilalti)'

-- NoClip verifica gradul de staff prin LocalPlayer.state.staff (setat de rpg-auth) + Staff.level().
-- Toggle-ul e re-validat si pe server (statebag replicat 'noclip' -> vizibilitate sincronizata pt. ceilalti).
-- rpg-hud e folosit optional pt. feedback in chat; rpg-characters pt. resolveCharacter la /setvw.
dependencies { 'rpg-auth', 'rpg-hud', 'rpg-characters' }

shared_scripts {
    '@rpg-auth/shared/staff.lua',   -- Staff.RANKS / Staff.level()
    'shared/config.lua',
}

client_scripts {
    'client/population.lua',
    'client/noclip.lua',
    'client/vehicles.lua',
}

server_script 'server/main.lua'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/app.js',
}
