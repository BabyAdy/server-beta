fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rpg-world'
author 'Custom RPG'
version '0.1.0'
description 'Setari de lume (fara NPC/trafic ambiental) + NoClip pentru staff (F2)'

-- NoClip verifica gradul de staff prin LocalPlayer.state.staff (setat de rpg-auth) + Staff.level().
dependencies { 'rpg-auth' }

shared_scripts {
    '@rpg-auth/shared/staff.lua',   -- Staff.RANKS / Staff.level()
    'shared/config.lua',
}

client_scripts {
    'client/population.lua',
    'client/noclip.lua',
}
